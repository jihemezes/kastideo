import XCTest
@testable import KastideoCore

final class ThemeTests: XCTestCase {
    func testChannelNames() {
        XCTAssertEqual(ThemeClassifier.theme(forChannelName: "|FR| TF1 FHD"), .general)
        XCTAssertEqual(ThemeClassifier.theme(forChannelName: "|FR| BEIN SPORTS 1 FHD"), .sport)
        XCTAssertEqual(ThemeClassifier.theme(forChannelName: "|FR| BFM TV FHD"), .news)
        XCTAssertEqual(ThemeClassifier.theme(forChannelName: "|FR| DISNEY CHANNEL HD"), .kids)
        XCTAssertEqual(ThemeClassifier.theme(forChannelName: "|FR| NATIONAL GEOGRAPHIC HD"), .documentary)
        XCTAssertEqual(ThemeClassifier.theme(forChannelName: "|FR| CANAL+ SPORT FHD"), .sport)
        XCTAssertEqual(ThemeClassifier.theme(forChannelName: "|FR| CANAL+ FHD"), .general)
        XCTAssertEqual(ThemeClassifier.theme(forChannelName: "|FR| MTV HITS"), .music)
        XCTAssertNil(ThemeClassifier.theme(forChannelName: "|FR| XYZ"))
    }

    func testCategories() {
        XCTAssertEqual(ThemeClassifier.theme(forCategory: "Série d'animation"), .kids)
        XCTAssertEqual(ThemeClassifier.theme(forCategory: "Magazine sportif"), .sport)
        XCTAssertEqual(ThemeClassifier.theme(forCategory: "Série TV"), .series)
        XCTAssertEqual(ThemeClassifier.theme(forCategory: "Film"), .movies)
        XCTAssertEqual(ThemeClassifier.theme(forCategory: "Magazine d'information"), .news)
        XCTAssertEqual(ThemeClassifier.theme(forCategory: "Documentaire"), .documentary)
    }

    func testQualityAndPick() {
        XCTAssertEqual(ChannelQuality.of("|FR| TF1 4K"), .uhd)
        XCTAssertEqual(ChannelQuality.of("|FR| TF1 FHD"), .fhd)
        XCTAssertEqual(ChannelQuality.of("|FR| TF1 HD"), .hd)
        XCTAssertEqual(ChannelQuality.of("|FR| TF1 SD"), .sd)
        let names = ["TF1 4K", "TF1 FHD", "TF1 HD", "TF1 SD"]
        XCTAssertEqual(ChannelQuality.pick(names, target: .fhd, quality: ChannelQuality.of), "TF1 FHD")
        XCTAssertEqual(ChannelQuality.pick(["TF1 4K"], target: .hd, quality: ChannelQuality.of), "TF1 4K")
        XCTAssertEqual(ChannelMatcher.variantKey("|FR| TF1 FHD"), ChannelMatcher.variantKey("TF1 4K"))
    }

    func testCategoryParsed() {
        let xml = """
        <tv><programme start="20261021200000 +0200" stop="20261021220000 +0200" channel="a"><title>PSG - OM</title><category lang="fr">Sport</category></programme></tv>
        """
        let p = XMLTVParser.parse(data: Data(xml.utf8), window: nil)
        XCTAssertEqual(p.first?.category, "Sport")
        XCTAssertEqual(p.first?.theme, .sport)
    }
}

final class MoreThemeTests: XCTestCase {
    func testNewThemes() {
        XCTAssertEqual(ThemeClassifier.theme(forChannelName: "|XX| Something"), .adult)
        XCTAssertEqual(ThemeClassifier.theme(forChannelName: "Chaine", group: "ADULT 18+"), .adult)
        XCTAssertEqual(ThemeClassifier.theme(forChannelName: "|FR| AUTOMOTO HD"), .automotive)
        XCTAssertEqual(ThemeClassifier.theme(forChannelName: "|FR| CUISINE TV"), .lifestyle)
        XCTAssertEqual(ThemeClassifier.theme(forChannelName: "|FR| CHASSE ET PECHE"), .nature)
        XCTAssertEqual(ThemeClassifier.theme(forChannelName: "|FR| KTO"), .religion)
        XCTAssertEqual(ThemeClassifier.theme(forChannelName: "|FR| FRANCE 3 OCCITANIE"), .regional)
        XCTAssertEqual(ThemeClassifier.theme(forChannelName: "|FR| FRANCE 3 FHD"), .general)
        XCTAssertEqual(ThemeClassifier.theme(forChannelName: "|IT| RAI 1"), .international)
        XCTAssertEqual(ThemeClassifier.theme(forChannelName: "|IT| SKY SPORT"), .sport)
        XCTAssertEqual(ThemeClassifier.theme(forChannelName: "|FR| NOSTALGIE"), .radio)
        XCTAssertEqual(ThemeClassifier.theme(forCategory: "Sports mécaniques"), .automotive)
    }

    func testSportKinds() {
        XCTAssertEqual(SportKind.detect("Ligue 1 : PSG - OM"), .football)
        XCTAssertEqual(SportKind.detect("Top 14", "Rugby"), .rugby)
        XCTAssertEqual(SportKind.detect("Roland-Garros"), .tennis)
        XCTAssertEqual(SportKind.detect("UFC 300"), .combat)
        XCTAssertEqual(SportKind.detect("Téléfoot"), .football)
        XCTAssertNil(SportKind.detect("Journal de 20 heures"))
    }
}

final class CountryTests: XCTestCase {
    func testCategoryCountries() {
        XCTAssertEqual(CountryDetector.code(for: "FR| CINÉMA"), "FR")
        XCTAssertEqual(CountryDetector.code(for: "|PT| FILMES"), "PT")
        XCTAssertEqual(CountryDetector.code(for: "PT - FILMES 2024"), "PT")
        XCTAssertEqual(CountryDetector.code(for: "[IT] Film"), "IT")
        XCTAssertEqual(CountryDetector.code(for: "FRANCE HD"), "FR")
        XCTAssertEqual(CountryDetector.code(for: "Films VOSTFR"), "FR")
        XCTAssertEqual(CountryDetector.code(for: "BRASIL | NOVELAS"), "BR")
        XCTAssertEqual(CountryDetector.code(for: "EN: Movies 4K"), "EN")
        XCTAssertNil(CountryDetector.code(for: "Action"))
        XCTAssertNil(CountryDetector.code(for: "Nouveautés"))
        XCTAssertNil(CountryDetector.code(for: "MOVIES IN 4K"))
        XCTAssertNil(CountryDetector.code(for: "TV SHOWS"))
    }

    func testFilter() {
        let filter = CountryFilter(stored: "FR,IT", keepNeutral: false)
        XCTAssertTrue(filter.allows(category: "FR| CINÉMA"))
        XCTAssertFalse(filter.allows(category: "|PT| FILMES"))
        XCTAssertFalse(filter.allows(category: "Action"))
        XCTAssertTrue(CountryFilter(stored: "FR", keepNeutral: true).allows(category: "Action"))
        XCTAssertTrue(CountryFilter().allows(category: "|PT| FILMES"))
        XCTAssertEqual(filter.stored, "FR,IT")
    }
}
