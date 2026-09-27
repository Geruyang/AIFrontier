import SwiftUI

struct DiscoverView: View {
    enum Filter: String, CaseIterable, Identifiable { case important, latest, saved; var id: String { rawValue } }

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var news: NewsService
    @EnvironmentObject private var store: LocalStore
    @EnvironmentObject private var translations: NewsTranslationStore
    @State private var filter: Filter = .important
    @State private var searchText = ""
    @State private var showSources = false

    private var visibleArticles: [NewsArticle] {
        let candidates = filter == .saved ? store.savedArticles : news.articles
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = candidates.filter { article in
            query.isEmpty || article.sourceName.localizedCaseInsensitiveContains(query)
                || article.title.localizedCaseInsensitiveContains(query) || article.summary.localizedCaseInsensitiveContains(query)
                || translations.translated(article.title, language: settings.language).localizedCaseInsensitiveContains(query)
                || translations.translated(article.summary, language: settings.language).localizedCaseInsensitiveContains(query)
        }
        return filtered.sorted {
            if filter == .important {
                let a = NewsSelection.importance(of: $0), b = NewsSelection.importance(of: $1)
                if a != b { return a > b }
            }
            if $0.publishedAt != $1.publishedAt { return $0.publishedAt > $1.publishedAt }
            return $0.id < $1.id
        }
    }

    var body: some View {
        let articles = visibleArticles
        List {
            FrontierHero(eyebrow: settings.text("THE AI BRIEF", "AI 前沿速览"),
                         title: settings.text("Stay one idea ahead.", "下一步，正在发生。"),
                         subtitle: settings.text("Research. Releases. Real possibilities.", "新研究、新发布、新可能。")) {
                Label(filter == .saved ? settings.text("Saved articles · all dates", "收藏资讯 · 全部日期") : settings.text("Important AI news · past month", "重要 AI 新闻 · 近一个月"), systemImage: "sparkle")
                    .font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.85))
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 12, trailing: 0))
            .listRowBackground(Color.clear).listRowSeparator(.hidden)

            if filter != .saved, case .failed = news.state {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "wifi.exclamationmark").foregroundStyle(AppTheme.teal)
                    Text(settings.text("Couldn't update. Showing available news.", "暂时无法更新，正在显示已有资讯。"))
                        .font(.subheadline)
                    Spacer(minLength: 0)
                    Button(settings.text("Retry", "重试")) { Task { await news.refresh() } }
                        .font(.subheadline.bold()).frame(minHeight: 44)
                }.listRowBackground(AppTheme.surface)
            }

            Picker(settings.text("Filter", "筛选"), selection: $filter) {
                Text(settings.text("Important", "重要")).tag(Filter.important)
                Text(settings.text("Latest", "最新")).tag(Filter.latest)
                Text(settings.text("Saved", "已收藏")).tag(Filter.saved)
            }
            .pickerStyle(.segmented)
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 16, trailing: 0))
            .listRowBackground(Color.clear).listRowSeparator(.hidden)

            if articles.isEmpty {
                if news.state == .loading, filter != .saved {
                    ProgressView().frame(maxWidth: .infinity).padding(32)
                        .accessibilityLabel(settings.text("Loading news", "正在加载资讯"))
                        .listRowBackground(Color.clear)
                } else {
                    EmptyStateView(symbol: filter == .saved ? "bookmark" : "newspaper", title: settings.text("No matching news", "暂无符合条件的新闻"), message: filter == .saved ? settings.text("Keep a good read. Save an article to find it here.", "把值得一读的文章收藏在这里。") : settings.text("Pull to refresh or try another search.", "下拉刷新，或尝试其他搜索词。"))
                        .listRowBackground(Color.clear)
                }
            } else {
                ForEach(Array(articles.enumerated()), id: \.element.id) { index, article in
                    NavigationLink(value: article) {
                        ArticleRow(article: article, featured: index == 0 && filter != .saved && searchText.isEmpty)
                    }
                    .listRowBackground(RoundedRectangle(cornerRadius: 22).fill(AppTheme.surface).padding(.vertical, 4))
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing) {
                        Button { store.toggleBookmark(article) } label: {
                            Label(store.isBookmarked(article.id) ? settings.text("Unsave", "取消收藏") : settings.text("Save", "收藏"), systemImage: store.isBookmarked(article.id) ? "bookmark.slash" : "bookmark")
                        }.tint(AppTheme.teal)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden).background(AppTheme.canvas)
        .navigationTitle(settings.text("Discover", "资讯"))
        .searchable(text: $searchText, prompt: settings.text("Search news or sources", "搜索资讯或来源"))
        .refreshable { await news.refresh() }
        .toolbar {
            Button { showSources = true } label: {
                Label(settings.text("News sources", "新闻来源"), systemImage: "globe")
            }.accessibilityIdentifier("discover.sources")
        }
        .sheet(isPresented: $showSources) {
            NavigationStack {
                NewsSourcesView()
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button(settings.text("Done", "完成")) { showSources = false } } }
            }
        }
        .navigationDestination(for: NewsArticle.self) { ArticleDetailView(article: $0) }
        .accessibilityIdentifier("discover.list")
    }
}

private struct ArticleRow: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: LocalStore
    @EnvironmentObject private var translations: NewsTranslationStore
    let article: NewsArticle
    let featured: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(article.sourceName).font(.caption.bold()).foregroundStyle(AppTheme.teal)
                Spacer(minLength: 4)
                if store.isBookmarked(article.id) { Image(systemName: "bookmark.fill").foregroundStyle(AppTheme.teal) }
            }
            if featured {
                Label(settings.text("IN FOCUS", "焦点"), systemImage: "sparkles")
                    .font(.caption2.bold()).tracking(1.6).foregroundStyle(AppTheme.violet)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(AppTheme.violet.opacity(0.09), in: Capsule())
            }
            Text(translations.translated(article.title, language: settings.language))
                .font(featured ? .system(.title2, design: .rounded, weight: .bold) : .headline)
                .lineLimit(featured ? 5 : 3)
            Text(translations.translated(article.summary, language: settings.language))
                .font(.subheadline).foregroundStyle(.secondary).lineLimit(featured ? 3 : 2)
            HStack(spacing: 8) {
                Text(article.publishedAt, format: .dateTime.month().day().year())
                if settings.language == .simplifiedChinese, translations.hasTranslation(for: article) { Text("· 译文") }
            }.font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, featured ? 14 : 10)
        .accessibilityIdentifier("article.\(article.id)")
    }
}

struct NewsSourcesView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var news: NewsService

    var body: some View {
        List {
            Section {
                Text(settings.text("Direct from publishers", "直达发布者"))
                    .font(.title2.bold())
                Text(settings.text("Follow AI announcements and research from the publishers below. Open any story to read its original source.", "关注以下发布者的 AI 动态与研究，每条资讯均可打开原文。"))
                    .font(.subheadline).foregroundStyle(.secondary)
                if let date = news.lastRefresh {
                    LabeledContent(settings.text("Last updated", "最近更新")) { Text(date, format: .dateTime.month().day().hour().minute()) }
                }
            }
            Section(settings.text("Publishers", "发布者")) {
                ForEach(NewsSource.defaults) { source in
                    Link(destination: source.homepageURL) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(source.name).font(.headline)
                                Text(source.homepageURL.host ?? "").font(.caption).foregroundStyle(.secondary)
                                if news.sourceFailures.contains(source.name) {
                                    Text(settings.text("Temporarily unavailable", "暂时无法连接")).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right").font(.caption)
                        }.padding(.vertical, 4)
                    }.foregroundStyle(.primary)
                }
            }
            Section(settings.text("Updates", "资讯更新")) {
                Text(settings.text("Checks every 5 minutes while the app is active. Background updates depend on iOS, network access, and your Background App Refresh settings.", "使用时每 5 分钟检查更新。后台更新由 iOS 调度，取决于网络及系统的“后台 App 刷新”设置。"))
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle(settings.text("News sources", "新闻来源"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
