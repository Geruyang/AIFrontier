import SwiftUI

struct ArticleDetailView: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: LocalStore
    @EnvironmentObject private var translations: NewsTranslationStore
    let article: NewsArticle

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(article.sourceName).font(.subheadline.bold()).foregroundStyle(AppTheme.teal)
                }
                Text(translations.translated(article.title, language: settings.language)).font(.largeTitle.bold()).foregroundStyle(AppTheme.navy)
                Text(article.publishedAt, format: .dateTime.month().day().year()).font(.subheadline).foregroundStyle(.secondary)
                Divider()
                Text(translations.translated(article.summary, language: settings.language)).font(.title3).lineSpacing(6)
                if settings.language == .simplifiedChinese {
                    if !translations.hasTranslation(for: article) { NewsTranslationStatus() }
                    if translations.hasTranslation(for: article) {
                        Text("译文 · 技术细节请以原文为准。")
                            .font(.footnote).foregroundStyle(.secondary)
                        DisclosureGroup("查看英文标题与摘要") {
                            VStack(alignment: .leading, spacing: 10) { Text(article.title).bold(); Text(article.summary) }
                        }
                    }
                }
                evidenceNotice
                articleActions
            }
            .padding()
        }
        .background(AppTheme.canvas)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var articleActions: some View {
        ViewThatFits(in: .horizontal) {
            HStack { openOriginalButton; saveButton }
            VStack(spacing: 12) { openOriginalButton; saveButton }
        }
        .controlSize(.large)
    }

    private var openOriginalButton: some View {
        Button { openURL(article.url) } label: {
            Label(settings.text("Open original", "打开原文"), systemImage: "arrow.up.right.square")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent).tint(AppTheme.action)
    }

    private var saveButton: some View {
        Button { store.toggleBookmark(article) } label: {
            Label(store.isBookmarked(article.id) ? settings.text("Saved", "已收藏") : settings.text("Save", "收藏"), systemImage: store.isBookmarked(article.id) ? "bookmark.fill" : "bookmark")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }

    private var evidenceNotice: some View {
        DisclosureGroup(settings.text("Evidence note", "证据说明")) {
            Text(settings.text("Read the publisher’s original article for the full context and evaluation details. Publisher claims have not been independently verified by AI Frontier.", "完整背景与评估细节请查阅发布者原文。AI Frontier 未独立核实发布者的主张。"))
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .padding()
        .background(AppTheme.paleTeal, in: RoundedRectangle(cornerRadius: 16))
    }
}
