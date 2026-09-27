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
                PagePurposeView(core: settings.text("The announcement summary, publication date, source, and original article.", "这条公告的摘要、发布日期、来源与原文入口。"), purpose: settings.text("Understand what changed and use the original evidence to judge its relevance.", "理解发生了什么变化，结合原始证据判断其意义。"))
                Divider()
                Text(translations.translated(article.summary, language: settings.language)).font(.title3).lineSpacing(6)
                if settings.language == .simplifiedChinese {
                    NewsTranslationStatus()
                    if translations.hasTranslation(for: article) {
                        Text("设备端机器翻译 · 请结合原文核对专有名词、数字和技术结论。")
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
        .buttonStyle(.borderedProminent)
    }

    private var saveButton: some View {
        Button { store.toggleBookmark(article) } label: {
            Label(store.isBookmarked(article.id) ? settings.text("Saved", "已收藏") : settings.text("Save", "收藏"), systemImage: store.isBookmarked(article.id) ? "bookmark.fill" : "bookmark")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }

    private var evidenceNotice: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(settings.text("Evidence note", "证据说明"), systemImage: "info.circle.fill").font(.headline)
            Text(settings.text("This item is an official source announcement, selected automatically for AI news signals. AI Frontier has not independently verified the claims. Read the original and its evaluation conditions before drawing conclusions.", "此条目是按 AI 新闻信号自动筛选的官方公告。AI Frontier 未独立核实其中主张。得出结论前请阅读原文及评估条件。"))
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .padding()
        .background(AppTheme.paleTeal, in: RoundedRectangle(cornerRadius: 16))
    }
}
