import Foundation

/// Ce qu'un nom de fichier vidéo laisse deviner.
public enum LocalKind: Sendable, Equatable {
    case movie, episode, video
}

public struct LocalEntry: Sendable, Equatable {
    public var kind: LocalKind
    public var title: String
    public var year: Int?
    public var series: String?
    public var season: Int?
    public var episode: Int?
}

/// Reconnaît films, épisodes et vidéos personnelles d'après leur nom et leur dossier
/// (« Titre (2020).mkv », « Titre.2020.1080p.mkv », « Série S01E02 », « Série/Saison 1/1x02 »…).
/// Mêmes règles que la version Windows / Linux.
public enum LocalNameParser {
    public static let videoExtensions: Set<String> = ["mkv", "mp4", "m4v", "avi", "mov", "wmv", "ts", "m2ts", "mts", "mpg", "mpeg",
                                                      "webm", "flv", "vob", "ogv", "3gp", "divx"]
    public static let subtitleExtensions: Set<String> = ["srt", "ass", "ssa", "vtt", "sub"]

    private static func re(_ pattern: String, _ insensitive: Bool = true) -> NSRegularExpression {
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: pattern, options: insensitive ? [.caseInsensitive] : [])
    }

    static let episodeRE = re(#"(?:^|[^a-z0-9])s(\d{1,2})[ ._-]*e(\d{1,3})(?:[^0-9]|$)"#)
    static let episodeXRE = re(#"(?:^|[^0-9])(\d{1,2})x(\d{2,3})(?:[^0-9]|$)"#)
    static let seasonFolderRE = re(#"^(?:saison|season|staffel|temporada|s)[ ._-]*(\d{1,2})$"#)
    static let yearRE = re(#"(?:^|[\s.(\[_-])((?:19|20)\d{2})(?:[\s.)\]_-]|$)"#, false)
    static let numberRE = re(#"^(?:e|ep|episode|épisode)?[ ._-]*(\d{1,3})(?:[^0-9]|$)"#)
    static let tagsRE = re(
        #"\b(2160p|1080p|1080i|720p|576p|480p|4k|uhd|hdr10?|hdr|dv|dolby|vision|x264|x265|h\.?264|h\.?265|hevc|avc|xvid|divx|"#
        + #"bluray|blu-ray|bdrip|brrip|webrip|web-dl|webdl|web|hdtv|dvdrip|dvd|remux|proper|repack|extended|unrated|"#
        + #"multi|truefrench|french|vff|vfq|vf2|vf|vostfr|vost|subfrench|english|dts|ac3|eac3|aac|ddp?5\.?1|5\.1|7\.1|atmos|10bit)\b.*$"#)

    private static func firstMatch(_ re: NSRegularExpression, _ s: String) -> NSTextCheckingResult? {
        re.firstMatch(in: s, range: NSRange(s.startIndex..., in: s))
    }

    private static func lastMatch(_ re: NSRegularExpression, _ s: String) -> NSTextCheckingResult? {
        re.matches(in: s, range: NSRange(s.startIndex..., in: s)).last
    }

    private static func group(_ m: NSTextCheckingResult, _ i: Int, in s: String) -> String? {
        guard let r = Range(m.range(at: i), in: s) else { return nil }
        return String(s[r])
    }

    private static func replace(_ s: String, _ pattern: String, _ with: String) -> String {
        s.replacingOccurrences(of: pattern, with: with, options: .regularExpression)
    }

    static func clean(_ raw: String) -> String {
        var t = replace(raw, #"[._]+"#, " ")
        t = replace(t, #"\[[^\]]*\]"#, " ")
        if let m = firstMatch(tagsRE, t), let r = Range(m.range, in: t) { t.removeSubrange(r) }
        t = replace(t, #"\s+"#, " ").trimmingCharacters(in: .whitespaces)
        while let last = t.last, "-–([{".contains(last) { t = String(t.dropLast()).trimmingCharacters(in: .whitespaces) }
        while let first = t.first, "-–)]}".contains(first) { t = String(t.dropFirst()).trimmingCharacters(in: .whitespaces) }
        return t
    }

    static func components(_ path: String) -> [String] {
        path.split(whereSeparator: { $0 == "/" || $0 == "\\" }).map(String.init)
    }

    public static func baseName(_ path: String) -> String {
        let name = components(path).last ?? path
        guard let dot = name.lastIndex(of: "."), dot != name.startIndex else { return name }
        return String(name[..<dot])
    }

    private static func removingYear(_ s: String) -> String {
        guard let m = firstMatch(yearRE, s), let r = Range(m.range, in: s) else { return s }
        var copy = s
        copy.removeSubrange(r)
        return copy.trimmingCharacters(in: .whitespaces)
    }

    /// `relative` : chemin du fichier par rapport au dossier de la source (ses sous-dossiers aident à le reconnaître).
    /// `aloneInFolder` : seule vidéo de son dossier (« Titre (2020)/film.mkv ») ; sinon l'année du dossier
    /// (« Vacances 2024/plage.mp4 ») ne fait pas un film.
    public static func parse(_ relative: String, aloneInFolder: Bool = true) -> LocalEntry {
        let base = baseName(relative)
        let parts = components(relative)
        let folders = parts.count > 1 ? Array(parts.dropLast()) : []
        // Épisode : SxxEyy ou 1x02 dans le nom (ou, à défaut, dans le dossier).
        if let m = firstMatch(episodeRE, base) ?? firstMatch(episodeXRE, base),
           let season = group(m, 1, in: base).flatMap(Int.init), let episode = group(m, 2, in: base).flatMap(Int.init),
           let whole = Range(m.range, in: base) {
            var series = clean(String(base[..<whole.lowerBound]))
            let rest = clean(String(base[whole.upperBound...]))
            if series.isEmpty {
                // « Série/Saison 1/S01E02.mkv » : le nom de la série est celui du dossier.
                for f in folders.reversed() {
                    if firstMatch(seasonFolderRE, f.trimmingCharacters(in: .whitespaces)) != nil { continue }
                    series = clean(f)
                    break
                }
            }
            series = removingYear(series)
            if series.isEmpty { series = "Série" }
            return LocalEntry(kind: .episode, title: rest.isEmpty ? "Épisode \(episode)" : rest, series: series,
                              season: season, episode: episode)
        }
        // Dossier « Saison 2 » sans SxxEyy : numéro d'épisode en tête du nom.
        if folders.count >= 2, let sm = firstMatch(seasonFolderRE, folders[folders.count - 1].trimmingCharacters(in: .whitespaces)),
           let season = group(sm, 1, in: folders[folders.count - 1].trimmingCharacters(in: .whitespaces)).flatMap(Int.init),
           let nm = firstMatch(numberRE, base), let number = group(nm, 1, in: base).flatMap(Int.init),
           let nr = Range(nm.range, in: base) {
            let series = removingYear(clean(folders[folders.count - 2]))
            // La correspondance avale le caractère qui suit le numéro : il fait partie du reste.
            var restStart = nr.upperBound
            if let digits = Range(nm.range(at: 1), in: base) { restStart = digits.upperBound }
            let rest = clean(String(base[restStart...]))
            return LocalEntry(kind: .episode, title: rest.isEmpty ? "Épisode \(number)" : rest,
                              series: series.isEmpty ? "Série" : series, season: season, episode: number)
        }
        // Film : une année dans le nom, ou dans le dossier « Titre (2020) ».
        if let y = lastMatch(yearRE, base), let year = group(y, 1, in: base).flatMap(Int.init), let r = Range(y.range, in: base) {
            let title = clean(String(base[..<r.lowerBound]))
            if !title.isEmpty { return LocalEntry(kind: .movie, title: title, year: year) }
        }
        if let folder = folders.last, aloneInFolder, let y = lastMatch(yearRE, folder),
           let year = group(y, 1, in: folder).flatMap(Int.init), let r = Range(y.range, in: folder) {
            let title = clean(String(folder[..<r.lowerBound]))
            if !title.isEmpty { return LocalEntry(kind: .movie, title: title, year: year) }
        }
        // Étiquettes de version (1080p, BluRay…) sans année : sans doute un film quand même.
        if firstMatch(tagsRE, replace(base, #"[._]+"#, " ")) != nil {
            let title = clean(base)
            if !title.isEmpty { return LocalEntry(kind: .movie, title: title) }
        }
        let title = clean(base)
        return LocalEntry(kind: .video, title: title.isEmpty ? base : title)
    }
}

/// Empreinte stable d'un texte (FNV-1a 32 bits), identique sur Mac, Windows et Linux.
public func stableHash(_ text: String) -> String {
    var h: UInt32 = 0x811c9dc5
    for byte in text.utf8 {
        h = (h ^ UInt32(byte)) &* 0x01000193
    }
    return String(h, radix: 16)
}

/// Examen des dossiers d'une source (disque, clé USB, NAS monté) : films, séries (épisodes regroupés) et vidéos.
public enum FolderScanner {
    public struct Labels: Sendable {
        public var movies: String
        public var series: String
        public var videos: String
        public init(movies: String = "Films", series: String = "Séries", videos: String = "Vidéos") {
            self.movies = movies
            self.series = series
            self.videos = videos
        }
    }

    private static let skipped: Set<String> = ["system volume information", "$recycle.bin", "@eadir", "#recycle", "lost+found",
                                               ".trash", ".trashes"]

    /// Fichiers d'un dossier et de ses sous-dossiers. Un sous-dossier illisible est ignoré sans interrompre l'examen ;
    /// les liens symboliques sont suivis, sans boucle.
    public static func files(in root: URL, maxDepth: Int = 12) -> [URL] {
        var files: [URL] = []
        var visited = Set<String>()
        let fm = FileManager.default
        func walk(_ dir: URL, _ depth: Int) {
            guard depth <= maxDepth, visited.insert(dir.resolvingSymlinksInPath().path).inserted else { return }
            guard let entries = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isDirectoryKey],
                                                            options: [.skipsHiddenFiles]) else { return }
            for entry in entries {
                let name = entry.lastPathComponent
                if name.hasPrefix(".") { continue }
                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: entry.path, isDirectory: &isDir) else { continue }
                if isDir.boolValue {
                    if !skipped.contains(name.lowercased()) { walk(entry, depth + 1) }
                } else {
                    files.append(entry)
                }
            }
        }
        walk(root, 0)
        return files
    }

    /// Identifiants : « <source>:movie:<empreinte du chemin> », « <source>:series:<empreinte du nom> », « <source>:episode:… ».
    public static func scan(roots: [URL], sourceID: UUID, labels: Labels = Labels()) -> SourceContent {
        var items: [MediaItem] = []
        var seriesIDs: [String: String] = [:]
        var seriesNames: [String: String] = [:]
        var seriesRoots: [String: String] = [:]
        let prefix = sourceID.uuidString
        for root in roots {
            let rootPath = root.standardizedFileURL.path
            let rootName = root.lastPathComponent
            let videos = files(in: root).filter { LocalNameParser.videoExtensions.contains($0.pathExtension.lowercased()) }
            var perFolder: [String: Int] = [:]
            for url in videos { perFolder[url.deletingLastPathComponent().path, default: 0] += 1 }
            for url in videos {
                let path = url.standardizedFileURL.path
                var relative = path.hasPrefix(rootPath) ? String(path.dropFirst(rootPath.count)) : url.lastPathComponent
                while relative.hasPrefix("/") { relative.removeFirst() }
                if relative.range(of: #"(^|/)(sample|trailers?|extras?|featurettes?)(/|$)"#,
                                  options: [.regularExpression, .caseInsensitive]) != nil { continue }
                let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
                let entry = LocalNameParser.parse(relative, aloneInFolder: perFolder[url.deletingLastPathComponent().path] == 1)
                let key = stableHash(path)
                switch entry.kind {
                case .movie:
                    var movie = MediaItem(id: "\(prefix):movie:\(key)", sourceID: sourceID, kind: .movie,
                                          name: entry.year.map { "\(entry.title) (\($0))" } ?? entry.title,
                                          group: "\(labels.movies) · \(rootName)", streamURL: url, added: modified)
                    movie.year = entry.year
                    items.append(movie)
                case .episode:
                    let name = entry.series ?? "Série"
                    let seriesKey = name.lowercased()
                    let seriesID = seriesIDs[seriesKey] ?? "\(prefix):series:\(stableHash(seriesKey))"
                    seriesIDs[seriesKey] = seriesID
                    if seriesNames[seriesKey] == nil { seriesNames[seriesKey] = name }
                    if seriesRoots[seriesKey] == nil { seriesRoots[seriesKey] = rootName }
                    var item = MediaItem(id: "\(prefix):episode:\(key)", sourceID: sourceID, kind: .episode, name: entry.title,
                                         group: seriesNames[seriesKey] ?? name, streamURL: url, seriesID: seriesID,
                                         number: entry.episode, added: modified)
                    item.season = entry.season
                    items.append(item)
                case .video:
                    // Vidéos personnelles : rubrique à part, rangée par dossier.
                    let parts = relative.split(separator: "/")
                    let folder = parts.count > 1 ? String(parts[parts.count - 2]) : rootName
                    items.append(MediaItem(id: "\(prefix):movie:\(key)", sourceID: sourceID, kind: .movie, name: entry.title,
                                           group: "\(labels.videos) · \(folder)", streamURL: url, added: modified))
                }
            }
        }
        // Une fiche « série » par série trouvée (date : épisode le plus récent).
        var latest: [String: Date] = [:]
        for item in items where item.kind == .episode {
            guard let sid = item.seriesID, let date = item.added else { continue }
            if latest[sid].map({ date > $0 }) ?? true { latest[sid] = date }
        }
        for (key, id) in seriesIDs.sorted(by: { $0.key < $1.key }) {
            items.append(MediaItem(id: id, sourceID: sourceID, kind: .series, name: seriesNames[key] ?? key,
                                   group: "\(labels.series) · \(seriesRoots[key] ?? "")", seriesID: id, added: latest[id]))
        }
        return SourceContent(items: items, epgURL: nil)
    }

    /// Sous-titres placés à côté d'une vidéo (« Film.srt », « Film.fr.srt »).
    public static func sidecarSubtitles(for video: URL) -> [URL] {
        let base = LocalNameParser.baseName(video.lastPathComponent).lowercased()
        let dir = video.deletingLastPathComponent()
        guard let entries = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return [] }
        return entries.filter {
            LocalNameParser.subtitleExtensions.contains($0.pathExtension.lowercased())
                && LocalNameParser.baseName($0.lastPathComponent).lowercased().hasPrefix(base)
        }
    }
}
