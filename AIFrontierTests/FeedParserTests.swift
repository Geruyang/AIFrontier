import XCTest
import Combine
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

    func testFallsBackToValidPublicationDateWhenAnotherFieldIsMalformed() throws {
        let xml = """
        <rss xmlns:dc="http://purl.org/dc/elements/1.1/"><channel><item>
        <title>AI governance research</title><link>https://example.com/research</link>
        <pubDate>not a date</pubDate><dc:date>2026-09-25T12:00:00-04:00</dc:date>
        </item></channel></rss>
        """
        let item = try XCTUnwrap(FeedParser.parse(data: Data(xml.utf8), source: testSource).first)
        XCTAssertEqual(item.publishedAt, ISO8601DateFormatter().date(from: "2026-09-25T16:00:00Z"))
    }

    func testParsesRSSDateWithNamedTimezone() throws {
        let xml = """
        <rss><channel><item><title>AI research</title><link>https://example.com/research</link>
        <pubDate>Fri, 25 Sep 2026 12:00:00 EDT</pubDate></item></channel></rss>
        """
        let item = try XCTUnwrap(FeedParser.parse(data: Data(xml.utf8), source: testSource).first)
        XCTAssertEqual(item.publishedAt, ISO8601DateFormatter().date(from: "2026-09-25T16:00:00Z"))
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

    func testNestedAtomSourceDoesNotReplaceArticleIdentity() throws {
        let xml = """
        <feed><entry><title>Introducing an AI model</title><id>article-id</id>
        <link href="https://example.com/article"/><published>2026-09-15T12:00:00Z</published>
        <source><title>Publisher feed</title><id>feed-id</id><link href="https://example.com/feed"/></source>
        <summary>Article summary</summary></entry></feed>
        """
        let article = try XCTUnwrap(FeedParser.parse(data: Data(xml.utf8), source: testSource).first)
        XCTAssertEqual(article.title, "Introducing an AI model")
        XCTAssertEqual(article.id, "article-id")
        XCTAssertEqual(article.url.absoluteString, "https://example.com/article")
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

    func testRecognizesMajorModelAnnouncementsWithoutLiteralAIInTitle() {
        let input = [news("claude", title: "Introducing Claude 5"),
                     news("llama", title: "Llama 5 is now available"),
                     news("qwen", title: "Qwen releases a new reasoning model"),
                     news("copilot", title: "Introducing Microsoft Copilot updates")]
        XCTAssertEqual(NewsSelection.select(input, now: testNow).count, 4)
    }

    func testSelectionCapsCacheAndSortsDates() {
        let input = (0..<250).map { news("item-\($0)", date: testNow.addingTimeInterval(-Double($0))) }
        let articles = NewsSelection.select(input, now: testNow)
        XCTAssertEqual(articles.count, 200)
        XCTAssertEqual(articles.first?.publishedAt, testNow)
        XCTAssertTrue(zip(articles, articles.dropFirst()).allSatisfy { $0.publishedAt >= $1.publishedAt })
    }
}

final class NewsRefreshPolicyTests: XCTestCase {
    func testFiveMinuteBoundaryAndDeviceClockChanges() {
        XCTAssertEqual(NewsRefreshPolicy.delay(lastAttempt: nil, now: testNow), 0)
        XCTAssertEqual(NewsRefreshPolicy.delay(lastAttempt: testNow, now: testNow.addingTimeInterval(299)), 1)
        XCTAssertEqual(NewsRefreshPolicy.delay(lastAttempt: testNow, now: testNow.addingTimeInterval(300)), 0)
        XCTAssertEqual(NewsRefreshPolicy.delay(lastAttempt: testNow, now: testNow.addingTimeInterval(-60)), 0)
    }

    func testEarlierPendingBackgroundRequestIsNotPostponed() {
        XCTAssertTrue(NewsRefreshPolicy.needsBackgroundRequest(hasPending: false, earliestDate: nil, now: testNow))
        XCTAssertFalse(NewsRefreshPolicy.needsBackgroundRequest(hasPending: true, earliestDate: nil, now: testNow))
        XCTAssertFalse(NewsRefreshPolicy.needsBackgroundRequest(hasPending: true, earliestDate: testNow.addingTimeInterval(60), now: testNow))
        XCTAssertFalse(NewsRefreshPolicy.needsBackgroundRequest(hasPending: true, earliestDate: testNow.addingTimeInterval(300), now: testNow))
        XCTAssertTrue(NewsRefreshPolicy.needsBackgroundRequest(hasPending: true, earliestDate: testNow.addingTimeInterval(6 * 60 * 60), now: testNow))
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

    func testForegroundRefreshSkipsFreshCacheButManualRefreshStillWorks() async {
        let store = makeStore()
        store.updateArticles([news("cached")], refreshedAt: testNow.addingTimeInterval(-299))
        let service = NewsService(fetcher: StubFetcher(rss()), sources: [testSource], store: store, clock: { testNow })
        await service.refreshIfNeeded()
        XCTAssertEqual(service.state, .idle)
        XCTAssertEqual(service.articles.map(\.id), ["https://example.com/cached"])
        await service.refresh()
        XCTAssertEqual(service.state, .loaded)
        XCTAssertTrue(service.articles.contains { $0.id == "https://example.com/new" })
    }

    func testForegroundRefreshFetchesAtFiveMinuteBoundary() async {
        let store = makeStore()
        store.updateArticles([], refreshedAt: testNow.addingTimeInterval(-300))
        let service = NewsService(fetcher: StubFetcher(rss()), sources: [testSource], store: store, clock: { testNow })
        await service.refreshIfNeeded()
        XCTAssertEqual(service.state, .loaded)
        XCTAssertEqual(service.articles.map(\.id), ["https://example.com/new"])
    }

    func testAutomaticFailureDoesNotCauseAnImmediateRetryLoop() async {
        let fetcher = StubFetcher(nil)
        let service = NewsService(fetcher: fetcher, sources: [testSource], store: makeStore(), clock: { testNow })
        await service.refreshIfNeeded()
        await service.refreshIfNeeded()
        let calls = await fetcher.calls
        XCTAssertEqual(calls, 1)
        if case .failed = service.state {} else { XCTFail("Expected network failure") }
    }

    private actor WaitingFetcher: FeedFetching {
        private var started = false
        private var waiter: CheckedContinuation<Void, Never>?
        private(set) var calls = 0
        func waitUntilStarted() async {
            if started { return }
            await withCheckedContinuation { waiter = $0 }
        }
        func data(from url: URL) async throws -> Data {
            calls += 1
            started = true
            waiter?.resume()
            waiter = nil
            try await Task.sleep(for: .seconds(30))
            return rss()
        }
    }

    func testOverlappingRefreshIsCoalescedAndCancellationRestoresCache() async {
        let store = makeStore()
        store.updateArticles([news("cached")], refreshedAt: testNow.addingTimeInterval(-600))
        let fetcher = WaitingFetcher()
        let service = NewsService(fetcher: fetcher, sources: [testSource], store: store, clock: { testNow })
        let task = Task { await service.refresh() }
        await fetcher.waitUntilStarted()
        await service.refresh()
        XCTAssertEqual(service.state, .loading)
        let calls = await fetcher.calls
        XCTAssertEqual(calls, 1)
        task.cancel()
        await task.value
        XCTAssertEqual(service.state, .idle)
        XCTAssertEqual(service.articles.map(\.id), ["https://example.com/cached"])
        XCTAssertEqual(service.lastRefresh, testNow.addingTimeInterval(-600))
        XCTAssertTrue(service.sourceFailures.isEmpty)
    }

    private actor DelayedCancellationFetcher: FeedFetching {
        private var started = false
        private var startedWaiter: CheckedContinuation<Void, Never>?
        private var finishFirst: CheckedContinuation<Void, Never>?
        private var calls = 0

        func waitUntilStarted() async {
            if started { return }
            await withCheckedContinuation { startedWaiter = $0 }
        }
        func releaseFirstRequest() { finishFirst?.resume(); finishFirst = nil }
        func data(from url: URL) async throws -> Data {
            calls += 1
            if calls == 1 {
                // Model URLSession taking time to finish cancelled request cleanup.
                await withCheckedContinuation { continuation in
                    finishFirst = continuation
                    started = true
                    startedWaiter?.resume()
                    startedWaiter = nil
                }
                try Task.checkCancellation()
            }
            return rss()
        }
    }

    func testReturningToForegroundWaitsForCancelledRequestThenRefreshesImmediately() async {
        let store = makeStore()
        store.updateArticles([news("cached")], refreshedAt: testNow.addingTimeInterval(-600))
        let fetcher = DelayedCancellationFetcher()
        let service = NewsService(fetcher: fetcher, sources: [testSource], store: store, clock: { testNow })
        let previousScene = Task { await service.refreshWhileActive() }
        await fetcher.waitUntilStarted()
        previousScene.cancel()

        let entered = expectation(description: "New foreground loop entered")
        let refreshed = expectation(description: "News refreshed without a five-minute delay")
        let observation = service.$state.filter { $0 == .loaded }.sink { _ in refreshed.fulfill() }
        let nextScene = Task {
            entered.fulfill()
            await service.refreshWhileActive()
        }
        await fulfillment(of: [entered], timeout: 2)
        await fetcher.releaseFirstRequest()
        await previousScene.value
        await fulfillment(of: [refreshed], timeout: 2)
        observation.cancel()
        nextScene.cancel()
        await nextScene.value
        XCTAssertEqual(service.lastRefresh, testNow)
        XCTAssertTrue(service.articles.contains { $0.id == "https://example.com/new" })
    }

    func testForegroundWaitCanBeCancelledBeforeOldRequestFinishesCleaningUp() async {
        let fetcher = DelayedCancellationFetcher()
        let service = NewsService(fetcher: fetcher, sources: [testSource], store: makeStore(), clock: { testNow })
        let previousScene = Task { await service.refresh() }
        await fetcher.waitUntilStarted()
        previousScene.cancel()
        let entered = expectation(description: "New loop entered")
        let stopped = expectation(description: "New loop cancellation is independent of old request")
        let nextScene = Task {
            entered.fulfill()
            await service.refreshWhileActive()
            stopped.fulfill()
        }
        await fulfillment(of: [entered], timeout: 2)
        nextScene.cancel()
        await fulfillment(of: [stopped], timeout: 2)
        await fetcher.releaseFirstRequest()
        await previousScene.value
        await nextScene.value
        XCTAssertEqual(service.state, .idle)
        XCTAssertNil(service.lastRefresh)
    }

    func testAlreadyCancelledRefreshDoesNotPublishAnErrorOrCacheData() async {
        let store = makeStore()
        let service = NewsService(fetcher: StubFetcher(rss()), sources: [testSource], store: store, clock: { testNow })
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            await service.refresh()
        }
        await task.value
        XCTAssertEqual(service.state, .idle)
        XCTAssertNil(service.lastRefresh)
        XCTAssertTrue(store.data.cachedArticles.isEmpty)
    }

    private func makeStore() -> LocalStore {
        let name = "NewsServiceTests.\(UUID().uuidString)"
        return LocalStore(defaults: UserDefaults(suiteName: name)!, storageKey: "news")
    }
}

@MainActor
final class NewsExpansionTests: XCTestCase {
    private actor CountingFetcher: FeedFetching {
        private var active = 0
        private(set) var peak = 0
        private(set) var calls = 0
        func data(from url: URL) async throws -> Data {
            active += 1; calls += 1; peak = max(peak, active)
            defer { active -= 1 }
            try await Task.sleep(for: .milliseconds(20))
            return rss(link: url.absoluteString + "/article")
        }
    }

    func testLargeCatalogBoundsConcurrentRequestsAndVisitsEverySource() async {
        let sources = (0..<54).map { index in
            NewsSource(id: "source-\(index)", name: "Source \(index)", feedURL: URL(string: "https://example.com/\(index)")!, homepageURL: URL(string: "https://example.com")!, kind: "Test")
        }
        let fetcher = CountingFetcher()
        let store = LocalStore(defaults: UserDefaults(suiteName: "Expansion.\(UUID().uuidString)")!)
        let service = NewsService(fetcher: fetcher, sources: sources, store: store, clock: { testNow })
        await service.refresh()
        let peak = await fetcher.peak
        let calls = await fetcher.calls
        XCTAssertLessThanOrEqual(peak, 6, "Expanding sources must not launch every network request together")
        XCTAssertEqual(calls, sources.count)
        XCTAssertEqual(service.articles.count, sources.count)
        XCTAssertEqual(service.state, .loaded)
    }

    func testCatalogHasAtLeastFiftyDistinctHTTPSFeeds() {
        let sources = NewsSource.defaults
        XCTAssertGreaterThanOrEqual(sources.count, 50)
        XCTAssertEqual(Set(sources.map(\.id)).count, sources.count)
        XCTAssertEqual(Set(sources.map(\.name)).count, sources.count)
        XCTAssertEqual(Set(sources.map(\.feedURL)).count, sources.count)
        XCTAssertTrue(sources.allSatisfy { $0.feedURL.scheme == "https" && $0.homepageURL.scheme == "https" })
    }
}
