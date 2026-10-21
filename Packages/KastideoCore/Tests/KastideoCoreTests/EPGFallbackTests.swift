import XCTest
@testable import KastideoCore

final class EPGFallbackTests: XCTestCase {
    func testNormalize() {
        XCTAssertEqual(ChannelMatcher.normalize("|FR| TF1 FHD"), "tf1")
        XCTAssertEqual(ChannelMatcher.normalize("|FR| FRANCE 2 UHD"), "france2")
        XCTAssertEqual(ChannelMatcher.normalize("France 2"), "france2")
        XCTAssertEqual(ChannelMatcher.normalize("FR: M6 HD"), "m6")
        XCTAssertEqual(ChannelMatcher.normalize("13ème rue"), "13emerue")
        XCTAssertEqual(ChannelMatcher.normalize("|FR| 13EME RUE FHD"), "13emerue")
        XCTAssertEqual(ChannelMatcher.normalize("|FR| CANAL+ FHD"), "canalplus")
        XCTAssertEqual(ChannelMatcher.normalize("Canal+"), "canalplus")
    }

    func testGuideAndMatch() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <tv>
          <channel id="TF1.fr"><display-name>TF1</display-name></channel>
          <channel id="France2.fr"><display-name>France 2</display-name></channel>
          <programme start="20261021080000 +0200" stop="20261021090000 +0200" channel="TF1.fr"><title>Téléshopping</title></programme>
        </tv>
        """
        let now = XMLTVDate.parse("20261021083000 +0200")!
        let guide = XMLTVParser.parseGuide(data: Data(xml.utf8), window: XMLTVParser.defaultWindow(now: now))
        XCTAssertTrue(guide.isValid)
        XCTAssertEqual(guide.programmes.count, 1)
        XCTAssertEqual(guide.channels.count, 2)
        let matcher = ChannelMatcher(channels: guide.channels)
        XCTAssertEqual(matcher.match(name: "|FR| TF1 FHD", epgID: nil), "TF1.fr")
        XCTAssertEqual(matcher.match(name: "whatever", epgID: "france2.fr"), "France2.fr")
        XCTAssertEqual(matcher.match(name: "|FR| FRANCE 2 HD", epgID: "f2.fr"), "France2.fr")
        XCTAssertNil(matcher.match(name: "Inconnue", epgID: nil))
    }

    func testInvalidGuide() {
        XCTAssertFalse(XMLTVParser.parseGuide(data: Data("<html>error</html>".utf8)).isValid)
        XCTAssertFalse(XMLTVParser.parseGuide(data: Data()).isValid)
    }
}
