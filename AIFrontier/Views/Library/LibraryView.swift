import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: LocalStore
    @EnvironmentObject private var news: NewsService
    @EnvironmentObject private var translations: NewsTranslationStore

    private var completed: [Lesson] { CurriculumCatalog.lessons.filter { store.isCompleted($0.id) } }
    private var saved: [NewsArticle] { store.savedArticles }

    var body: some View {
        List {
            FrontierHero(eyebrow: settings.text("YOUR COLLECTION", "属于你的知识库"),
                         title: settings.text("Keep what moves you.", "让每次收获，都有迹可循。"),
                         subtitle: settings.text("Your progress, your next step, your best reads.", "记录进步，温故知新，收藏灵感。")) {
                HStack(spacing: 20) {
                    Label("\(completed.count)", systemImage: "checkmark.seal")
                        .accessibilityLabel(settings.text("\(completed.count) completed lessons", "已完成 \(completed.count) 节课程"))
                    Label("\(saved.count)", systemImage: "bookmark")
                        .accessibilityLabel(settings.text("\(saved.count) saved articles", "已收藏 \(saved.count) 篇资讯"))
                }.font(.title3.bold())
            }
            .listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
            Section(settings.text("Progress", "学习进度")) {
                HStack {
                    Label(settings.text("Completed lessons", "已完成课程"), systemImage: "checkmark.circle")
                    Spacer(); Text("\(completed.count) / \(CurriculumCatalog.lessons.count)").foregroundStyle(.secondary)
                }
                if completed.isEmpty {
                    Text(settings.text("Complete a lesson and its knowledge check to see it here.", "完成课程及知识测验后，会显示在这里。"))
                        .font(.subheadline).foregroundStyle(.secondary)
                } else {
                    ForEach(completed) { lesson in
                        NavigationLink(value: lesson) { Label(lesson.title.value(for: settings.language), systemImage: "checkmark.seal.fill") }
                    }
                }
            }
            Section(settings.text("Needs review", "待复习课程")) {
                let review = CurriculumCatalog.lessons.filter { store.needsReview($0) }
                if review.isEmpty {
                    Text(settings.text("Questions you miss will guide your review here.", "测验中有错题的课程会显示在这里，方便查漏补缺。"))
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                ForEach(review) { lesson in
                    NavigationLink(value: lesson) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(lesson.title.value(for: settings.language))
                            Text(settings.text("Latest score: ", "最近得分：") + "\(store.data.latestLessonScores[lesson.id] ?? 0)/\(lesson.questions.count)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }.accessibilityIdentifier("review.\(lesson.id)")
                }
            }
            Section(settings.text("Saved articles", "收藏资讯")) {
                if saved.isEmpty {
                    Text(settings.text("Save an article from Discover for quick access.", "在资讯页收藏文章后，可在这里快速访问。"))
                        .font(.subheadline).foregroundStyle(.secondary)
                } else {
                    ForEach(saved) { article in
                        NavigationLink(value: article) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(translations.translated(article.title, language: settings.language)).lineLimit(2)
                                if settings.language == .simplifiedChinese, translations.hasTranslation(for: article) {
                                    Text("译文").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden).background(AppTheme.canvas)
        .navigationTitle(settings.text("Library", "资料库"))
        .toolbar {
            NavigationLink { SettingsView() } label: { Label(settings.text("Settings & privacy", "设置与隐私"), systemImage: "gearshape") }
                .accessibilityIdentifier("library.settings")
        }
        .navigationDestination(for: Lesson.self) { LessonDetailView(lesson: $0) }
        .navigationDestination(for: NewsArticle.self) { ArticleDetailView(article: $0) }
    }
}
