import XCTest
@testable import KastideoCore

final class ReplayTests: XCTestCase {
    private func date(_ s: String) -> Date {
        let f = ISO8601DateFormatter()
        return f.date(from: s)!
    }

    func testReplayURLWithOffset() {
        let live = URL(string: "https://fr.example.com:8080/live/jean/s3cret/4242.ts")!
        // 20:00 UTC, serveur à UTC+1 → 21:00, marge avant d'une minute → 20:59.
        let url = ReplayURL.make(live: live, start: date("2026-10-27T20:00:00Z"), end: date("2026-10-27T21:00:00Z"),
                                 clock: ServerClock(offset: 3600), fallbackZone: TimeZone(secondsFromGMT: 0)!)
        XCTAssertEqual(url?.absoluteString, "https://fr.example.com:8080/timeshift/jean/s3cret/66/2026-10-27:20-59/4242.ts".replacingOccurrences(of: "20-59", with: "20-59"))
    }

    func testReplayURLTimezoneAndManualShift() {
        let live = URL(string: "http://h.example/live/u/p%20w/7.m3u8")!
        let clock = ServerClock(timezone: "Europe/Paris", offset: nil)
        // Fin octobre 2026 : heure d'hiver (UTC+1) après le 25 octobre, été (UTC+2) avant.
        let winter = ReplayURL.make(live: live, start: date("2026-10-27T20:00:00Z"), end: date("2026-10-27T20:30:00Z"), clock: clock)
        XCTAssertEqual(winter?.absoluteString, "http://h.example/timeshift/u/p%20w/36/2026-10-27:20-59/7.ts")
        let summer = ReplayURL.make(live: live, start: date("2026-10-20T20:00:00Z"), end: date("2026-10-20T20:30:00Z"), clock: clock, extraOffsetMinutes: 10)
        XCTAssertEqual(summer?.absoluteString, "http://h.example/timeshift/u/p%20w/36/2026-10-20:22-09/7.ts")
    }

    func testReplayURLRefusesOtherURLs() {
        let movie = URL(string: "http://h.example/movie/u/p/7.mp4")!
        XCTAssertNil(ReplayURL.make(live: movie, start: Date(), end: Date().addingTimeInterval(60), clock: nil))
    }

    func testServerClockParse() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let info: [String: Any] = ["timezone": "Europe/Paris", "time_now": "2027-01-15 09:00:00", "timestamp_now": 1_800_000_000 - 8 * 3600 + 0]
        // 1 800 000 000 s = 2027-01-15 08:00:00 UTC ; « time_now » 09:00 → UTC+1.
        let clock = ServerClock.parse(["timezone": "Europe/Paris", "time_now": "2027-01-15 09:00:00", "timestamp_now": "1800000000"], now: now)
        XCTAssertEqual(clock?.offset, 3600)
        XCTAssertEqual(clock?.timezone, "Europe/Paris")
        _ = info
        XCTAssertNil(ServerClock.parse(["timezone": "Nulle/Part"], now: now))
    }

    func testArchiveDaysParsing() throws {
        let json = #"[{"stream_id":1,"name":"A","tv_archive":1,"tv_archive_duration":"14","category_id":"1"},{"stream_id":2,"name":"B","tv_archive":0}]"#
        let c = XtreamCredentials(server: URL(string: "http://h")!, username: "u", password: "p")
        let items = try XtreamAPI.parseLive(Data(json.utf8), categories: [:], sourceID: UUID(), credentials: c)
        XCTAssertEqual(items[0].archiveDays, 14)
        XCTAssertNil(items[1].archiveDays)
    }
}
