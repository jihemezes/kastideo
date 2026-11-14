import SwiftUI
import Network
import CoreImage.CIFilterBuiltins
import KastideoCore

/// Saisie d'une source depuis un téléphone : l'Apple TV ouvre une petite page web sur le réseau local,
/// protégée par un code à 4 chiffres affiché à l'écran. Rien ne sort de votre réseau.
@MainActor
@Observable
final class TVRemoteSetup {
    private(set) var isRunning = false
    private(set) var address: String?
    private(set) var code = ""
    private(set) var lastAdded: String?
    private(set) var failure: String?
    @ObservationIgnored private var listener: NWListener?
    @ObservationIgnored private var store: LibraryStore?
    let port: UInt16 = 8765

    var url: String? { address.map { "http://\($0):\(port)" } }

    func start(store: LibraryStore) {
        guard !isRunning else { return }
        self.store = store
        code = String(format: "%04d", Int.random(in: 0...9999))
        address = Self.localAddress()
        failure = nil
        lastAdded = nil
        do {
            let listener = try NWListener(using: .tcp, on: NWEndpoint.Port(rawValue: port)!)
            listener.newConnectionHandler = { [weak self] connection in
                let handler = TVHTTPConnection(connection: connection) { fields in
                    guard let owner = self else { return "Indisponible." }
                    return await owner.handle(fields)
                } expectedCode: { [weak self] in
                    await self?.code ?? ""
                }
                handler.start()
            }
            listener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    switch state {
                    case .ready: self?.isRunning = true
                    case .failed(let error):
                        self?.failure = error.localizedDescription
                        self?.isRunning = false
                    default: break
                    }
                }
            }
            listener.start(queue: .global(qos: .userInitiated))
            self.listener = listener
        } catch {
            failure = error.localizedDescription
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
    }

    /// Ajoute la source reçue ; renvoie un message d'erreur, ou nil si tout va bien.
    private func handle(_ f: [String: String]) -> String? {
        guard let store else { return "Indisponible." }
        var text = (f["server"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.contains("://") { text = "http://" + text }
        guard let url = URL(string: text), url.host != nil else { return "Adresse invalide." }
        let title = (f["name"] ?? "").trimmingCharacters(in: .whitespaces)
        if f["type"] == "xtream" {
            let user = (f["user"] ?? "").trimmingCharacters(in: .whitespaces)
            let pass = f["pass"] ?? ""
            guard !user.isEmpty, !pass.isEmpty else { return "Identifiant et mot de passe requis." }
            store.addSource(Source(name: title.isEmpty ? (url.host ?? "Xtream") : title, kind: .xtream(server: url, username: user)), password: pass)
            lastAdded = title.isEmpty ? (url.host ?? "Xtream") : title
        } else {
            store.addSource(Source(name: title.isEmpty ? (url.host ?? "M3U") : title, kind: .m3uURL(url)), password: nil)
            lastAdded = title.isEmpty ? (url.host ?? "M3U") : title
        }
        return nil
    }

    /// Adresse IPv4 de l'Apple TV sur le réseau local.
    static func localAddress() -> String? {
        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0, let first = head else { return nil }
        defer { freeifaddrs(head) }
        var found: String?
        var pointer: UnsafeMutablePointer<ifaddrs>? = first
        while let current = pointer {
            let entry = current.pointee
            if entry.ifa_addr.pointee.sa_family == UInt8(AF_INET),
               (entry.ifa_flags & UInt32(IFF_UP)) != 0, (entry.ifa_flags & UInt32(IFF_LOOPBACK)) == 0,
               String(cString: entry.ifa_name).hasPrefix("en") {
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(entry.ifa_addr, socklen_t(entry.ifa_addr.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 {
                    found = String(cString: host)
                    break
                }
            }
            pointer = entry.ifa_next
        }
        return found
    }

    static func qrImage(_ text: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
              let cg = CIContext().createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

/// Une connexion HTTP : GET / renvoie le formulaire, POST /add ajoute la source.
final class TVHTTPConnection: @unchecked Sendable {
    private let connection: NWConnection
    private let onAdd: @Sendable ([String: String]) async -> String?
    private let expectedCode: @Sendable () async -> String
    private var buffer = Data()

    init(connection: NWConnection, onAdd: @escaping @Sendable ([String: String]) async -> String?,
         expectedCode: @escaping @Sendable () async -> String) {
        self.connection = connection
        self.onAdd = onAdd
        self.expectedCode = expectedCode
    }

    func start() {
        connection.start(queue: .global(qos: .userInitiated))
        receive()
    }

    private func receive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [self] data, _, finished, error in
            if let data { buffer.append(data) }
            if error != nil { connection.cancel(); return }
            if let request = parseComplete() {
                Task { await respond(request) }
            } else if finished || buffer.count > 200_000 {
                connection.cancel()
            } else {
                receive()
            }
        }
    }

    private struct Request { var method: String; var path: String; var body: String }

    private func parseComplete() -> Request? {
        guard let range = buffer.range(of: Data("\r\n\r\n".utf8)) else { return nil }
        let head = String(decoding: buffer[..<range.lowerBound], as: UTF8.self)
        let lines = head.components(separatedBy: "\r\n")
        let parts = (lines.first ?? "").split(separator: " ")
        guard parts.count >= 2 else { return nil }
        var length = 0
        for line in lines.dropFirst() where line.lowercased().hasPrefix("content-length:") {
            length = Int(line.dropFirst("content-length:".count).trimmingCharacters(in: .whitespaces)) ?? 0
        }
        let bodyData = buffer[range.upperBound...]
        guard bodyData.count >= length else { return nil }
        return Request(method: String(parts[0]), path: String(parts[1]), body: String(decoding: bodyData.prefix(length), as: UTF8.self))
    }

    private func respond(_ request: Request) async {
        if request.method == "POST", request.path.hasPrefix("/add") {
            var fields: [String: String] = [:]
            for pair in request.body.split(separator: "&") {
                let kv = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
                guard kv.count == 2 else { continue }
                func decode(_ s: Substring) -> String { String(s).replacingOccurrences(of: "+", with: " ").removingPercentEncoding ?? "" }
                fields[decode(kv[0])] = decode(kv[1])
            }
            let expected = await expectedCode()
            if (fields["code"] ?? "") != expected {
                send(page(message: "Code incorrect.", ok: false))
            } else if let error = await onAdd(fields) {
                send(page(message: error, ok: false))
            } else {
                send(page(message: "Source ajoutée. Regardez votre téléviseur.", ok: true))
            }
        } else {
            send(page(message: nil, ok: true))
        }
    }

    private func send(_ html: String) {
        let body = Data(html.utf8)
        let head = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: \(body.count)\r\nConnection: close\r\n\r\n"
        connection.send(content: Data(head.utf8) + body, completion: .contentProcessed { [connection] _ in connection.cancel() })
    }

    private func page(message: String?, ok: Bool) -> String {
        let banner = message.map { "<p style='padding:12px;border-radius:10px;background:\(ok ? "#1f6f3f" : "#8a2a2a");color:#fff'>\($0)</p>" } ?? ""
        return """
        <!doctype html><html lang="fr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
        <title>Kastideo</title><style>
        body{font-family:-apple-system,sans-serif;background:#111;color:#eee;margin:0;padding:24px;max-width:520px}
        h1{color:#ff9f0a;font-size:26px} label{display:block;margin-top:14px;font-size:14px;color:#aaa}
        input,select{width:100%;box-sizing:border-box;padding:12px;font-size:17px;border-radius:10px;border:1px solid #444;background:#222;color:#fff;margin-top:4px}
        button{margin-top:22px;width:100%;padding:14px;font-size:18px;border:0;border-radius:12px;background:#ff9f0a;color:#000;font-weight:600}
        </style></head><body><h1>Kastideo · Apple TV</h1>\(banner)
        <form method="post" action="/add">
        <label>Code affiché sur le téléviseur<input name="code" inputmode="numeric" maxlength="4" required></label>
        <label>Type<select name="type"><option value="xtream">Xtream Codes</option><option value="m3u">Liste M3U (adresse)</option></select></label>
        <label>Nom (facultatif)<input name="name"></label>
        <label>Serveur ou adresse de la liste<input name="server" autocapitalize="none" autocorrect="off" required></label>
        <label>Identifiant (Xtream)<input name="user" autocapitalize="none" autocorrect="off"></label>
        <label>Mot de passe (Xtream)<input name="pass" type="password"></label>
        <button type="submit">Ajouter à l'Apple TV</button></form></body></html>
        """
    }
}

/// Écran « Ajouter depuis un téléphone » : adresse, code et QR code.
struct TVRemoteSetupView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(TVRemoteSetup.self) private var setup

    var body: some View {
        HStack(alignment: .top, spacing: 80) {
            if let url = setup.url, let image = TVRemoteSetup.qrImage(url) {
                Image(uiImage: image).interpolation(.none).resizable().frame(width: 360, height: 360)
                    .padding(20).background(.white, in: RoundedRectangle(cornerRadius: 16))
            }
            VStack(alignment: .leading, spacing: 22) {
                Text("Saisir depuis un téléphone").font(.title.bold())
                Text("Sur un téléphone ou un ordinateur du même réseau Wi-Fi, scannez le QR code ou ouvrez cette adresse :")
                    .foregroundStyle(.secondary)
                Text(setup.url ?? String(localized: "Réseau local introuvable")).font(.title2.monospaced())
                Text("Code : \(setup.code)").font(.system(size: 60, weight: .bold, design: .rounded)).foregroundStyle(TVPalette.orange)
                if let added = setup.lastAdded {
                    Label("Source « \(added) » ajoutée.", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                }
                if let failure = setup.failure { Text(failure).foregroundStyle(.red) }
                Text("La saisie reste sur votre réseau local et n'est active que sur cet écran.")
                    .font(.callout).foregroundStyle(.secondary)
            }
        }
        .padding(60)
        .onAppear { setup.start(store: store) }
        .onDisappear { setup.stop() }
    }
}
