import XCTest
@testable import KastideoCore

final class MediaDetailsTests: XCTestCase {
    func testCleanTitle() {
        XCTAssertEqual(TMDB.cleanTitle("FR - Dune (2021) 4K").title, "Dune")
        XCTAssertEqual(TMDB.cleanTitle("FR - Dune (2021) 4K").year, 2021)
        XCTAssertEqual(TMDB.cleanTitle("|VF| Oppenheimer [MULTI]").title, "Oppenheimer")
        XCTAssertEqual(TMDB.cleanTitle("Alien: Romulus 2024").title, "Alien: Romulus")
        XCTAssertEqual(TMDB.cleanTitle("Alien: Romulus 2024").year, 2024)
    }

    func testVODInfo() throws {
        let json = """
        {"info":{"movie_image":"http://x/p.jpg","plot":"Un résumé.","cast":"Acteur A, Acteur B","director":"Réal",
        "genre":"Drame / Action","rating":"7.4","releasedate":"2021-09-15","duration_secs":9360,
        "youtube_trailer":"abc123","backdrop_path":["http://x/b.jpg"],"tmdb_id":"438631"},
        "movie_data":{"name":"Dune","stream_id":12}}
        """
        let d = try XtreamAPI.parseVODDetails(Data(json.utf8))
        XCTAssertEqual(d.title, "Dune")
        XCTAssertEqual(d.cast.map(\.name), ["Acteur A", "Acteur B"])
        XCTAssertEqual(d.genres, ["Drame", "Action"])
        XCTAssertEqual(d.year, 2021)
        XCTAssertEqual(d.runtime, 156)
        XCTAssertEqual(d.rating, 7.4)
        XCTAssertEqual(d.tmdbID, "438631")
        XCTAssertEqual(d.trailerURL?.absoluteString, "https://www.youtube.com/watch?v=abc123")
        XCTAssertEqual(d.backdropURL?.absoluteString, "http://x/b.jpg")
    }

    func testTMDBDetailsAndMerge() throws {
        let json = """
        {"id":438631,"title":"Dune","overview":"Paul Atreides…","release_date":"2021-09-15","runtime":155,
        "vote_average":7.8,"genres":[{"name":"Science-Fiction"}],"poster_path":"/p.jpg","backdrop_path":"/b.jpg",
        "credits":{"cast":[{"name":"Timothée Chalamet","character":"Paul","profile_path":"/t.jpg"}],
        "crew":[{"name":"Denis Villeneuve","job":"Director"}]},
        "videos":{"results":[{"site":"YouTube","type":"Trailer","key":"n9xhJrPXop4"}]}}
        """
        let tmdb = try TMDB.parseDetails(Data(json.utf8), isSeries: false)
        XCTAssertEqual(tmdb.directors, ["Denis Villeneuve"])
        XCTAssertEqual(tmdb.cast.first?.photoURL?.absoluteString, "https://image.tmdb.org/t/p/w185/t.jpg")
        var iptv = MediaDetails()
        iptv.plot = "Résumé IPTV"
        iptv.sources = ["IPTV"]
        let merged = iptv.merged(with: tmdb)
        XCTAssertEqual(merged.plot, "Paul Atreides…")
        XCTAssertEqual(merged.sources, ["IPTV", "TMDB"])
        XCTAssertEqual(TMDB.parseSearch(Data(#"{"results":[{"id":1,"release_date":"1984-01-01"},{"id":2,"release_date":"2021-01-01"}]}"#.utf8), year: 2021, isSeries: false), "2")
    }
}

final class TrendingTests: XCTestCase {
    func testTrendingAndTitleKey() {
        let json = #"{"results":[{"id":1,"title":"Dune : Deuxième partie","original_title":"Dune: Part Two","release_date":"2024-02-27","backdrop_path":"/b.jpg"}]}"#
        let list = TMDB.parseTrending(Data(json.utf8), isSeries: false)
        XCTAssertEqual(list.first?.year, 2024)
        XCTAssertEqual(TMDB.titleKey(list[0].title), TMDB.titleKey("|FR| Dune : deuxième partie (2024) 4K"))
        XCTAssertEqual(XtreamAPI.timestamp("1729500000")?.timeIntervalSince1970, 1729500000)
    }
}

final class TMDBMatchTests: XCTestCase {
    func testParseMatches() {
        let json = #"{"results":[{"id":438631,"title":"Dune","release_date":"2021-09-15","poster_path":"/d.jpg","overview":"Paul"},{"title":"sans id"}]}"#
        let matches = TMDB.parseMatches(Data(json.utf8), isSeries: false)
        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches[0].tmdbID, "438631")
        XCTAssertEqual(matches[0].year, 2021)
        XCTAssertEqual(matches[0].posterURL?.absoluteString, "https://image.tmdb.org/t/p/w342/d.jpg")
    }
}
