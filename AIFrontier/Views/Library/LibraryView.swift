import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: LocalStore
    @EnvironmentObject private var news: NewsService
    @EnvironmentObject private var translations: NewsTranslationStore

    private var completed: [Lesson] { CurriculumCatalog.lessons.filter { store.isCompleted($0.id) } }
    private var saved: [NewsArticle] { news.articles.filter { store.isBookmarked($0.id) } }

    var body: some View {
        List {
            PagePurposeView(core: settings.text("Completed lessons, quiz progress, saved news, and settings.", "已完成课程、测验进度、收藏资讯与设置入口。"), purpose: settings.text("Return to useful material, review what you learned, and continue your learning path.", "快速找回有用内容，复习已学知识并继续学习。"))
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
                                    Text("设备端机器翻译").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            Section {
                NavigationLink { SettingsView() } label: { Label(settings.text("Settings & privacy", "设置与隐私"), systemImage: "gearshape") }
                    .accessibilityIdentifier("library.settings")
            }
        }
        .navigationTitle(settings.text("Library", "资料库"))
        .navigationDestination(for: Lesson.self) { LessonDetailView(lesson: $0) }
        .navigationDestination(for: NewsArticle.self) { ArticleDetailView(article: $0) }
    }
}
