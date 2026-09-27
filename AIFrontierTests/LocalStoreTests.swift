import XCTest
@testable import AIFrontier

@MainActor
final class LocalStoreTests: XCTestCase {
    func testProgressBookmarkAndCachePersist() {
        let suite = "LocalStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = LocalStore(defaults: defaults, storageKey: "test")
        store.complete(lessonID: "course-explorer-what-ai", score: 4)
        store.complete(lessonID: "course-explorer-what-ai", score: 1)
        store.toggleBookmark(articleID: "article-1")
        store.updateArticles([fixtureArticle], refreshedAt: Date(timeIntervalSince1970: 100))

        let restored = LocalStore(defaults: defaults, storageKey: "test")
        XCTAssertTrue(restored.isCompleted("course-explorer-what-ai"))
        XCTAssertEqual(restored.score(for: "course-explorer-what-ai"), 4)
        XCTAssertTrue(restored.isBookmarked("article-1"))
        XCTAssertEqual(restored.data.cachedArticles.count, 1)
        XCTAssertEqual(restored.data.lastNewsRefresh, Date(timeIntervalSince1970: 100))
    }

    func testClearingLearningDataPreservesArticleCache() {
        let suite = "LocalStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = LocalStore(defaults: defaults, storageKey: "test")
        store.complete(lessonID: "course-explorer-what-ai", score: 3)
        store.updateArticles([fixtureArticle])
        store.clearLearningData()
        XCTAssertTrue(store.data.completedLessonIDs.isEmpty)
        XCTAssertEqual(store.data.cachedArticles.count, 1)
    }

    func testFailedQuizDoesNotCompleteLesson() {
        let suite = "LocalStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = LocalStore(defaults: defaults, storageKey: "test")
        store.complete(lessonID: "course-explorer-what-ai", score: 1)
        XCTAssertFalse(store.isCompleted("course-explorer-what-ai"))
        XCTAssertEqual(store.score(for: "course-explorer-what-ai"), 1)
    }

    func testClearingLearningDataPreservesBookmarks() {
        let suite = "LocalStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = LocalStore(defaults: defaults, storageKey: "test")
        store.updateArticles([fixtureArticle])
        store.toggleBookmark(articleID: fixtureArticle.id)
        store.clearLearningData()
        XCTAssertTrue(store.isBookmarked(fixtureArticle.id))
    }

    func testBookmarksSurviveCacheRolloverAndRestart() {
        withStore { store, defaults in
            store.updateArticles([self.fixtureArticle])
            store.toggleBookmark(articleID: self.fixtureArticle.id)
            store.updateArticles([])
            let restored = LocalStore(defaults: defaults, storageKey: "test")
            XCTAssertEqual(restored.savedArticles.map(\.id), ["fixture"])
            restored.toggleBookmark(articleID: "fixture")
            XCTAssertTrue(LocalStore(defaults: defaults, storageKey: "test").savedArticles.isEmpty)
        }
    }

    func testLegacyDataMigratesBookmarksAndCorrectsFailedCompletion() throws {
        let suite = "LocalStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        var data = AppUserData()
        data.completedLessonIDs = ["course-explorer-what-ai"]
        data.lessonScores = ["course-explorer-what-ai": 1]
        data.cachedArticles = [fixtureArticle]
        data.bookmarkedArticleIDs = ["fixture"]
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(data)) as? [String: Any])
        for key in ["savedArticles", "latestLessonScores", "lastVisitedLessonID"] { json.removeValue(forKey: key) }
        defaults.set(try JSONSerialization.data(withJSONObject: json), forKey: "test")
        let restored = LocalStore(defaults: defaults, storageKey: "test")
        XCTAssertFalse(restored.isCompleted("course-explorer-what-ai"))
        XCTAssertEqual(restored.savedArticles.map(\.id), ["fixture"])
        XCTAssertTrue(restored.needsReview(CurriculumCatalog.lessons.first { $0.id == "course-explorer-what-ai" }!))
    }

    func testRetakeKeepsBestScoreButReviewUsesLatestAttempt() {
        withStore { store, defaults in
            let lesson = CurriculumCatalog.lessons.first { $0.id == "course-explorer-what-ai" }!
            store.complete(lessonID: lesson.id, score: 3)
            XCTAssertFalse(store.isCompleted(lesson.id))
            store.complete(lessonID: lesson.id, score: 4)
            XCTAssertTrue(store.isCompleted(lesson.id))
            store.complete(lessonID: lesson.id, score: 6)
            XCTAssertFalse(store.needsReview(lesson))
            store.complete(lessonID: lesson.id, score: 1)
            let restored = LocalStore(defaults: defaults, storageKey: "test")
            XCTAssertTrue(restored.isCompleted(lesson.id))
            XCTAssertEqual(restored.score(for: lesson.id), 6)
            XCTAssertTrue(restored.needsReview(lesson))
        }
    }

    func testInvalidScoresDoNotChangeProgress() {
        withStore { store, _ in
            for score in [-1, 7, Int.max] { store.complete(lessonID: "course-explorer-what-ai", score: score) }
            store.complete(lessonID: "missing", score: 2)
            XCTAssertTrue(store.data.lessonScores.isEmpty)
            XCTAssertTrue(store.data.completedLessonIDs.isEmpty)
        }
    }

    func testResumePersistsAndLearningResetClearsReview() {
        withStore { store, defaults in
            store.visit(lessonID: "course-explorer-what-ai")
            store.complete(lessonID: "course-explorer-what-ai", score: 1)
            let restored = LocalStore(defaults: defaults, storageKey: "test")
            XCTAssertEqual(restored.data.lastVisitedLessonID, "course-explorer-what-ai")
            restored.clearLearningData()
            XCTAssertNil(restored.data.lastVisitedLessonID)
            XCTAssertTrue(restored.data.latestLessonScores.isEmpty)
        }
    }

    func testMigrationDiscardsInvalidLegacyScore() throws {
        let suite = "LocalStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        var data = AppUserData()
        data.completedLessonIDs = ["course-explorer-what-ai"]
        data.lessonScores = ["course-explorer-what-ai": Int.max]
        defaults.set(try JSONEncoder().encode(data), forKey: "test")
        let restored = LocalStore(defaults: defaults, storageKey: "test")
        XCTAssertFalse(restored.isCompleted("course-explorer-what-ai"))
        XCTAssertNil(restored.score(for: "course-explorer-what-ai"))
    }

    func testSavingOpenArticleAfterRefreshPersistsItsSnapshot() {
        withStore { store, defaults in
            store.updateArticles([])
            store.toggleBookmark(self.fixtureArticle)
            XCTAssertEqual(LocalStore(defaults: defaults, storageKey: "test").savedArticles.map(\.id), ["fixture"])
            store.toggleBookmark(self.fixtureArticle)
            XCTAssertTrue(store.savedArticles.isEmpty)
        }
    }

    private func withStore(_ body: (LocalStore, UserDefaults) -> Void) {
        let suite = "LocalStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        body(LocalStore(defaults: defaults, storageKey: "test"), defaults)
    }

    private var fixtureArticle: NewsArticle {
        .init(id: "fixture", title: "AI model launch", summary: "Test fixture", url: URL(string: "https://example.com/news")!,
              sourceName: "Test", publishedAt: .now, languageCode: "en", categories: ["AI"], isReviewed: false)
    }
}
