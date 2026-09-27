import Foundation

@MainActor
final class LocalStore: ObservableObject {
    @Published private(set) var data: AppUserData

    private let defaults: UserDefaults
    private let storageKey: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard, storageKey: String = "app.userData") {
        self.defaults = defaults
        self.storageKey = storageKey
        if let encoded = defaults.data(forKey: storageKey),
           let decoded = try? decoder.decode(AppUserData.self, from: encoded) {
            data = decoded
        } else {
            data = AppUserData()
        }
    }

    func isCompleted(_ lessonID: String) -> Bool { data.completedLessonIDs.contains(lessonID) }
    func score(for lessonID: String) -> Int? { data.lessonScores[lessonID] }
    func isBookmarked(_ articleID: String) -> Bool { data.bookmarkedArticleIDs.contains(articleID) }

    func complete(lessonID: String, score: Int) {
        data.completedLessonIDs.insert(lessonID)
        data.lessonScores[lessonID] = max(score, data.lessonScores[lessonID] ?? 0)
        save()
    }

    func toggleBookmark(articleID: String) {
        if data.bookmarkedArticleIDs.contains(articleID) {
            data.bookmarkedArticleIDs.remove(articleID)
        } else {
            data.bookmarkedArticleIDs.insert(articleID)
        }
        save()
    }

    func updateArticles(_ articles: [NewsArticle], refreshedAt: Date = .now) {
        data.cachedArticles = Array(articles.prefix(200))
        data.lastNewsRefresh = refreshedAt
        save()
    }

    func clearLearningData() {
        let cached = data.cachedArticles
        let refresh = data.lastNewsRefresh
        data = AppUserData(cachedArticles: cached, lastNewsRefresh: refresh)
        save()
    }

    func resetAll() {
        data = AppUserData()
        save()
    }

    private func save() {
        guard let encoded = try? encoder.encode(data) else { return }
        defaults.set(encoded, forKey: storageKey)
    }
}

