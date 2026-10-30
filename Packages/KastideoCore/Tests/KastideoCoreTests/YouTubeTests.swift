import XCTest
@testable import KastideoCore

final class YouTubeTests: XCTestCase {
    func testParseSource() {
        XCTAssertEqual(YouTube.parseSource("dQw4w9WgXcQ"), .video("dQw4w9WgXcQ"))
        XCTAssertEqual(YouTube.parseSource("https://www.youtube.com/watch?v=dQw4w9WgXcQ"), .video("dQw4w9WgXcQ"))
        XCTAssertEqual(YouTube.parseSource("youtu.be/dQw4w9WgXcQ?t=3"), .video("dQw4w9WgXcQ"))
        XCTAssertEqual(YouTube.parseSource("https://youtube.com/shorts/dQw4w9WgXcQ"), .video("dQw4w9WgXcQ"))
        XCTAssertEqual(YouTube.parseSource("https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ"), .video("dQw4w9WgXcQ"))
        XCTAssertEqual(YouTube.parseSource("https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=PLabcdefghijkl"), .playlist("PLabcdefghijkl"))
        XCTAssertEqual(YouTube.parseSource("https://www.youtube.com/channel/UCabcdefghijklmnopqrstuv"), .channel("UCabcdefghijklmnopqrstuv"))
        XCTAssertEqual(YouTube.parseSource("https://www.youtube.com/@Squeezie/videos"), .handle("@Squeezie"))
        XCTAssertEqual(YouTube.parseSource("@Squeezie"), .handle("@Squeezie"))
        XCTAssertEqual(YouTube.parseSource("https://www.youtube.com/c/Foo"), .handle("@Foo"))
        XCTAssertNil(YouTube.parseSource("https://example.com/watch?v=dQw4w9WgXcQ"))
        XCTAssertNil(YouTube.parseSource("bonjour"))
        XCTAssertNil(YouTube.parseSource(""))
    }

    func testParseFeed() {
        let xml = """
        <feed><title>Ma chaîne &amp; moi</title>
        <entry><yt:videoId>dQw4w9WgXcQ</yt:videoId><title>Titre &quot;un&quot;</title><author><name>Auteur</name></author>
        <published>2026-10-01T10:00:00+00:00</published></entry>
        <entry><yt:videoId>court</yt:videoId><title>Ignorée</title></entry>
        <entry><yt:videoId>abcdefghijk</yt:videoId><title>Deux</title><author><name>Auteur</name></author></entry></feed>
        """
        let feed = YouTube.parseFeed(xml)
        XCTAssertEqual(feed.title, "Ma chaîne & moi")
        XCTAssertEqual(feed.videos.map(\.id), ["dQw4w9WgXcQ", "abcdefghijk"])
        XCTAssertEqual(feed.videos[0].title, "Titre \"un\"")
        XCTAssertEqual(feed.videos[0].channel, "Auteur")
        XCTAssertEqual(feed.videos[0].published, "2026-10-01T10:00:00+00:00")
    }

    func testChannelIDFromPage() {
        XCTAssertEqual(YouTube.channelID(fromPage: "...\"channelId\":\"UCabcdefghijklmnopqrstuv\",..."), "UCabcdefghijklmnopqrstuv")
        XCTAssertNil(YouTube.channelID(fromPage: "rien"))
    }

    func testSearch() throws {
        let json = """
        {"nextPageToken":"N","items":[{"id":{"videoId":"dQw4w9WgXcQ"},"snippet":{"title":"L&#39;été","channelTitle":"A &amp; B","publishedAt":"2026-01-01T00:00:00Z"}},
        {"id":{"channelId":"x"},"snippet":{"title":"autre"}}]}
        """
        let page = try YouTube.parseSearch(Data(json.utf8))
        XCTAssertEqual(page.videos.count, 1)
        XCTAssertEqual(page.videos[0].title, "L'été")
        XCTAssertEqual(page.videos[0].channel, "A & B")
        XCTAssertEqual(page.next, "N")
        XCTAssertNil(page.previous)
        XCTAssertThrowsError(try YouTube.parseSearch(Data("{\"error\":{\"code\":403,\"message\":\"quota\"}}".utf8)))
        let url = YouTube.searchURL(query: "chat & chien", apiKey: "K", order: .date, pageToken: "T")
        XCTAssertTrue(url.absoluteString.contains("videoEmbeddable=true"))
        XCTAssertTrue(url.absoluteString.contains("order=date"))
        XCTAssertTrue(url.absoluteString.contains("pageToken=T"))
    }

    func testPlayerHTML() {
        let labels = YouTube.PlayerLabels(previous: "Précédente", next: "Suivante", chain: "Enchaîner", loop: "Boucle", mute: "Muet",
                                          openOnYouTube: "Ouvrir sur YouTube", unavailable: "Indisponible")
        let q = [YouTubeVideo(id: "dQw4w9WgXcQ", title: "</script><b>x", channel: "C")]
        let html = YouTube.playerHTML(queue: q, index: 5, labels: labels, eventPath: "/event")
        XCTAssertTrue(html.contains("youtube-nocookie.com"))
        XCTAssertFalse(html.contains("</script><b>"))
        XCTAssertTrue(html.contains("idx=0"))
        XCTAssertTrue(html.contains("var Q=[{"))
        XCTAssertTrue(html.contains("EV=\"/event\""))
    }

    func testSubscriptionsAndResume() {
        let csv = ["Channel ID,Channel URL,Channel title",
                   "UCabcdefghijklmnopqrstuv,http://www.youtube.com/channel/UCabcdefghijklmnopqrstuv,\"Chaîne, avec \"\"virgule\"\"\"",
                   "UCzzzzzzzzzzzzzzzzzzzzzz,http://www.youtube.com/channel/UCzzzzzzzzzzzzzzzzzzzzzz,Deux",
                   "UCabcdefghijklmnopqrstuv,http://www.youtube.com/channel/UCabcdefghijklmnopqrstuv,Doublon"].joined(separator: "\n")
        let channels = YouTube.parseSubscriptions(csv)
        XCTAssertEqual(channels.map(\.id), ["UCabcdefghijklmnopqrstuv", "UCzzzzzzzzzzzzzzzzzzzzzz"])
        XCTAssertEqual(channels[0].title, "Chaîne, avec \"virgule\"")
        let json = "[{\"snippet\":{\"title\":\"Trois\",\"resourceId\":{\"channelId\":\"UCyyyyyyyyyyyyyyyyyyyyyy\"}}}]"
        XCTAssertEqual(YouTube.parseSubscriptions(json).map(\.title), ["Trois"])
        XCTAssertEqual(YouTube.parseSubscriptions("https://www.youtube.com/channel/UCabcdefghijklmnopqrstuv\n@pseudo").count, 1)
        let labels = YouTube.PlayerLabels(previous: "a", next: "b", chain: "c", loop: "d", mute: "e", openOnYouTube: "f", unavailable: "g")
        let q = [YouTubeVideo(id: "dQw4w9WgXcQ", title: "t")]
        let html = YouTube.playerHTML(queue: q, index: 0, resume: ["dQw4w9WgXcQ": 125.7, "bad": 3], labels: labels)
        XCTAssertTrue(html.contains("S={\"dQw4w9WgXcQ\":125}"))
        XCTAssertFalse(html.contains("\"bad\""))
    }
}
