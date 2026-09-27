import XCTest
@testable import AIFrontier

private let testSource = NewsSource(id: "test", name: "Test Source", feedURL: URL(string: "https://example.com/feed")!,
                                    homepageURL: URL(string: "https://example.com")!, kind: "Test")
private let testNow = Date(timeIntervalSince1970: 1_789_560_000) // Fixed clock; fixtures below use relative dates.
private func rss(title: String = "Introducing a new AI model", date: Date = testNow, link: String = "https://example.com/new") -> Data {
    let iso = ISO8601DateFormatter().string(from: date)
    return Data("""
    <rss version="2.0"><channel><title>Feed</title><item><title>\(title)</title><link>\(link)</link>
    <guid>new-item</guid><pubDate>\(iso)</pubDate><description>AI release announcement</description></item></channel></rss>
    """.utf8)
}
private func news(_ id: String, title: String = "Introducing a new AI model", date: Date = testNow,
                  url: String? = nil, reviewed: Bool = false, source: String = "Test Source") -> NewsArticle {
    .init(id: id, title: title, summary: "", url: URL(string: url ?? "https://example.com/\(id)")!,
          sourceName: source, publishedAt: date, languageCode: "en", categories: [], isReviewed: reviewed)
}

final class FeedParserTests: XCTestCase {
    func testParsesRSSAndRemovesMarkup() throws {
        let xml = """
        <rss><channel><item><title>Model &amp; Data</title><link>https://example.com/a</link><guid>item-a</guid>
        <pubDate>Mon, 15 Sep 2025 12:00:00 +0000</pubDate>
        <description><![CDATA[<p>A <b>useful</b> result.</p>]]></description><category>Evaluation</category></item></channel></rss>
        """
        let articles = try FeedParser.parse(data: Data(xml.utf8), source: testSource)
        XCTAssertEqual(articles.count, 1)
        XCTAssertEqual(articles[0].id, "item-a")
        XCTAssertEqual(articles[0].title, "Model & Data")
        XCTAssertEqual(articles[0].summary, "A useful result.")
        XCTAssertEqual(articles[0].categories, ["Evaluation"])
    }

    func testAtomAlternateLinkWinsOverSelfAndFractionalDateParses() throws {
        let xml = """
        <feed xmlns="http://www.w3.org/2005/Atom"><entry><title>Open Model</title><id>tag:example,1</id>
        <link rel="alternate" href="https://example.com/model"/><link rel="self" href="https://example.com/model.atom"/>
        <published>2025-09-15T12:30:00.123Z</published><updated>2026-09-16T00:00:00Z</updated>
        <category term="Release"/><summary>Release notes</summary></entry></feed>
        """
        let article = try XCTUnwrap(FeedParser.parse(data: Data(xml.utf8), source: testSource).first)
        XCTAssertEqual(article.url.absoluteString, "https://example.com/model")
        XCTAssertEqual(article.categories, ["Release"])
        XCTAssertLessThan(article.publishedAt, Date(timeIntervalSince1970: 1_760_000_000))
    }

    func testNestedAtomMarkupPreservesWholeSummary() throws {
        let xml = """
        <feed><entry><title>AI release</title><link href="https://example.com/a"/><published>2026-09-15T12:00:00Z</published>
        <content><div>First <b>important</b> detail and <i>another</i> fact.</div></content></entry></feed>
        """
        XCTAssertEqual(try FeedParser.parse(data: Data(xml.utf8), source: testSource).first?.summary, "First important detail and another fact.")
    }

    func testInvalidMissingDatesAndUnsafeLinksAreNotInventedAsCurrent() throws {
        for xml in [
            "<rss><channel><item><title>AI launch</title><link>https://example.com/a</link></item></channel></rss>",
            "<rss><channel><item><title>AI launch</title><link>https://example.com/a</link><pubDate>not a date</pubDate></item></channel></rss>"
        ] {
            XCTAssertTrue(try FeedParser.parse(data: Data(xml.utf8), source: testSource).isEmpty)
        }
        for link in ["javascript:alert(1)", "file:///tmp/a", "/relative"] {
            XCTAssertTrue(try FeedParser.parse(data: rss(link: link), source: testSource).isEmpty)
        }
    }

    func testValidEmptyFeedIsSuccessButUnsupportedOrMalformedFeedFails() throws {
        XCTAssertTrue(try FeedParser.parse(data: Data("<rss><channel/></rss>".utf8), source: testSource).isEmpty)
        XCTAssertThrowsError(try FeedParser.parse(data: Data("<html><body>Error</body></html>".utf8), source: testSource))
        XCTAssertThrowsError(try FeedParser.parse(data: Data("<rss><channel>".utf8), source: testSource))
    }
}

final class NewsSelectionTests: XCTestCase {
    func testRollingCalendarMonthIncludesBoundaryAndRejectsOldOrFutureNews() {
        let boundary = NewsSelection.monthStart(relativeTo: testNow)
        let input = [news("boundary", date: boundary), news("old", date: boundary.addingTimeInterval(-1)),
                     news("now"), news("future", date: testNow.addingTimeInterval(1))]
        XCTAssertEqual(Set(NewsSelection.select(input, now: testNow).map(\.id)),
                       ["https://example.com/boundary", "https://example.com/now"])
    }

    func testOnlyRelevantImportantAnnouncementsSurvive() {
        let input = [
            news("model"), news("policy", title: "AI safety policy announced"),
            news("tutorial", title: "How to launch an AI model"),
            news("ordinary", title: "Introducing a new cooking pan"),
            news("fluff", title: "A day with AI"),
            news("reviewed", reviewed: true)
        ]
        XCTAssertEqual(Set(NewsSelection.select(input, now: testNow).map(\.id)),
                       ["https://example.com/model", "https://example.com/policy"])
    }

    func testDuplicateUrlsLoseTrackingAndFragmentsButKeepFunctionalQuery() {
        let articles = NewsSelection.select([
            news("a", url: "https://example.com/release/?utm_source=rss#top"),
            news("b", url: "https://example.com/release"),
            news("c", url: "https://example.com/release?version=2&utm_campaign=ai")
        ], now: testNow)
        XCTAssertEqual(Set(articles.map(\.id)), ["https://example.com/release", "https://example.com/release?version=2"])
        XCTAssertEqual(articles.count, 2)
    }

    func testSelectionCapsCacheAndSortsDates() {
        let input = (0..<250).map { news("item-\($0)", date: testNow.addingTimeInterval(-Double($0))) }
        let articles = NewsSelection.select(input, now: testNow)
        XCTAssertEqual(articles.count, 200)
        XCTAssertEqual(articles.first?.publishedAt, testNow)
        XCTAssertTrue(zip(articles, articles.dropFirst()).allSatisfy { $0.publishedAt >= $1.publishedAt })
    }
}

@MainActor
final class NewsServiceTests: XCTestCase {
    private actor StubFetcher: FeedFetching {
        let payload: Data?
        private(set) var calls = 0
        init(_ payload: Data?) { self.payload = payload }
        func data(from url: URL) async throws -> Data {
            calls += 1
            guard let payload else { throw URLError(.notConnectedToInternet) }
            return payload
        }
    }

    func testRefreshPublishesAndCachesFetchedCurrentArticles() async {
        let store = makeStore()
        let service = NewsService(fetcher: StubFetcher(rss()), sources: [testSource], store: store, clock: { testNow })
        await service.refresh()
        XCTAssertEqual(service.state, .loaded)
        XCTAssertEqual(service.articles.map(\.id), ["https://example.com/new"])
        XCTAssertEqual(service.articles, store.data.cachedArticles)
        XCTAssertEqual(store.data.lastNewsRefresh, testNow)
    }

    func testRefreshFailureKeepsOnlyUnexpiredCachedNewsAndOldTimestamp() async {
        let store = makeStore()
        let oldCheck = testNow.addingTimeInterval(-500)
        store.updateArticles([news("cached"), news("expired", date: NewsSelection.monthStart(relativeTo: testNow).addingTimeInterval(-1))], refreshedAt: oldCheck)
        let service = NewsService(fetcher: StubFetcher(nil), sources: [testSource], store: store, clock: { testNow })
        await service.refresh()
        XCTAssertEqual(service.articles.map(\.id), ["https://example.com/cached"])
        XCTAssertEqual(service.sourceFailures, ["Test Source"])
        XCTAssertEqual(service.lastRefresh, oldCheck)
        if case .failed = service.state {} else { XCTFail("Expected failed state") }
    }

    func testEmptySuccessfulFeedDoesNotInventFallbackNews() async {
        let store = makeStore()
        let service = NewsService(fetcher: StubFetcher(Data("<rss><channel/></rss>".utf8)), sources: [testSource], store: store, clock: { testNow })
        await service.refresh()
        XCTAssertEqual(service.state, .loaded)
        XCTAssertTrue(service.articles.isEmpty)
        XCTAssertEqual(service.lastRefresh, testNow)
    }

    func testRepeatedOpensCanRequestFreshDataAgain() async {
        let fetcher = StubFetcher(rss())
        let service = NewsService(fetcher: fetcher, sources: [testSource], store: makeStore(), clock: { testNow })
        await service.refresh()
        await service.refresh()
        let calls = await fetcher.calls
        XCTAssertEqual(calls, 2)
        XCTAssertEqual(service.articles.count, 1)
    }

    func testPreviousResearchFeedsAndBuiltInBriefsDoNotAppearAfterMigration() {
        let store = makeStore()
        store.updateArticles([news("paper", source: "arXiv AI"), news("old-brief", reviewed: true), news("official")])
        let service = NewsService(sources: [testSource], store: store, clock: { testNow })
        XCTAssertEqual(service.articles.map(\.id), ["https://example.com/official"])
    }

    private func makeStore() -> LocalStore {
        let name = "NewsServiceTests.\(UUID().uuidString)"
        return LocalStore(defaults: UserDefaults(suiteName: name)!, storageKey: "news")
    }
}
