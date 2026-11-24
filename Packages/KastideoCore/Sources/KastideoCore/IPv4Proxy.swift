import Foundation
#if canImport(Network)
import Network
#endif

/// Option « Forcer IPv4 » : certains fournisseurs répondent par une erreur (HTTP 520 de Cloudflare par exemple) quand on
/// les joint en IPv6, alors que tout fonctionne en IPv4. macOS préfère IPv6 et ne bascule pas de lui-même : la réponse
/// d'erreur est une vraie réponse.
///
/// URLSession ne permet pas de limiter une connexion à IPv4. Kastideo démarre donc un petit proxy local (127.0.0.1) qui
/// ouvre toutes ses connexions sortantes en IPv4 uniquement : les requêtes HTTPS passent en tunnel (CONNECT), le chiffrement
/// et le nom du site restent ceux de URLSession ; les requêtes HTTP simples sont retransmises telles quelles.
public final class IPv4Proxy: @unchecked Sendable {
    public static let shared = IPv4Proxy()

    /// Clé du réglage (UserDefaults) : faux par défaut.
    public static let defaultsKey = "network.forceIPv4"

    public static var isEnabled: Bool { UserDefaults.standard.bool(forKey: defaultsKey) }

    /// Réglage de proxy à donner à `URLSessionConfiguration.connectionProxyDictionary`, ou nil si l'option est coupée
    /// (ou si le proxy n'a pas pu démarrer : la connexion se fait alors normalement).
    public static func proxyDictionary() -> [AnyHashable: Any]? {
        #if canImport(Network)
        guard isEnabled, let port = shared.ensureStarted() else { return nil }
        return ["HTTPEnable": 1, "HTTPProxy": "127.0.0.1", "HTTPPort": Int(port),
                "HTTPSEnable": 1, "HTTPSProxy": "127.0.0.1", "HTTPSPort": Int(port)]
        #else
        return nil
        #endif
    }

    #if canImport(Network)
    private let queue = DispatchQueue(label: "fr.jmezes.kastideo.ipv4proxy")
    private var listener: NWListener?
    private var port: UInt16?
    private var pairs: [ObjectIdentifier: Pair] = [:]

    /// Un client et sa connexion sortante en IPv4.
    private final class Pair {
        let client: NWConnection
        var upstream: NWConnection?
        var open = 2

        init(client: NWConnection) { self.client = client }

        func cancel() {
            client.cancel()
            upstream?.cancel()
        }
    }

    private init() {}

    /// Démarre l'écoute si besoin et renvoie le port (attend au plus une seconde).
    func ensureStarted() -> UInt16? {
        queue.sync { startListener() }
        let deadline = Date().addingTimeInterval(1)
        while Date() < deadline {
            if let port = queue.sync(execute: { self.port }) { return port }
            Thread.sleep(forTimeInterval: 0.01)
        }
        return queue.sync { port }
    }

    private func startListener() {
        guard listener == nil else { return }
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = NWEndpoint.hostPort(host: "127.0.0.1", port: .any)
        parameters.allowLocalEndpointReuse = true
        guard let listener = try? NWListener(using: parameters) else { return }
        listener.stateUpdateHandler = { [weak self, weak listener] state in
            guard let self else { return }
            switch state {
            case .ready:
                self.port = listener?.port?.rawValue
            case .failed, .cancelled:
                self.port = nil
                self.listener = nil
            default:
                break
            }
        }
        listener.newConnectionHandler = { [weak self] connection in self?.accept(connection) }
        listener.start(queue: queue)
        self.listener = listener
    }

    // MARK: - Connexions

    private func accept(_ client: NWConnection) {
        let pair = Pair(client: client)
        pairs[ObjectIdentifier(pair)] = pair
        client.stateUpdateHandler = { [weak self, weak pair] state in
            guard let self, let pair else { return }
            if case .failed = state { self.close(pair) }
            if case .cancelled = state { self.pairs[ObjectIdentifier(pair)] = nil }
        }
        client.start(queue: queue)
        readHead(pair, buffer: Data())
    }

    private func close(_ pair: Pair) {
        pair.cancel()
        pairs[ObjectIdentifier(pair)] = nil
    }

    /// Lit la première requête du client (jusqu'à la ligne vide).
    private func readHead(_ pair: Pair, buffer: Data) {
        pair.client.receive(minimumIncompleteLength: 1, maximumLength: 16384) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            var buffer = buffer
            if let data { buffer.append(data) }
            if let end = buffer.range(of: Data("\r\n\r\n".utf8)) {
                let head = String(decoding: buffer[..<end.lowerBound], as: UTF8.self)
                let rest = Data(buffer[end.upperBound...])
                self.handle(pair, head: head, rest: rest)
            } else if error != nil || isComplete || buffer.count > 65536 {
                self.close(pair)
            } else {
                self.readHead(pair, buffer: buffer)
            }
        }
    }

    private func handle(_ pair: Pair, head: String, rest: Data) {
        var lines = head.components(separatedBy: "\r\n")
        let parts = lines.removeFirst().split(separator: " ").map(String.init)
        guard parts.count >= 2 else { return fail(pair, "400 Bad Request") }
        let method = parts[0]
        let version = parts.count > 2 ? parts[2] : "HTTP/1.1"
        if method.uppercased() == "CONNECT" {
            // HTTPS : tunnel brut vers hote:port.
            let target = parts[1]
            guard let colon = target.lastIndex(of: ":"), let port = UInt16(target[target.index(after: colon)...]) else {
                return fail(pair, "400 Bad Request")
            }
            let host = String(target[..<colon]).trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
            connect(pair, host: host, port: port) { [weak self] in
                pair.client.send(content: Data("HTTP/1.1 200 Connection Established\r\n\r\n".utf8), completion: .contentProcessed { error in
                    guard error == nil else { self?.close(pair); return }
                    self?.start(pair, initial: rest)
                })
            }
        } else if let url = URL(string: parts[1]), let host = url.host {
            // HTTP simple : requête en forme « origine », une connexion par requête.
            var path = url.path.isEmpty ? "/" : url.path
            if let query = url.query { path += "?" + query }
            var request = "\(method) \(path) \(version)\r\n"
            for line in lines where !line.isEmpty {
                let name = line.split(separator: ":", maxSplits: 1).first.map { $0.lowercased() } ?? ""
                if name == "proxy-connection" || name == "proxy-authorization" || name == "connection" { continue }
                request += line + "\r\n"
            }
            request += "Connection: close\r\n\r\n"
            connect(pair, host: host, port: UInt16(url.port ?? 80)) { [weak self] in
                self?.start(pair, initial: Data(request.utf8) + rest)
            }
        } else {
            fail(pair, "400 Bad Request")
        }
    }

    /// Connexion sortante limitée à IPv4.
    private func connect(_ pair: Pair, host: String, port: UInt16, ready: @escaping () -> Void) {
        guard let nwPort = NWEndpoint.Port(rawValue: port) else { return fail(pair, "400 Bad Request") }
        let parameters = NWParameters.tcp
        if let ip = parameters.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options {
            ip.version = .v4
        }
        let upstream = NWConnection(host: NWEndpoint.Host(host), port: nwPort, using: parameters)
        pair.upstream = upstream
        var announced = false
        upstream.stateUpdateHandler = { [weak self, weak pair] state in
            guard let self, let pair else { return }
            switch state {
            case .ready:
                if !announced {
                    announced = true
                    ready()
                }
            case .failed, .waiting:
                if !announced { self.fail(pair, "502 Bad Gateway") } else { self.close(pair) }
            default:
                break
            }
        }
        upstream.start(queue: queue)
    }

    private func fail(_ pair: Pair, _ status: String) {
        pair.client.send(content: Data("HTTP/1.1 \(status)\r\nConnection: close\r\nContent-Length: 0\r\n\r\n".utf8),
                         completion: .contentProcessed { [weak self] _ in self?.close(pair) })
    }

    /// Fait passer les octets dans les deux sens ; la connexion se ferme quand les deux sens sont terminés.
    private func start(_ pair: Pair, initial: Data) {
        guard let upstream = pair.upstream else { return close(pair) }
        if !initial.isEmpty {
            upstream.send(content: initial, completion: .contentProcessed { [weak self] error in
                if error != nil { self?.close(pair); return }
                self?.pump(pair, from: pair.client, to: upstream)
            })
        } else {
            pump(pair, from: pair.client, to: upstream)
        }
        pump(pair, from: upstream, to: pair.client)
    }

    private func pump(_ pair: Pair, from: NWConnection, to: NWConnection) {
        from.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            if error != nil { self.close(pair); return }
            let finished = {
                // Ce sens est terminé : on prévient l'autre bout, et on ferme quand les deux sens le sont.
                to.send(content: nil, contentContext: .finalMessage, isComplete: true, completion: .contentProcessed { _ in })
                pair.open -= 1
                if pair.open <= 0 { self.close(pair) }
            }
            if let data, !data.isEmpty {
                to.send(content: data, completion: .contentProcessed { error in
                    if error != nil { self.close(pair); return }
                    if isComplete { finished() } else { self.pump(pair, from: from, to: to) }
                })
            } else if isComplete {
                finished()
            } else {
                self.pump(pair, from: from, to: to)
            }
        }
    }
    #endif
}
