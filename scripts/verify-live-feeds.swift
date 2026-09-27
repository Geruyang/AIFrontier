// Compile this harness with AppModels.swift, LocalStore.swift and NewsService.swift.
import Foundation
import Combine
import Darwin

@main
struct VerifyLiveFeeds {
    @MainActor
    static func main() async {
        let fetcher = URLSessionFeedFetcher()
        let now = Date()
        var failed = false
        var all: [NewsArticle] = []
        for source in NewsSource.defaults {
            do {
                let data = try await fetcher.data(from: source.feedURL)
                let parsed = try FeedParser.parse(data: data, source: source)
                let selected = NewsSelection.select(parsed, now: now)
                print("\(source.name): \(parsed.count) parsed; \(selected.count) significant items in past month")
                guard !parsed.isEmpty else { throw FeedError.invalidFeed }
                guard selected.allSatisfy({ $0.publishedAt >= NewsSelection.monthStart(relativeTo: now) && $0.publishedAt <= now }) else {
                    throw FeedError.invalidFeed
                }
                all.append(contentsOf: parsed)
            } catch {
                failed = true
                print("\(source.name): FAILED — \(error.localizedDescription)")
            }
        }
        let selected = NewsSelection.select(all, now: now)
        print("Combined: \(selected.count) unique, significant current-month announcements")
        if selected.isEmpty || failed { exit(1) }
    }
}
