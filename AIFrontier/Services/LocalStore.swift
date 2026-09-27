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
        // Validate persisted scores before arithmetic; older builds accepted arbitrary integers.
        for lesson in CurriculumCatalog.lessons {
            if let score = data.lessonScores[lesson.id], !(0...lesson.questions.count).contains(score) {
                data.lessonScores.removeValue(forKey: lesson.id)
            }
            if let score = data.latestLessonScores[lesson.id], !(0...lesson.questions.count).contains(score) {
                data.latestLessonScores.removeValue(forKey: lesson.id)
            }
            if data.completedLessonIDs.contains(lesson.id),
               (data.lessonScores[lesson.id] ?? 0) * 3 < lesson.questions.count * 2 {
                data.completedLessonIDs.remove(lesson.id)
            }
        }
    }

    var savedArticles: [NewsArticle] {
        data.savedArticles.filter { data.bookmarkedArticleIDs.contains($0.id) }.sorted {
            $0.publishedAt == $1.publishedAt ? $0.id < $1.id : $0.publishedAt > $1.publishedAt
        }
    }

    func needsReview(_ lesson: Lesson) -> Bool {
        guard let score = data.latestLessonScores[lesson.id] else { return false }
        return score < lesson.questions.count
    }

    func visit(lessonID: String) {
        guard data.lastVisitedLessonID != lessonID else { return }
        data.lastVisitedLessonID = lessonID
        save()
    }

    func isCompleted(_ lessonID: String) -> Bool { data.completedLessonIDs.contains(lessonID) }
    func score(for lessonID: String) -> Int? { data.lessonScores[lessonID] }
    func isBookmarked(_ articleID: String) -> Bool { data.bookmarkedArticleIDs.contains(articleID) }

    func complete(lessonID: String, score: Int) {
        guard let lesson = CurriculumCatalog.lessons.first(where: { $0.id == lessonID }),
              !lesson.questions.isEmpty, (0...lesson.questions.count).contains(score) else { return }
        if score * 3 >= lesson.questions.count * 2 { data.completedLessonIDs.insert(lessonID) }
        data.lessonScores[lessonID] = max(score, data.lessonScores[lessonID] ?? 0)
        data.latestLessonScores[lessonID] = score
        save()
    }

    func toggleBookmark(_ article: NewsArticle) {
        let removing = isBookmarked(article.id)
        toggleBookmark(articleID: article.id)
        if !removing {
            // The article can outlive the feed cache while its detail screen is open.
            data.savedArticles.removeAll { $0.id == article.id }
            data.savedArticles.append(article)
            save()
        }
    }

    func toggleBookmark(articleID: String) {
        if data.bookmarkedArticleIDs.contains(articleID) {
            data.bookmarkedArticleIDs.remove(articleID)
            data.savedArticles.removeAll { $0.id == articleID }
        } else {
            data.bookmarkedArticleIDs.insert(articleID)
            if let article = data.cachedArticles.first(where: { $0.id == articleID }) {
                data.savedArticles.removeAll { $0.id == articleID }
                data.savedArticles.append(article)
            }
        }
        save()
    }

    func updateArticles(_ articles: [NewsArticle], refreshedAt: Date = .now) {
        data.cachedArticles = Array(articles.prefix(200))
        data.lastNewsRefresh = refreshedAt
        save()
    }

    func clearLearningData() {
        data.completedLessonIDs = []
        data.lessonScores = [:]
        data.latestLessonScores = [:]
        data.lastVisitedLessonID = nil
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

