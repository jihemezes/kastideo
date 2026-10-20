import Foundation

/// Retrouve le fichier écrit par VLC pendant un enregistrement, sans dépendre du chemin qu'il annonce
/// (VLCKit le transmet parfois vide, ou écrit dans un autre dossier que celui demandé).
enum RecordingLocator {
    private static let mediaExtensions: Set<String> = ["ts", "mp4", "mkv", "mpg", "mpeg", "avi", "mov", "m2ts", "webm", "flv", "ogg"]

    /// Dossiers où VLC peut avoir écrit, hors dossier de travail.
    private static var fallbackDirectories: [URL] {
        let manager = FileManager.default
        var urls = [manager.temporaryDirectory]
        for directory in [FileManager.SearchPathDirectory.downloadsDirectory, .documentsDirectory,
                          .moviesDirectory, .desktopDirectory, .cachesDirectory] {
            urls.append(contentsOf: manager.urls(for: directory, in: .userDomainMask))
        }
        urls.append(RecordingFolder.realHome.appendingPathComponent("Movies", isDirectory: true))
        return urls
    }

    /// Le fichier le plus récent apparu depuis `since` : d'abord dans le dossier de travail (tout fichier),
    /// puis ailleurs (fichiers « vlc-record… » uniquement).
    static func find(workDir: URL, since: Date, includeFallbacks: Bool = true) -> URL? {
        if let url = newest(in: workDir, since: since, onlyVLCNames: false) { return url }
        guard includeFallbacks else { return nil }
        for directory in fallbackDirectories {
            if let url = newest(in: directory, since: since, onlyVLCNames: true) { return url }
        }
        return nil
    }

    /// Taille d'un fichier, en octets.
    static func size(of url: URL) -> Int64 {
        Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
    }

    private static func newest(in directory: URL, since: Date, onlyVLCNames: Bool) -> URL? {
        let keys: [URLResourceKey] = [.contentModificationDateKey, .creationDateKey, .fileSizeKey, .isRegularFileKey]
        guard let urls = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: keys,
                                                                      options: [.skipsHiddenFiles]) else { return nil }
        var best: (URL, Date)?
        for url in urls {
            guard let values = try? url.resourceValues(forKeys: Set(keys)), values.isRegularFile == true,
                  (values.fileSize ?? 0) > 0 else { continue }
            if onlyVLCNames {
                guard url.lastPathComponent.lowercased().hasPrefix("vlc-record"),
                      mediaExtensions.contains(url.pathExtension.lowercased()) else { continue }
            }
            let date = max(values.contentModificationDate ?? .distantPast, values.creationDate ?? .distantPast)
            guard date >= since.addingTimeInterval(-2) else { continue }
            if best == nil || date > best!.1 { best = (url, date) }
        }
        return best?.0
    }
}
