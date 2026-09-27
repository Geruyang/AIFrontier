import Foundation

protocol FeedFetching: Sendable {
    func data(from url: URL) async throws -> Data
}

struct URLSessionFeedFetcher: FeedFetching {
    func data(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("AIFrontier/1.5 iOS", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              data.count <= 5_000_000 else { throw URLError(.badServerResponse) }
        return data
    }
}

enum FeedError: LocalizedError {
    case noSourcesAvailable, invalidFeed
    var errorDescription: String? {
        switch self {
        case .noSourcesAvailable: "No public source was available."
        case .invalidFeed: "The source returned an unsupported feed."
        }
    }
}

/// Local, transparent significance signals; these are not editorial verification.
enum NewsSelection {
    static func monthStart(relativeTo now: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(byAdding: .month, value: -1, to: now)!
    }

    static func importance(of article: NewsArticle) -> Int {
        let title = article.title.lowercased()
        let context = (title + " " + article.summary + " " + article.categories.joined(separator: " ")).lowercased()
        let ai = #"(\bai\b|artificial intelligence|generative|language model|\bllm\b|\bgpt[- ]|chatgpt|gemini|deepmind|neural|robotics|\bgpu\b|blackwell|rubin|machine learning|\bclaude\b|\banthropic\b|\bllama\b|\bmistral\b|\bqwen\b|\bdeepseek\b|\bcopilot\b)"#
        guard context.range(of: ai, options: .regularExpression) != nil else { return 0 }
        let exclude = #"(how to|how-to|tutorial|beginner|podcast|webinar|event recap|meet the team|course|tips for)"#
        guard title.range(of: exclude, options: .regularExpression) == nil else { return 0 }
        var score = 0
        for (pattern, weight) in [
            (#"(introduc|launch|releas|unveil|announc|now available|open.source)"#, 3),
            (#"(breakthrough|benchmark|research|reasoning|frontier|new model|new chip|new gpu)"#, 2),
            (#"(safety|security|regulat|governance|privacy|policy|partnership|acqui|funding|invest)"#, 2),
            (#"(model|agent|robot|chip|infrastructure|supercomput|multimodal|video generation)"#, 1)
        ] where title.range(of: pattern, options: .regularExpression) != nil {
            score += weight
        }
        if score < 2, context.range(of: #"(launch|release|announc|introduc|new model|safety|partnership)"#, options: .regularExpression) != nil {
            score = 2
        }
        return score
    }

    static func canonicalURL(_ url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
        components.fragment = nil
        components.queryItems = components.queryItems?.filter {
            let name = $0.name.lowercased()
            return !name.hasPrefix("utm_") && !["fbclid", "gclid"].contains(name)
        }
        if components.queryItems?.isEmpty == true { components.queryItems = nil }
        components.host = components.host?.lowercased()
        if components.path.count > 1, components.path.hasSuffix("/") { components.path.removeLast() }
        return components.url ?? url
    }

    static func select(_ input: [NewsArticle], now: Date) -> [NewsArticle] {
        let cutoff = monthStart(relativeTo: now)
        var unique: [String: NewsArticle] = [:]
        // Deterministic order also makes duplicate handling independent of network completion order.
        for article in input.sorted(by: {
            $0.publishedAt == $1.publishedAt ? $0.sourceName < $1.sourceName : $0.publishedAt > $1.publishedAt
        }) {
            guard !article.isReviewed, article.publishedAt >= cutoff, article.publishedAt <= now,
                  ["https", "http"].contains(article.url.scheme?.lowercased() ?? ""),
                  article.url.host != nil, importance(of: article) >= 2 else { continue }
            let url = canonicalURL(article.url)
            let id = url.absoluteString
            if unique[id] == nil {
                unique[id] = .init(id: id, title: article.title, summary: article.summary, url: url,
                                  sourceName: article.sourceName, publishedAt: article.publishedAt,
                                  languageCode: article.languageCode, categories: article.categories, isReviewed: false)
            }
        }
        return Array(unique.values.sorted {
            $0.publishedAt == $1.publishedAt ? $0.id < $1.id : $0.publishedAt > $1.publishedAt
        }.prefix(200))
    }
}

/// A foreground cadence and an earliest background request, never a guaranteed iOS wake-up time.
enum NewsRefreshPolicy {
    static let interval: TimeInterval = 5 * 60

    static func delay(lastAttempt: Date?, now: Date) -> TimeInterval {
        guard let lastAttempt else { return 0 }
        let elapsed = now.timeIntervalSince(lastAttempt)
        // Device clock changes must not suspend refreshing for hours.
        guard elapsed >= 0 else { return 0 }
        return max(0, interval - elapsed)
    }

    static func needsBackgroundRequest(hasPending: Bool, earliestDate: Date?, now: Date) -> Bool {
        guard hasPending else { return true }
        // nil means the existing request can run immediately.
        guard let earliestDate else { return false }
        return earliestDate > now.addingTimeInterval(interval)
    }
}

@MainActor
final class NewsService: ObservableObject {
    enum State: Equatable { case idle, loading, loaded, failed(String) }
    @Published private(set) var articles: [NewsArticle] = []
    @Published private(set) var state: State = .idle
    @Published private(set) var sourceFailures: [String] = []
    @Published private(set) var lastRefresh: Date?
    private let fetcher: any FeedFetching
    private let sources: [NewsSource]
    private let store: LocalStore
    private let clock: @Sendable () -> Date
    private var lastAttempt: Date?
    private var refreshWaiters: [UUID: CheckedContinuation<Void, Never>] = [:]

    init(fetcher: any FeedFetching = URLSessionFeedFetcher(), sources: [NewsSource] = NewsSource.defaults,
         store: LocalStore, clock: @escaping @Sendable () -> Date = { .now }) {
        self.fetcher = fetcher
        self.sources = sources
        self.store = store
        self.clock = clock
        let names = Set(sources.map(\.name))
        articles = NewsSelection.select(store.data.cachedArticles.filter { names.contains($0.sourceName) }, now: clock())
        lastRefresh = store.data.lastNewsRefresh
    }

    func refreshIfNeeded() async {
        // A previous scene may still be unwinding its cancelled request. Its attempt
        // timestamp is provisional until cleanup completes, so never sleep against it.
        while state == .loading, !Task.isCancelled { await waitForCurrentRefresh() }
        guard !Task.isCancelled else { return }
        guard NewsRefreshPolicy.delay(lastAttempt: lastAttempt ?? lastRefresh, now: clock()) == 0 else { return }
        await refresh()
    }

    /// SwiftUI cancels this structured task when the scene leaves the foreground.
    func refreshWhileActive() async {
        while !Task.isCancelled {
            await refreshIfNeeded()
            let delay = max(1, NewsRefreshPolicy.delay(lastAttempt: lastAttempt ?? lastRefresh, now: clock()))
            do { try await Task.sleep(for: .seconds(delay)) }
            catch { return }
        }
    }

    private func waitForCurrentRefresh() async {
        let id = UUID()
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                guard state == .loading, !Task.isCancelled else {
                    continuation.resume()
                    return
                }
                refreshWaiters[id] = continuation
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.refreshWaiters.removeValue(forKey: id)?.resume()
            }
        }
    }

    func refresh() async {
        guard !Task.isCancelled, state != .loading else { return }
        defer {
            let waiting = refreshWaiters.values
            refreshWaiters.removeAll()
            for continuation in waiting { continuation.resume() }
        }
        let previousState = state
        let previousFailures = sourceFailures
        let previousAttempt = lastAttempt
        lastAttempt = clock()
        // Expire cache even if this attempt subsequently fails.
        articles = NewsSelection.select(articles, now: clock())
        state = .loading
        sourceFailures = []
        var fetched: [NewsArticle] = []
        var successfulSources = 0
        let clock = self.clock
        await withTaskGroup(of: (String, Result<[NewsArticle], Error>).self) { group in
            // A rolling pool bounds sockets and parser work for the expanded catalog.
            let initialCount = min(6, sources.count)
            var nextIndex = initialCount
            for source in sources.prefix(initialCount) {
                group.addTask { [fetcher] in await Self.fetch(source, using: fetcher, clock: clock) }
            }
            for await (name, result) in group {
                switch result {
                case .success(let items): successfulSources += 1; fetched.append(contentsOf: items)
                case .failure: sourceFailures.append(name)
                }
                if !Task.isCancelled, nextIndex < sources.count {
                    let source = sources[nextIndex]
                    nextIndex += 1
                    group.addTask { [fetcher] in await Self.fetch(source, using: fetcher, clock: clock) }
                }
            }
        }
        guard !Task.isCancelled else {
            state = previousState
            sourceFailures = previousFailures
            lastAttempt = previousAttempt
            return
        }
        sourceFailures.sort()
        let now = clock()
        if successfulSources == 0 {
            articles = NewsSelection.select(articles, now: now)
            state = .failed(FeedError.noSourcesAvailable.localizedDescription)
        } else {
            // Feeds may only retain a few days: retain still-current announcements already seen.
            articles = NewsSelection.select(fetched + articles, now: now)
            store.updateArticles(articles, refreshedAt: now)
            lastRefresh = now
            state = .loaded
        }
    }

    nonisolated private static func fetch(_ source: NewsSource, using fetcher: any FeedFetching,
                                          clock: @Sendable () -> Date) async -> (String, Result<[NewsArticle], Error>) {
        do {
            try Task.checkCancellation()
            let data = try await fetcher.data(from: source.feedURL)
            try Task.checkCancellation()
            let parsed = try FeedParser.parse(data: data, source: source)
            // Discard old/non-AI entries off the main actor before merging the catalog.
            return (source.name, .success(NewsSelection.select(parsed, now: clock())))
        } catch { return (source.name, .failure(error)) }
    }

}

enum FeedParser {
    static func parse(data: Data, source: NewsSource) throws -> [NewsArticle] {
        guard data.count <= 5_000_000 else { throw FeedError.invalidFeed }
        let delegate = FeedXMLDelegate(source: source)
        let parser = XMLParser(data: data)
        parser.shouldResolveExternalEntities = false
        parser.delegate = delegate
        guard parser.parse(), delegate.recognizedRoot else { throw FeedError.invalidFeed }
        return delegate.articles
    }
}

private final class FeedXMLDelegate: NSObject, XMLParserDelegate {
    private let source: NewsSource
    private var item: [String: String] = [:]
    private var categories: [String] = []
    private var buffers: [String] = []
    private var insideItem = false
    private var itemDepth = 0
    private var atomLink: String?
    fileprivate var recognizedRoot = false
    fileprivate var articles: [NewsArticle] = []

    init(source: NewsSource) { self.source = source }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        let element = elementName.lowercased()
        if buffers.isEmpty { recognizedRoot = ["rss", "feed", "rdf:rdf"].contains(element) }
        buffers.append("")
        if !insideItem, element == "item" || element == "entry" {
            insideItem = true
            itemDepth = buffers.count
            item = [:]; categories = []; atomLink = nil
        }
        guard insideItem, buffers.count == itemDepth + 1 else { return }
        if element == "link", let href = attributeDict["href"],
           attributeDict["rel"] == nil || attributeDict["rel"] == "alternate" {
            atomLink = href
        }
        if element == "category", let term = attributeDict["term"] { categories.append(term) }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if !buffers.isEmpty { buffers[buffers.count - 1] += string }
    }
    func parser(_ parser: XMLParser, foundCDATA data: Data) {
        if let string = String(data: data, encoding: .utf8) { self.parser(parser, foundCharacters: string) }
    }
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let text = buffers.popLast() ?? ""
        if !buffers.isEmpty { buffers[buffers.count - 1] += text + " " }
        guard insideItem else { return }
        let element = elementName.lowercased()
        if buffers.count == itemDepth - 1, element == "item" || element == "entry" {
            finishItem(); insideItem = false
            return
        }
        guard buffers.count == itemDepth else { return }
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if element == "category", !value.isEmpty { categories.append(value) }
        if ["title", "description", "summary", "content", "content:encoded", "link", "guid", "id", "pubdate", "published", "updated", "dc:date"].contains(element), !value.isEmpty {
            item[element] = value
        }
    }

    private func finishItem() {
        let title = clean(item["title"] ?? "")
        let summary = String(clean(item["summary"] ?? item["description"] ?? item["content"] ?? item["content:encoded"] ?? "").prefix(600))
        let link = atomLink ?? item["link"] ?? item["guid"] ?? item["id"] ?? ""
        guard !title.isEmpty, let url = URL(string: link.trimmingCharacters(in: .whitespacesAndNewlines)),
              ["http", "https"].contains(url.scheme?.lowercased() ?? ""), url.host != nil,
              let date = ["published", "pubdate", "dc:date", "updated"].lazy.compactMap({ self.item[$0].flatMap(Self.parseDate) }).first else { return }
        articles.append(.init(id: item["guid"] ?? item["id"] ?? url.absoluteString, title: title,
                             summary: summary, url: url, sourceName: source.name, publishedAt: date,
                             languageCode: "en", categories: categories, isReviewed: false))
    }

    private func clean(_ value: String) -> String {
        let stripped = value.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        let decoded = stripped.replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"").replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ").replacingOccurrences(of: "&#8217;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<").replacingOccurrences(of: "&gt;", with: ">")
        return decoded.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func parseDate(_ value: String) -> Date? {
        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: value) { return date }
        iso.formatOptions.insert(.withFractionalSeconds)
        if let date = iso.date(from: value) { return date }
        for format in ["EEE, dd MMM yyyy HH:mm:ss Z", "EEE, d MMM yyyy HH:mm:ss Z", "EEE, dd MMM yyyy HH:mm:ss zzz", "yyyy-MM-dd'T'HH:mm:ssZ"] {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.isLenient = false
            formatter.dateFormat = format
            if let date = formatter.date(from: value) { return date }
        }
        return nil
    }
}
