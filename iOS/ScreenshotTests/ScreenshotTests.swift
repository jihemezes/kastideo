import XCTest

/// Captures d'écran pour App Store Connect / TestFlight (lancé par .github/workflows/ios-screenshots.yml).
/// L'app démarre en mode démonstration avec une playlist M3U publique ; aucune donnée personnelle n'est utilisée.
final class ScreenshotTests: XCTestCase {
    private var app: XCUIApplication!
    private var outDir = ""

    override func setUpWithError() throws {
        continueAfterFailure = true
        let env = ProcessInfo.processInfo.environment
        outDir = env["SHOTS_DIR"] ?? NSTemporaryDirectory()
        try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
        app = XCUIApplication()
        app.launchArguments += ["-kastideo-demo-m3u", env["DEMO_M3U"] ?? "",
                                "-AppleLanguages", "(\(env["SHOTS_LANG"] ?? "fr"))",
                                "-AppleLocale", env["SHOTS_LOCALE"] ?? "fr_FR"]
        app.launch()
    }

    private func shot(_ name: String) {
        Thread.sleep(forTimeInterval: 1.5)
        let data = app.screenshot().pngRepresentation
        try? data.write(to: URL(fileURLWithPath: outDir).appendingPathComponent("\(name).png"))
    }

    /// Touche le premier bouton dont le libellé contient l'un des textes (français ou anglais).
    @discardableResult
    private func tap(_ labels: String...) -> Bool {
        for label in labels {
            let match = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", label)).firstMatch
            if match.waitForExistence(timeout: 4), match.isHittable {
                match.tap()
                return true
            }
        }
        return false
    }

    func testCaptures() {
        Thread.sleep(forTimeInterval: 12) // chargement de la playlist
        shot("01-accueil")
        if tap("Direct", "Live") { shot("02-direct") }
        tap("Accueil", "Home")
        if tap("Films", "Movies") { shot("03-films") }
        tap("Accueil", "Home")
        if tap("Guide TV", "TV Guide") { shot("04-guide") }
        tap("Accueil", "Home")
        if tap("Application") { shot("05-reglages") }
        if tap("Aide", "Help") { shot("06-aide") }
    }
}
