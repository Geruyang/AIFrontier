import SwiftUI

struct DiscoverView: View {
    enum Filter: String, CaseIterable, Identifiable { case important, latest, saved; var id: String { rawValue } }

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var news: NewsService
    @EnvironmentObject private var store: LocalStore
    @EnvironmentObject private var translations: NewsTranslationStore
    @State private var filter: Filter = .important
    @State private var searchText = ""

    private var visibleArticles: [NewsArticle] {
        let candidates = filter == .saved ? store.savedArticles : news.articles
        let searchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = candidates.filter { article in
            let matches = searchText.isEmpty || article.title.localizedCaseInsensitiveContains(searchText) || article.summary.localizedCaseInsensitiveContains(searchText) || translations.translated(article.title, language: settings.language).localizedCaseInsensitiveContains(searchText) || translations.translated(article.summary, language: settings.language).localizedCaseInsensitiveContains(searchText)
            return matches
        }
        return filter == .important ? filtered.sorted {
            let a = NewsSelection.importance(of: $0), b = NewsSelection.importance(of: $1)
            return a == b ? $0.publishedAt > $1.publishedAt : a > b
        } : filtered
    }

    var body: some View {
        List {
            VStack(alignment: .leading, spacing: 8) {
                Text(filter == .saved ? settings.text("Saved articles · all dates", "收藏资讯 · 全部日期") : settings.text("Important AI news · past month", "重要 AI 新闻 · 近一个月")).font(.headline)
                PagePurposeView(core: settings.text("Important AI releases, research, safety, and industry announcements from the past month.", "近一个月的重要 AI 发布、研发、安全与行业公告。"), purpose: settings.text("Keep up with changes, find relevant developments, and read original sources for details.", "掌握最新动态，发现值得关注的进展，并通过原始来源深入了解。"))
                Text(settings.text("Official public announcements, selected using release, research, safety, and industry signals. Updates on every open or return; coverage depends on these sources.", "按发布、研究、安全和行业信号筛选官方公开公告。每次打开或返回时更新，覆盖范围取决于这些来源。"))
                    .font(.footnote).foregroundStyle(.secondary)
                if let date = news.lastRefresh {
                    Text(settings.text("Last successful check: ", "上次成功检查：") + date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption).foregroundStyle(.secondary)
                }
                if news.state == .loading { ProgressView(settings.text("Checking public sources…", "正在检查公开来源…")) }
            }
            sourceStatus
            if settings.language == .simplifiedChinese { NewsTranslationStatus() }
            Picker(settings.text("Filter", "筛选"), selection: $filter) {
                Text(settings.text("Important", "重要")).tag(Filter.important)
                Text(settings.text("Latest", "最新")).tag(Filter.latest)
                Text(settings.text("Saved", "已收藏")).tag(Filter.saved)
            }
            .pickerStyle(.segmented)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            if visibleArticles.isEmpty {
                EmptyStateView(symbol: "newspaper", title: settings.text("No matching news", "暂无符合条件的新闻"), message: filter == .saved ? settings.text("Save articles to keep them here, or try another search.", "收藏的文章会保留在这里，也可尝试更换搜索词。") : settings.text("Only significant AI announcements dated within the past month appear here. Pull to refresh or try another filter.", "这里只显示近一个月的重要 AI 公告。可下拉刷新或更换筛选条件。"))
                    .listRowBackground(Color.clear)
            } else {
                ForEach(visibleArticles) { article in
                    NavigationLink(value: article) { ArticleRow(article: article) }
                        .swipeActions(edge: .trailing) {
                            Button { store.toggleBookmark(article) } label: {
                                Label(settings.text("Save", "收藏"), systemImage: store.isBookmarked(article.id) ? "bookmark.slash" : "bookmark")
                            }
                            .tint(AppTheme.teal)
                        }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(settings.text("Discover", "资讯"))
        .searchable(text: $searchText, prompt: settings.text("Search fetched articles", "搜索已获取资讯"))
        .refreshable { await news.refresh() }
        .navigationDestination(for: NewsArticle.self) { ArticleDetailView(article: $0) }
        .accessibilityIdentifier("discover.list")
    }

    @ViewBuilder private var sourceStatus: some View {
        if case .failed = news.state {
            Label(settings.text("Update failed. Only still-current cached news is shown; it may miss the latest announcements. Pull to retry.", "更新失败。仅显示未过期的缓存新闻，可能缺少最新公告。可下拉重试。"), systemImage: "wifi.exclamationmark")
                .font(.footnote).foregroundStyle(.secondary)
        } else if !news.sourceFailures.isEmpty {
            Label(settings.text("Unavailable sources: ", "暂不可用来源：") + news.sourceFailures.joined(separator: ", "), systemImage: "exclamationmark.triangle")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }
}

private struct ArticleRow: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: LocalStore
    @EnvironmentObject private var translations: NewsTranslationStore
    let article: NewsArticle

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(article.sourceName).font(.caption.bold()).foregroundStyle(AppTheme.teal)
                Spacer()
                if store.isBookmarked(article.id) { Image(systemName: "bookmark.fill").foregroundStyle(AppTheme.teal) }
            }
            Text(translations.translated(article.title, language: settings.language)).font(.headline).lineLimit(3)
            Text(translations.translated(article.summary, language: settings.language)).font(.subheadline).foregroundStyle(.secondary).lineLimit(3)
            if settings.language == .simplifiedChinese, translations.hasTranslation(for: article) {
                Text("设备端机器翻译").font(.caption).foregroundStyle(AppTheme.teal)
            }
            Text(article.publishedAt, format: .dateTime.month().day().year()).font(.caption).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 5)
        .accessibilityIdentifier("article.\(article.id)")
    }
}
