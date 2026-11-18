import XCTest

/// Captures d'écran Apple TV pour App Store Connect (lancé par .github/workflows/tvos-screenshots.yml).
/// L'app démarre en mode démonstration avec une playlist M3U publique ; aucune donnée personnelle n'est utilisée.
/// La navigation se fait à la télécommande (focus) : les captures sont prises à chaque étape, à trier ensuite.
final class TVScreenshotTests: XCTestCase {
    private var app: XCUIApplication!
    private var outDir = ""
    private var counter = 0

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
        counter += 1
        Thread.sleep(forTimeInterval: 2)
        let data = app.screenshot().pngRepresentation
        let file = String(format: "%02d-%@.png", counter, name)
        try? data.write(to: URL(fileURLWithPath: outDir).appendingPathComponent(file))
    }

    private func press(_ button: XCUIRemote.Button, times: Int = 1) {
        for _ in 0..<times {
            XCUIRemote.shared.press(button)
            Thread.sleep(forTimeInterval: 0.6)
        }
    }

    func testCaptures() {
        Thread.sleep(forTimeInterval: 15) // chargement de la playlist
        shot("accueil")
        // Première tuile (Direct) : liste des chaînes.
        press(.select)
        Thread.sleep(forTimeInterval: 3)
        shot("direct")
        press(.menu)
        // Tuile suivante (Films).
        press(.right)
        press(.select)
        Thread.sleep(forTimeInterval: 3)
        shot("films")
        press(.menu)
        // Barre d'onglets : guide TV puis réglages.
        press(.up)
        press(.right, times: 3)
        shot("onglets")
        press(.select)
        Thread.sleep(forTimeInterval: 3)
        shot("onglet-suivant")
        press(.right, times: 3)
        press(.select)
        Thread.sleep(forTimeInterval: 3)
        shot("reglages")
    }
}
