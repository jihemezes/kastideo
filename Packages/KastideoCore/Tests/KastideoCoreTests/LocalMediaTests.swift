import XCTest
@testable import KastideoCore

final class LocalMediaTests: XCTestCase {
    func testNames() {
        var e = LocalNameParser.parse("Inception (2010).mkv")
        XCTAssertEqual(e.kind, .movie); XCTAssertEqual(e.title, "Inception"); XCTAssertEqual(e.year, 2010)
        e = LocalNameParser.parse("Films/The.Matrix.1999.1080p.BluRay.x264.mkv")
        XCTAssertEqual(e.kind, .movie); XCTAssertEqual(e.title, "The Matrix"); XCTAssertEqual(e.year, 1999)
        e = LocalNameParser.parse("Le Fabuleux Destin (2001)/film.mkv")
        XCTAssertEqual(e.kind, .movie); XCTAssertEqual(e.title, "Le Fabuleux Destin"); XCTAssertEqual(e.year, 2001)
        e = LocalNameParser.parse("Séries/Breaking Bad/Saison 1/Breaking.Bad.S01E02.Cat.in.the.Bag.720p.mkv")
        XCTAssertEqual(e.kind, .episode); XCTAssertEqual(e.series, "Breaking Bad"); XCTAssertEqual(e.season, 1)
        XCTAssertEqual(e.episode, 2); XCTAssertEqual(e.title, "Cat in the Bag")
        e = LocalNameParser.parse("Dark/Season 2/S02E05.mkv")
        XCTAssertEqual(e.series, "Dark"); XCTAssertEqual(e.season, 2); XCTAssertEqual(e.episode, 5)
        e = LocalNameParser.parse("Kaamelott/Saison 3/12 - Le Tourment.avi")
        XCTAssertEqual(e.kind, .episode); XCTAssertEqual(e.series, "Kaamelott"); XCTAssertEqual(e.season, 3)
        XCTAssertEqual(e.episode, 12); XCTAssertEqual(e.title, "Le Tourment")
        e = LocalNameParser.parse("Friends 1x05.mp4")
        XCTAssertEqual(e.series, "Friends"); XCTAssertEqual(e.season, 1); XCTAssertEqual(e.episode, 5)
        e = LocalNameParser.parse("Vacances/plage avec les enfants.mp4")
        XCTAssertEqual(e.kind, .video); XCTAssertEqual(e.title, "plage avec les enfants")
        e = LocalNameParser.parse("Dune.Part.Two.MULTi.2160p.WEB.mkv")
        XCTAssertEqual(e.kind, .movie); XCTAssertEqual(e.title, "Dune Part Two")
        e = LocalNameParser.parse("Vacances 2024/plage.mp4", aloneInFolder: false)
        XCTAssertEqual(e.kind, .video); XCTAssertEqual(e.title, "plage")
        e = LocalNameParser.parse("Heat (1995)/heat.mkv")
        XCTAssertEqual(e.kind, .movie); XCTAssertEqual(e.title, "Heat"); XCTAssertEqual(e.year, 1995)
        // Même empreinte que sur Windows / Linux : les identifiants (favoris, reprise) se correspondent.
        XCTAssertEqual(stableHash("abc"), "1a47e90b")
    }

    func testScan() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("kastideo-scan-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        for path in ["Films/Dune (2021).mkv", "Films/Dune (2021).fr.srt", "Séries/The Bear/Saison 1/The.Bear.S01E01.mkv",
                     "Séries/The Bear/Saison 1/The.Bear.S01E02.mkv", "Vacances 2024/plage.mp4", "Vacances 2024/GOPR0042.MP4",
                     "System Volume Information/x.mkv", ".cache/y.mkv"] {
            let url = root.appendingPathComponent(path)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data("x".utf8).write(to: url)
        }
        let source = UUID()
        let content = FolderScanner.scan(roots: [root], sourceID: source)
        let movies = content.items.filter { $0.kind == .movie }
        XCTAssertEqual(movies.filter { $0.group.hasPrefix("Films · ") }.map(\.name), ["Dune (2021)"])
        XCTAssertEqual(movies.filter { $0.group == "Vidéos · Vacances 2024" }.count, 2)
        let episodes = content.items.filter { $0.kind == .episode }
        XCTAssertEqual(episodes.count, 2)
        XCTAssertEqual(Set(episodes.compactMap(\.season)), [1])
        let series = content.items.filter { $0.kind == .series }
        XCTAssertEqual(series.map(\.name), ["The Bear"])
        XCTAssertEqual(series.first?.seriesID, episodes.first?.seriesID)
        let dune = try XCTUnwrap(movies.first { $0.name.hasPrefix("Dune") }?.streamURL)
        XCTAssertEqual(FolderScanner.sidecarSubtitles(for: dune).map(\.lastPathComponent), ["Dune (2021).fr.srt"])
    }

    func testDiscoveryReplies() {
        let jf = ServerDiscovery.parseReply(#"{"Address":"http://192.168.1.10:8096","Id":"x","Name":"Salon"}"#, from: "192.168.1.10")
        XCTAssertEqual(jf, DiscoveredServer(type: .jellyfin, name: "Salon", address: "http://192.168.1.10:8096"))
        let emby = ServerDiscovery.parseReply(#"{"Address":"http://10.0.0.2:8096","Name":"Emby"}"#, from: "10.0.0.2", hint: .emby)
        XCTAssertEqual(emby?.type, .emby)
        let plex = ServerDiscovery.parseReply("HTTP/1.0 200 OK\r\nContent-Type: plex/media-server\r\nName: Bureau\r\nPort: 32400\r\n",
                                              from: "192.168.1.20")
        XCTAssertEqual(plex, DiscoveredServer(type: .plex, name: "Bureau", address: "http://192.168.1.20:32400"))
        XCTAssertNil(ServerDiscovery.parseReply("bonjour", from: "1.2.3.4"))
    }

    func testAddresses() throws {
        XCTAssertEqual(try MediaServerHTTP.normalize("192.168.1.10", type: .plex).absoluteString, "http://192.168.1.10:32400")
        XCTAssertEqual(try MediaServerHTTP.normalize("nas.local/", type: .jellyfin).absoluteString, "http://nas.local:8096")
        XCTAssertEqual(try MediaServerHTTP.normalize("https://jf.example.com", type: .jellyfin).absoluteString, "https://jf.example.com")
        XCTAssertThrowsError(try MediaServerHTTP.normalize("  ", type: .emby))
        let session = ServerSession(token: "t", userID: "u")
        XCTAssertEqual(ServerSession.decode(session.encoded()), session)
    }

    /// Contre les serveurs simulés de l'environnement de test (KASTIDEO_MOCK=1).
    func testMockServers() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["KASTIDEO_MOCK"] == "1")
        let server = try MediaServerHTTP.normalize("127.0.0.1:8796", type: .jellyfin)
        let info = try await JellyfinClient.publicInfo(server: server)
        XCTAssertTrue(info?.contains("Salon") ?? false)
        do {
            _ = try await JellyfinClient.signIn(server: server, username: "jm", password: "bad")
            XCTFail("mot de passe refusé attendu")
        } catch {}
        let session = try await JellyfinClient.signIn(server: server, username: "jm", password: "secret")
        let jf = JellyfinClient(server: server, sourceID: UUID(), session: session, label: "Salon")
        let library = try await jf.fetchLibrary()
        XCTAssertEqual(library.items.filter { $0.kind == .movie }.count, 4)
        let dune = try XCTUnwrap(library.items.first { $0.name == "Dune (2021)" })
        XCTAssertEqual(dune.group, "Films · Salon")
        try await jf.setPlayed(dune, played: false)
        try await jf.report(dune, position: 600, duration: 1800, event: .progress)
        let v1 = try await jf.fetchLibrary().progress?[dune.id]?.position
        XCTAssertEqual(v1, 600)
        try await jf.setPlayed(dune, played: true)
        let v2 = try await jf.fetchLibrary().progress?[dune.id]?.isPlayed
        XCTAssertEqual(v2, true)
        try await jf.setPlayed(dune, played: false)
        let show = try XCTUnwrap(library.items.first { $0.kind == .series })
        let v3 = try await jf.episodes(of: show).seasons.map(\.number)
        XCTAssertEqual(v3, [1, 2])
        let v4 = try await jf.details(of: dune)?.directors
        XCTAssertEqual(v4, ["Denis Villeneuve"])

        let plex = PlexClient(server: URL(string: "http://127.0.0.1:8797")!, sourceID: UUID(), token: "ptok")
        let v5 = try await plex.identity()
        XCTAssertEqual(v5, "Bureau")
        let plexLibrary = try await plex.fetchLibrary()
        let movie = try XCTUnwrap(plexLibrary.items.first { $0.kind == .movie })
        XCTAssertTrue(movie.streamURL?.absoluteString.contains("/library/parts/") ?? false)
        try await plex.setPlayed(movie, played: false)
        try await plex.report(movie, position: 120, duration: 1800, event: .pause)
        let v6 = try await plex.fetchLibrary().progress?[movie.id]?.position
        XCTAssertEqual(v6, 120)
        let lupin = try XCTUnwrap(plexLibrary.items.first { $0.kind == .series })
        let v7 = try await plex.episodes(of: lupin).seasons.first?.episodes.count
        XCTAssertEqual(v7, 3)
        let v8 = try await plex.details(of: movie)?.tmdbID
        XCTAssertEqual(v8, "438631")

        let found = await ServerDiscovery.scan(wait: 2)
        XCTAssertTrue(found.contains { $0.type == .jellyfin })
        XCTAssertTrue(found.contains { $0.type == .plex })
    }
}
