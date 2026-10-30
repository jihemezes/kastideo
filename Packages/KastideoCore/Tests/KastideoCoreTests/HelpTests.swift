import XCTest
@testable import KastideoCore

final class HelpTests: XCTestCase {
    let sample = """
    Texte avant les rubriques (ignoré).

    # Démarrer

    ## Bienvenue {#bienvenue}

    Raccourci <!--mac-->**⌘9**<!--/mac--><!--pc-->**Ctrl+9**<!--/pc--> partout.

    <!--mac-->
    1. Ouvrez les Réglages.
    <!--/mac-->
    <!--pc-->
    1. Ouvrez la roue dentée.
    <!--/pc-->

    ## Réservé Windows {#pc-seul}

    <!--pc-->
    Contenu pour Windows.
    <!--/pc-->

    # Sources

    ## Xtream {#xtream}

    ### Étape
    - Un
      - Sous-point
    > Une note
    > sur deux lignes
    ![Schéma](img:home)
    Voir [la clé](help:youtube-cle).
    """

    func testPlatformFilter() {
        let mac = HelpDocument.parse(sample, platform: .mac)
        XCTAssertEqual(mac.map(\.title), ["Démarrer", "Sources"])
        XCTAssertEqual(mac[0].pages.map(\.id), ["bienvenue"])
        XCTAssertTrue(mac[0].pages[0].body.contains("⌘9"))
        XCTAssertFalse(mac[0].pages[0].body.contains("Ctrl+9"))
        XCTAssertTrue(mac[0].pages[0].body.contains("Réglages"))
        XCTAssertFalse(mac[0].pages[0].body.contains("<!--"))

        let pc = HelpDocument.parse(sample, platform: .pc)
        XCTAssertEqual(pc[0].pages.map(\.id), ["bienvenue", "pc-seul"])
        XCTAssertTrue(pc[0].pages[0].body.contains("Ctrl+9"))
        XCTAssertFalse(pc[0].pages[0].body.contains("⌘"))
    }

    func testBlocks() {
        let page = HelpDocument.parse(sample, platform: .mac)[1].pages[0]
        let blocks = HelpDocument.blocks(page.body)
        XCTAssertEqual(blocks[0], .heading("Étape"))
        XCTAssertEqual(blocks[1], .bullet(level: 0, text: "Un"))
        XCTAssertEqual(blocks[2], .bullet(level: 1, text: "Sous-point"))
        XCTAssertEqual(blocks[3], .note("Une note sur deux lignes"))
        XCTAssertEqual(blocks[4], .image(name: "home", alt: "Schéma"))
        XCTAssertEqual(blocks[5], .paragraph("Voir [la clé](help:youtube-cle)."))
        let numbered = HelpDocument.blocks("1. Un\n2. Deux")
        XCTAssertEqual(numbered, [.numbered(1, "Un"), .numbered(2, "Deux")])
    }

    func testSearch() {
        let groups = HelpDocument.parse(sample, platform: .mac)
        XCTAssertEqual(HelpDocument.search(groups, query: "reglages").map(\.id), ["bienvenue"])
        XCTAssertEqual(HelpDocument.search(groups, query: "ETAPE sous").map(\.id), ["xtream"])
        XCTAssertTrue(HelpDocument.search(groups, query: "a").isEmpty)
        XCTAssertTrue(HelpDocument.search(groups, query: "introuvable").isEmpty)
        XCTAssertTrue(HelpDocument.snippet(groups[0].pages[0], query: "réglages").contains("Réglages"))
    }

    /// L'aide embarquée : toutes les pages se chargent, aucun lien interne n'est cassé, aucun marqueur ne subsiste.
    func testShippedHelp() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("docs/help")
        for lang in ["fr", "en"] {
            let source = try String(contentsOf: root.appendingPathComponent("aide-\(lang).md"), encoding: .utf8)
            for platform in [HelpPlatform.mac, .pc] {
                let groups = HelpDocument.parse(source, platform: platform)
                let ids = Set(groups.flatMap(\.pages).map(\.id))
                XCTAssertGreaterThan(ids.count, 40)
                for page in groups.flatMap(\.pages) {
                    XCTAssertFalse(page.body.contains("<!--"), "\(lang) \(page.id)")
                    for match in page.body.components(separatedBy: "](help:").dropFirst() {
                        let target = String(match.prefix { $0 != ")" })
                        XCTAssertTrue(ids.contains(target), "\(lang) \(platform) \(page.id) → \(target)")
                    }
                }
            }
        }
    }
}
