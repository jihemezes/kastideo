import XCTest
@testable import KastideoCore

final class DecoderFallbackTests: XCTestCase {
    func testFrozenAfterThreeIdenticalSamples() {
        var detector = FreezeDetector(limit: 3)
        XCTAssertFalse(detector.update(displayedPictures: 100, playing: true, dataArriving: true))
        XCTAssertFalse(detector.update(displayedPictures: 100, playing: true, dataArriving: true))
        XCTAssertFalse(detector.update(displayedPictures: 100, playing: true, dataArriving: true))
        XCTAssertTrue(detector.update(displayedPictures: 100, playing: true, dataArriving: true))
    }

    func testProgressResetsTheCount() {
        var detector = FreezeDetector(limit: 2)
        _ = detector.update(displayedPictures: 10, playing: true, dataArriving: true)
        _ = detector.update(displayedPictures: 10, playing: true, dataArriving: true)
        XCTAssertFalse(detector.update(displayedPictures: 60, playing: true, dataArriving: true))
        XCTAssertFalse(detector.update(displayedPictures: 60, playing: true, dataArriving: true))
        XCTAssertTrue(detector.update(displayedPictures: 60, playing: true, dataArriving: true))
    }

    func testPauseAndMissingDataAreNotFreezes() {
        var detector = FreezeDetector(limit: 2)
        for _ in 0..<6 {
            XCTAssertFalse(detector.update(displayedPictures: 5, playing: false, dataArriving: true))
        }
        for _ in 0..<6 {
            XCTAssertFalse(detector.update(displayedPictures: 5, playing: true, dataArriving: false))
        }
    }

    func testResetForgetsHistory() {
        var detector = FreezeDetector(limit: 1)
        _ = detector.update(displayedPictures: 1, playing: true, dataArriving: true)
        detector.reset()
        XCTAssertFalse(detector.update(displayedPictures: 1, playing: true, dataArriving: true))
        XCTAssertTrue(detector.update(displayedPictures: 1, playing: true, dataArriving: true))
    }
}
