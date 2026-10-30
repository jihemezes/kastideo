import XCTest
@testable import KastideoCore

final class CastTests: XCTestCase {
    func testSearchRequest() {
        let request = CastDIAL.searchRequest
        XCTAssertTrue(request.hasPrefix("M-SEARCH * HTTP/1.1\r\n"))
        XCTAssertTrue(request.contains("ST: urn:dial-multiscreen-org:service:dial:1"))
        XCTAssertTrue(request.hasSuffix("\r\n\r\n"))
    }

    func testHeaders() {
        let response = "HTTP/1.1 200 OK\r\nCACHE-CONTROL: max-age=1800\r\nLocation: http://192.168.1.40:8008/ssdp/device-desc.xml\r\nST: urn:dial-multiscreen-org:service:dial:1\r\n\r\n"
        XCTAssertEqual(CastDIAL.header("LOCATION", in: response), "http://192.168.1.40:8008/ssdp/device-desc.xml")
        XCTAssertEqual(CastDIAL.header("st", in: response), "urn:dial-multiscreen-org:service:dial:1")
        XCTAssertNil(CastDIAL.header("X-Absent", in: response))
    }

    func testFriendlyName() {
        XCTAssertEqual(CastDIAL.friendlyName(inXML: "<root><device><friendlyName>Salon &amp; TV</friendlyName></device></root>"), "Salon & TV")
        XCTAssertNil(CastDIAL.friendlyName(inXML: "<root/>"))
    }

    func testApplicationURLAndBody() throws {
        let url = try XCTUnwrap(CastDIAL.applicationURL(from: "http://192.168.1.40:8008/apps"))
        XCTAssertEqual(url.absoluteString, "http://192.168.1.40:8008/apps/")
        XCTAssertNil(CastDIAL.applicationURL(from: "ftp://x/"))
        let device = DIALDevice(name: "Salon", host: "192.168.1.40", applicationURL: url)
        XCTAssertEqual(CastDIAL.youTubeLaunchURL(device).absoluteString, "http://192.168.1.40:8008/apps/YouTube")
        XCTAssertEqual(CastDIAL.youTubeBody(videoID: "dQw4w9WgXcQ"), "v=dQw4w9WgXcQ&t=0")
        XCTAssertEqual(CastDIAL.youTubeBody(videoID: "abc", startSeconds: 90), "v=abc&t=90")
        XCTAssertEqual(CastDIAL.youTubeBody(videoID: "abc", startSeconds: -5), "v=abc&t=0")
    }
}
