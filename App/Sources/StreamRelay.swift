import Foundation
import Network
import KastideoCore

/// Relais local des flux du direct, sur le modèle de Piboard : Kastideo ouvre lui-même UNE connexion chez le
/// fournisseur (en-têtes de lecteur VLC, redirections suivies) et la transmet au moteur VLC par 127.0.0.1.
///
/// Pourquoi : le moteur VLC multiplie les requêtes à l'ouverture (nouvel essai immédiat, connexions qui se
/// chevauchent au changement de chaîne). Avec un abonnement limité à une connexion, le fournisseur les refuse
/// (HTTP 401/403/404/520). Avec le relais, l'ancienne connexion est fermée net avant d'ouvrir la suivante, il n'y
/// en a jamais deux en même temps, et le journal indique la vraie réponse du fournisseur.
final class StreamRelay: NSObject, @unchecked Sendable {
    static let shared = StreamRelay()
    static let enabledKey = "relay.enabled"

    static var isEnabled: Bool { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }

    private let queue = DispatchQueue(label: "fr.jmezes.kastideo.relay")
    private var listener: NWListener?
    private var port: UInt16?
    private var routes: [String: URL] = [:]
    private var session: URLSession!
    /// Session en cours (une seule à la fois : c'est tout l'intérêt du relais).
    private var active: RelaySession?
    /// Dernière réponse du fournisseur pour la chaîne demandée (nil : pas encore de réponse ou pas de relais).
    private var lastStatus: Int?

    func lastUpstreamStatus() -> Int? { queue.sync { lastStatus } }

    private override init() {
        super.init()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpAdditionalHeaders = ["User-Agent": HTTP.userAgent, "Accept": "*/*"]
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 7 * 24 * 3600
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.httpMaximumConnectionsPerHost = 1
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    /// Démarre l'écoute sur 127.0.0.1 (port libre choisi par le système). Sans erreur bloquante :
    /// si le relais ne démarre pas, la lecture se fait en direct comme avant.
    func start() {
        queue.async { self.startListener() }
    }

    private func startListener() {
        guard listener == nil else { return }
        do {
            let parameters = NWParameters.tcp
            parameters.requiredLocalEndpoint = NWEndpoint.hostPort(host: "127.0.0.1", port: .any)
            parameters.allowLocalEndpointReuse = true
            let listener = try NWListener(using: parameters)
            listener.stateUpdateHandler = { [weak self] state in
                guard let self else { return }
                switch state {
                case .ready:
                    self.port = listener.port?.rawValue
                    PlaybackLog.shared.note("Relais de flux prêt (127.0.0.1:\(self.port ?? 0))")
                case .failed(let error):
                    PlaybackLog.shared.note("Relais de flux indisponible : \(error.localizedDescription) — lecture directe")
                    self.port = nil
                    self.listener = nil
                default:
                    break
                }
            }
            listener.newConnectionHandler = { [weak self] connection in
                self?.accept(connection)
            }
            listener.start(queue: queue)
            self.listener = listener
        } catch {
            PlaybackLog.shared.note("Relais de flux indisponible : \(error.localizedDescription) — lecture directe")
        }
    }

    /// Adresse à donner au moteur VLC : le relais pour un flux réseau du direct, sinon l'adresse d'origine.
    func playbackURL(for url: URL, live: Bool) -> URL {
        queue.sync { lastStatus = nil }
        guard live, Self.isEnabled, let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else { return url }
        // Les listes HLS (.m3u8) contiennent des adresses de segments : le relais ne sert que les flux continus (.ts…).
        guard url.pathExtension.lowercased() != "m3u8" else { return url }
        return queue.sync {
            guard let port else { return url }
            let token = UUID().uuidString.lowercased()
            routes = [token: url]
            lastStatus = nil   // seule la dernière chaîne demandée est servie
            let ext = url.pathExtension.isEmpty ? "ts" : url.pathExtension
            return URL(string: "http://127.0.0.1:\(port)/s/\(token).\(ext)") ?? url
        }
    }

    /// Ferme immédiatement la connexion chez le fournisseur (changement de chaîne, arrêt, fermeture de Kastideo).
    func closeAll() {
        queue.sync {
            routes.removeAll()
            closeActive(reason: nil)
        }
    }

    // MARK: - Connexions du moteur VLC

    private func accept(_ connection: NWConnection) {
        connection.start(queue: queue)
        readRequest(connection, buffer: Data())
    }

    private func readRequest(_ connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 16_384) { [weak self] data, _, complete, error in
            guard let self else { return }
            var buffer = buffer
            if let data { buffer.append(data) }
            if let end = buffer.range(of: Data("\r\n\r\n".utf8)) {
                let head = String(decoding: buffer[..<end.lowerBound], as: UTF8.self)
                self.route(head, connection)
            } else if error != nil || complete || buffer.count > 65_536 {
                connection.cancel()
            } else {
                self.readRequest(connection, buffer: buffer)
            }
        }
    }

    private func route(_ head: String, _ connection: NWConnection) {
        let requestLine = head.components(separatedBy: "\r\n").first ?? ""
        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2 else { return reply(connection, status: 400) }
        let path = String(parts[1])
        let token = path.split(separator: "/").last.map { String($0.split(separator: ".").first ?? "") } ?? ""
        guard let upstream = routes[token] else { return reply(connection, status: 404) }
        // Une seule connexion chez le fournisseur : la précédente est fermée avant d'ouvrir celle-ci.
        closeActive(reason: "nouvelle demande")
        let relay = RelaySession(client: connection, upstream: upstream)
        active = relay
        var request = URLRequest(url: upstream)
        request.setValue(HTTP.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("close", forHTTPHeaderField: "Connection")
        let task = session.dataTask(with: request)
        relay.task = task
        relay.opened = Date()
        PlaybackLog.shared.note("Relais : connexion au fournisseur (\(upstream.host ?? "?"))")
        watchClient(relay)
        task.resume()
    }

    /// Détecte la fermeture côté VLC (changement de chaîne, arrêt) pour fermer aussitôt la connexion au fournisseur.
    private func watchClient(_ relay: RelaySession) {
        relay.client.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] _, _, complete, error in
            guard let self else { return }
            if complete || error != nil {
                if self.active === relay { self.closeActive(reason: "lecteur fermé") }
            } else {
                self.watchClient(relay)
            }
        }
    }

    private func closeActive(reason: String?) {
        guard let relay = active else { return }
        active = nil
        relay.task?.cancel()
        relay.client.cancel()
        if let reason {
            let seconds = relay.opened.map { Date().timeIntervalSince($0) } ?? 0
            PlaybackLog.shared.note(String(format: "Relais : connexion au fournisseur fermée (%@, après %.0f s, %@)",
                                           reason, seconds, ByteCountFormatter.string(fromByteCount: relay.bytes, countStyle: .file)))
        }
    }

    private func reply(_ connection: NWConnection, status: Int) {
        let text = "HTTP/1.1 \(status) \(Self.reason(status))\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
        connection.send(content: Data(text.utf8), completion: .contentProcessed { _ in connection.cancel() })
    }

    private static func reason(_ status: Int) -> String {
        switch status {
        case 200: return "OK"
        case 400: return "Bad Request"
        case 401: return "Unauthorized"
        case 403: return "Forbidden"
        case 404: return "Not Found"
        default: return "Error"
        }
    }

    private func relay(for task: URLSessionTask) -> RelaySession? {
        guard let active, active.task === task else { return nil }
        return active
    }
}

// MARK: - Connexion au fournisseur

extension StreamRelay: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        queue.async {
            if self.relay(for: task) != nil {
                PlaybackLog.shared.note("Relais : redirection \(response.statusCode) vers \(request.url?.host ?? "?")")
            }
        }
        var next = request
        next.setValue(HTTP.userAgent, forHTTPHeaderField: "User-Agent")
        next.setValue("*/*", forHTTPHeaderField: "Accept")
        completionHandler(next)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        queue.async {
            guard let relay = self.relay(for: dataTask) else { return completionHandler(.cancel) }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            self.lastStatus = status
            let elapsed = relay.opened.map { Date().timeIntervalSince($0) } ?? 0
            PlaybackLog.shared.note(String(format: "Relais : réponse du fournisseur HTTP %d en %.2f s", status, elapsed))
            guard (200..<300).contains(status) else {
                self.active = nil
                // Le moteur VLC réessaie aussitôt de lui-même : on ne relaie pas ce nouvel essai chez le fournisseur
                // (Kastideo réessaie plus tard, avec une nouvelle adresse).
                self.routes.removeAll()
                self.reply(relay.client, status: status == 0 ? 502 : status)
                return completionHandler(.cancel)
            }
            let type = response.mimeType ?? "video/mp2t"
            let head = "HTTP/1.1 200 OK\r\nContent-Type: \(type)\r\nCache-Control: no-cache\r\nConnection: close\r\n\r\n"
            relay.client.send(content: Data(head.utf8), completion: .contentProcessed { _ in })
            completionHandler(.allow)
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        queue.async {
            guard let relay = self.relay(for: dataTask) else { return }
            relay.bytes += Int64(data.count)
            relay.client.send(content: data, completion: .contentProcessed { [weak self] error in
                guard let self, error != nil else { return }
                self.queue.async { if self.active === relay { self.closeActive(reason: "lecteur fermé") } }
            })
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        queue.async {
            guard let relay = self.relay(for: task) else { return }
            if let error, (error as NSError).code != NSURLErrorCancelled {
                PlaybackLog.shared.note("Relais : flux du fournisseur interrompu (\(error.localizedDescription))")
            } else {
                PlaybackLog.shared.note("Relais : le fournisseur a terminé le flux")
            }
            self.active = nil
            relay.client.send(content: nil, isComplete: true, completion: .contentProcessed { _ in relay.client.cancel() })
        }
    }
}

/// Une lecture relayée : la connexion du moteur VLC et la requête chez le fournisseur.
private final class RelaySession {
    let client: NWConnection
    let upstream: URL
    var task: URLSessionDataTask?
    var opened: Date?
    var bytes: Int64 = 0

    init(client: NWConnection, upstream: URL) {
        self.client = client
        self.upstream = upstream
    }
}
