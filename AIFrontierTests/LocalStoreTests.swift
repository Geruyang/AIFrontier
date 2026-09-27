import XCTest
@testable import AIFrontier

@MainActor
final class LocalStoreTests: XCTestCase {
    func testProgressBookmarkAndCachePersist() {
        let suite = "LocalStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = LocalStore(defaults: defaults, storageKey: "test")
        store.complete(lessonID: "lesson-01", score: 2)
        store.complete(lessonID: "lesson-01", score: 1)
        store.toggleBookmark(articleID: "article-1")
        store.updateArticles([fixtureArticle], refreshedAt: Date(timeIntervalSince1970: 100))

        let restored = LocalStore(defaults: defaults, storageKey: "test")
        XCTAssertTrue(restored.isCompleted("lesson-01"))
        XCTAssertEqual(restored.score(for: "lesson-01"), 2)
        XCTAssertTrue(restored.isBookmarked("article-1"))
        XCTAssertEqual(restored.data.cachedArticles.count, 1)
        XCTAssertEqual(restored.data.lastNewsRefresh, Date(timeIntervalSince1970: 100))
    }

    func testClearingLearningDataPreservesArticleCache() {
        let suite = "LocalStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = LocalStore(defaults: defaults, storageKey: "test")
        store.complete(lessonID: "lesson-01", score: 3)
        store.updateArticles([fixtureArticle])
        store.clearLearningData()
        XCTAssertTrue(store.data.completedLessonIDs.isEmpty)
        XCTAssertEqual(store.data.cachedArticles.count, 1)
    }

    private var fixtureArticle: NewsArticle {
        .init(id: "fixture", title: "AI model launch", summary: "Test fixture", url: URL(string: "https://example.com/news")!,
              sourceName: "Test", publishedAt: .now, languageCode: "en", categories: ["AI"], isReviewed: false)
    }
}
