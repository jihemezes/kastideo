import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// Serveur trouvé sur le réseau de la maison.
public struct DiscoveredServer: Sendable, Hashable, Identifiable {
    public var type: MediaServerType
    public var name: String
    public var address: String
    public var id: String { type.rawValue + address }

    public init(type: MediaServerType, name: String, address: String) {
        self.type = type
        self.name = name
        self.address = address
    }
}

/// Recherche des serveurs Jellyfin et Emby (diffusion UDP sur le port 7359) et Plex (GDM, port 32414).
public enum ServerDiscovery {
    /// Réponse d'un serveur : JSON (Jellyfin, Emby) ou en-têtes HTTP (Plex GDM).
    public static func parseReply(_ text: String, from address: String, hint: MediaServerType = .jellyfin) -> DiscoveredServer? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("{") {
            guard let data = trimmed.data(using: .utf8),
                  let map = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                  let server = map["Address"] as? String else { return nil }
            return DiscoveredServer(type: hint == .emby ? .emby : .jellyfin, name: map["Name"] as? String ?? server, address: server)
        }
        if trimmed.hasPrefix("HTTP/") {
            var headers: [String: String] = [:]
            for line in trimmed.components(separatedBy: .newlines).dropFirst() {
                guard let colon = line.firstIndex(of: ":") else { continue }
                headers[line[..<colon].trimmingCharacters(in: .whitespaces).lowercased()] =
                    line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            }
            guard (headers["content-type"] ?? "").contains("plex/media-server") else { return nil }
            return DiscoveredServer(type: .plex, name: headers["name"] ?? "Plex", address: "http://\(address):\(headers["port"] ?? "32400")")
        }
        return nil
    }

    /// Envoie les questions et rassemble les réponses pendant `wait` secondes.
    public static func scan(wait: TimeInterval = 3) async -> [DiscoveredServer] {
        await withTaskGroup(of: [DiscoveredServer].self) { group in
            group.addTask { ask("who is JellyfinServer?", targets: [("255.255.255.255", 7359)], hint: .jellyfin, wait: wait) }
            group.addTask { ask("who is EmbyServer?", targets: [("255.255.255.255", 7359)], hint: .emby, wait: wait) }
            group.addTask {
                ask("M-SEARCH * HTTP/1.1\r\n\r\n", targets: [("239.0.0.250", 32414), ("255.255.255.255", 32414)], hint: .plex, wait: wait)
            }
            var found = Set<DiscoveredServer>()
            for await list in group { found.formUnion(list) }
            return found.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
    }

    /// Une socket par question : la réponse dit de quel serveur il s'agit.
    private static func ask(_ message: String, targets: [(String, UInt16)], hint: MediaServerType, wait: TimeInterval) -> [DiscoveredServer] {
        #if canImport(Glibc)
        let fd = socket(AF_INET, Int32(SOCK_DGRAM.rawValue), 0)
        #else
        let fd = socket(AF_INET, SOCK_DGRAM, 0)
        #endif
        guard fd >= 0 else { return [] }
        defer { close(fd) }
        var yes: Int32 = 1
        setsockopt(fd, SOL_SOCKET, SO_BROADCAST, &yes, socklen_t(MemoryLayout<Int32>.size))
        var timeout = timeval(tv_sec: 0, tv_usec: 300_000)
        setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
        let bytes = Array(message.utf8)
        func send() {
            for (host, port) in targets {
                var addr = sockaddr_in()
                addr.sin_family = sa_family_t(AF_INET)
                addr.sin_port = port.bigEndian
                inet_pton(AF_INET, host, &addr.sin_addr)
                _ = withUnsafePointer(to: &addr) { pointer in
                    pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                        sendto(fd, bytes, bytes.count, 0, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                    }
                }
            }
        }
        send()
        var found = Set<DiscoveredServer>()
        let deadline = Date().addingTimeInterval(wait)
        var resent = false
        var buffer = [UInt8](repeating: 0, count: 4096)
        while Date() < deadline {
            if !resent, Date() > deadline.addingTimeInterval(-wait + 0.3) {
                send()   // une seconde fois : un paquet de diffusion peut se perdre
                resent = true
            }
            var from = sockaddr_in()
            var length = socklen_t(MemoryLayout<sockaddr_in>.size)
            let count = withUnsafeMutablePointer(to: &from) { pointer in
                pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { recvfrom(fd, &buffer, buffer.count, 0, $0, &length) }
            }
            guard count > 0 else { continue }
            var host = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
            inet_ntop(AF_INET, &from.sin_addr, &host, socklen_t(INET_ADDRSTRLEN))
            let text = String(decoding: buffer[0..<count], as: UTF8.self)
            if let server = parseReply(text, from: String(cString: host), hint: hint) { found.insert(server) }
        }
        return Array(found)
    }
}
