import Foundation
import Security

/// Cache disque (dossier Application Support du bac à sable).
enum Storage {
    static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Kastideo", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func url(_ name: String) -> URL { directory.appendingPathComponent("\(name).json") }

    static func save<T: Encodable>(_ value: T, name: String) {
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: url(name), options: .atomic)
        } catch {
            NSLog("Kastideo — échec d'écriture du cache %@ : %@", name, error.localizedDescription)
        }
    }

    static func load<T: Decodable>(_ type: T.Type, name: String) -> T? {
        guard let data = try? Data(contentsOf: url(name)) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    static func delete(name: String) {
        try? FileManager.default.removeItem(at: url(name))
    }

    /// Taille totale du cache, en octets.
    static func size() -> Int64 {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        return files.reduce(0) { total, file in
            total + Int64((try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
    }

    static func clear() {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        // Les logos choisis par l'utilisateur ne font pas partie du cache.
        for file in files where file.lastPathComponent != "logos" { try? FileManager.default.removeItem(at: file) }
    }
}

/// Mots de passe Xtream stockés dans le trousseau macOS (jamais en clair sur le disque).
enum Keychain {
    static let service = "fr.jmezes.kastideo.xtream"

    static func set(_ password: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = Data(password.utf8)
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(attributes as CFDictionary, nil)
        if status != errSecSuccess { NSLog("Kastideo — trousseau : erreur %d", status) }
    }

    static func get(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
