import XCTest
@testable import KastideoCore

final class M3UParserTests: XCTestCase {
    let source = UUID()

    func testExtendedPlaylist() {
        let text = """
        #EXTM3U url-tvg="http://epg.example.com/guide.xml.gz,http://other/guide.xml"
        #EXTINF:-1 tvg-id="tf1.fr" tvg-name="TF1 HD" tvg-logo="http://logo/tf1.png" group-title="France | Généralistes" tvg-chno="1",TF1 HD
        #EXTVLCOPT:http-user-agent=VLC
        http://server.example.com:8080/live/user/pass/101.ts
        #EXTINF:-1 tvg-id="" group-title="Films, Action",Film, avec virgule
        http://server.example.com:8080/movie/user/pass/555.mkv
        #EXTINF:-1,Série S01E01
        #EXTGRP:Ma série
        http://server.example.com:8080/series/user/pass/777.mp4
        http://bare.example.com/stream.m3u8
        """
        let result = M3UParser.parse(text, sourceID: source)
        XCTAssertEqual(result.epgURL?.absoluteString, "http://epg.example.com/guide.xml.gz")
        XCTAssertEqual(result.items.count, 4)

        let tf1 = result.items[0]
        XCTAssertEqual(tf1.name, "TF1 HD")
        XCTAssertEqual(tf1.group, "France | Généralistes")
        XCTAssertEqual(tf1.epgID, "tf1.fr")
        XCTAssertEqual(tf1.number, 1)
        XCTAssertEqual(tf1.logoURL?.absoluteString, "http://logo/tf1.png")
        XCTAssertEqual(tf1.kind, .live)

        let movie = result.items[1]
        XCTAssertEqual(movie.name, "Film, avec virgule")
        XCTAssertEqual(movie.group, "Films, Action")
        XCTAssertNil(movie.epgID)
        XCTAssertEqual(movie.kind, .movie)

        let episode = result.items[2]
        XCTAssertEqual(episode.kind, .series)
        XCTAssertEqual(episode.group, "Ma série")
        XCTAssertFalse(episode.needsEpisodes)

        let bare = result.items[3]
        XCTAssertEqual(bare.name, "stream")
        XCTAssertEqual(bare.group, M3UParser.defaultGroup)
    }

    func testCRLFAndDuplicates() {
        let text = "#EXTM3U\r\n#EXTINF:-1,A\r\nhttp://x/1.m3u8\r\n#EXTINF:-1,B\r\nhttp://x/1.m3u8\r\n"
        let items = M3UParser.parse(text, sourceID: source).items
        XCTAssertEqual(items.map(\.name), ["A", "B"])
        XCTAssertNotEqual(items[0].id, items[1].id)
    }

    func testStableIDs() {
        let text = "#EXTM3U\n#EXTINF:-1,A\nhttp://x/1.m3u8\n"
        XCTAssertEqual(M3UParser.parse(text, sourceID: source).items.first?.id,
                       M3UParser.parse(text, sourceID: source).items.first?.id)
    }

    func testSearchKey() {
        XCTAssertEqual("  Télé ÉTÉ ".kastideoSearchKey, "tele ete")
    }
}

final class XtreamTests: XCTestCase {
    let source = UUID()
    let creds = XtreamCredentials(server: URL(string: "http://srv.example.com:8080")!, username: "jm", password: "p@ss")

    func testNormalizeServer() {
        XCTAssertEqual(XtreamCredentials.normalizeServer("srv.example.com:8080/")?.absoluteString, "http://srv.example.com:8080")
        XCTAssertEqual(XtreamCredentials.normalizeServer("https://srv.example.com/player_api.php?username=a")?.absoluteString, "https://srv.example.com")
        XCTAssertNil(XtreamCredentials.normalizeServer("   "))
    }

    func testPlaylistURLDetection() {
        let url = URL(string: "http://gold.example.com:8080/get.php?username=jm&password=s3cr3t&type=m3u_plus&output=ts")!
        let c = XtreamCredentials.fromPlaylistURL(url)
        XCTAssertEqual(c?.server.absoluteString, "http://gold.example.com:8080")
        XCTAssertEqual(c?.username, "jm")
        XCTAssertEqual(c?.password, "s3cr3t")
        XCTAssertNil(XtreamCredentials.fromPlaylistURL(URL(string: "http://example.com/list.m3u")!))
        XCTAssertNil(XtreamCredentials.fromPlaylistURL(URL(string: "http://example.com/get.php?username=jm")!))
        XCTAssertEqual(HTTP.userAgent, "VLC/3.0.20 LibVLC/3.0.20")
    }

    func testURLs() {
        let api = XtreamAPI.apiURL(creds, action: "get_live_streams").absoluteString
        XCTAssertTrue(api.hasPrefix("http://srv.example.com:8080/player_api.php?username=jm&password=p@ss&action=get_live_streams"), api)
        XCTAssertEqual(XtreamAPI.liveURL(creds, streamID: "12").absoluteString, "http://srv.example.com:8080/live/jm/p@ss/12.ts")
        XCTAssertEqual(XtreamAPI.movieURL(creds, streamID: "5", ext: "mkv").absoluteString, "http://srv.example.com:8080/movie/jm/p@ss/5.mkv")
    }

    func testAccount() throws {
        let ok = #"{"user_info":{"auth":1,"status":"Active","exp_date":"1893456000","max_connections":"2"},"server_info":{}}"#
        let account = try XtreamAPI.parseAccount(Data(ok.utf8))
        XCTAssertEqual(account.maxConnections, 2)
        XCTAssertNotNil(account.expiration)

        let refused = #"{"user_info":{"auth":0}}"#
        XCTAssertThrowsError(try XtreamAPI.parseAccount(Data(refused.utf8))) { error in
            XCTAssertEqual(error as? XtreamError, .invalidCredentials)
        }
        let expired = #"{"user_info":{"auth":1,"status":"Expired"}}"#
        XCTAssertThrowsError(try XtreamAPI.parseAccount(Data(expired.utf8)))
    }

    func testLiveMixedTypes() throws {
        let cats = try XtreamAPI.parseCategories(Data(#"[{"category_id":"3","category_name":"Sport"},{"category_id":4,"category_name":"Info"}]"#.utf8))
        XCTAssertEqual(cats["3"], "Sport")
        XCTAssertEqual(cats["4"], "Info")

        let live = #"[{"num":1,"name":"beIN 1","stream_id":101,"stream_icon":"http://l/b.png","epg_channel_id":"bein1.fr","category_id":"3"},{"num":"2","name":"FranceInfo","stream_id":"102","stream_icon":"","epg_channel_id":null,"category_id":4},{"name":"cassé"}]"#
        let items = try XtreamAPI.parseLive(Data(live.utf8), categories: cats, sourceID: source, credentials: creds)
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].group, "Sport")
        XCTAssertEqual(items[0].epgID, "bein1.fr")
        XCTAssertEqual(items[0].streamURL?.lastPathComponent, "101.ts")
        XCTAssertEqual(items[1].group, "Info")
        XCTAssertNil(items[1].logoURL)
        XCTAssertNil(items[1].epgID)
        XCTAssertEqual(items[1].number, 2)
    }

    func testSeriesInfo() throws {
        let series = MediaItem(id: "s", sourceID: source, kind: .series, name: "Ma série", group: "G", seriesID: "9")
        XCTAssertTrue(series.needsEpisodes)
        let json = #"{"episodes":{"2":[{"id":"21","episode_num":2,"title":"B","container_extension":"mkv","info":{"plot":"p"}},{"id":"20","episode_num":1,"title":"A","container_extension":"mkv"}],"1":[{"id":"10","episode_num":"1","title":"","container_extension":"mp4"}]}}"#
        let seasons = try XtreamAPI.parseSeriesInfo(Data(json.utf8), seriesName: series.name, sourceID: source, credentials: creds)
        XCTAssertEqual(seasons.map(\.number), [1, 2])
        XCTAssertEqual(seasons[1].episodes.map(\.name), ["A", "B"])
        XCTAssertEqual(seasons[0].episodes[0].name, "Épisode 1")
        XCTAssertEqual(seasons[1].episodes[1].streamURL?.absoluteString, "http://srv.example.com:8080/series/jm/p@ss/21.mkv")
    }
}

final class EPGTests: XCTestCase {
    func testDateParsing() {
        let d = XMLTVDate.parse("20261018203000 +0200")!
        XCTAssertEqual(d.timeIntervalSince1970, XMLTVDate.parse("20261018183000 +0000")!.timeIntervalSince1970)
        XCTAssertNotNil(XMLTVDate.parse("202610181830"))
        XCTAssertNil(XMLTVDate.parse("bad"))
    }

    func testXMLTVParsingAndIndex() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <tv>
          <channel id="tf1.fr"><display-name>TF1</display-name></channel>
          <programme start="20261018180000 +0000" stop="20261018190000 +0000" channel="TF1.fr">
            <title lang="fr">Journal &amp; météo</title><title lang="en">News</title>
            <desc lang="fr">Infos</desc>
          </programme>
          <programme start="20261018190000 +0000" stop="20261018200000 +0000" channel="tf1.fr"><title>Film</title></programme>
          <programme start="20200101000000 +0000" stop="20200101010000 +0000" channel="tf1.fr"><title>Vieux</title></programme>
        </tv>
        """
        let now = XMLTVDate.parse("20261018183000 +0000")!
        let programmes = XMLTVParser.parse(data: Data(xml.utf8), window: XMLTVParser.defaultWindow(now: now))
        XCTAssertEqual(programmes.count, 2)
        XCTAssertEqual(programmes[0].title, "Journal & météo")
        XCTAssertEqual(programmes[0].desc, "Infos")

        let index = EPGIndex(programmes: programmes)
        XCTAssertEqual(index.current(for: "tf1.fr", at: now)?.title, "Journal & météo")
        XCTAssertEqual(index.upcoming(for: "TF1.FR", after: now).map(\.title), ["Film"])
        XCTAssertEqual(index.current(for: "tf1.fr", at: now)!.progress(at: now), 0.5, accuracy: 0.001)
        XCTAssertNil(index.current(for: nil))
    }
}
