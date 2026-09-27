import Charts
import SwiftUI

struct TrendsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var news: NewsService

    private var topics: [TrendTopic] { TrendAnalyzer.topics(from: news.articles) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                FrontierHero(eyebrow: settings.text("THE BIGGER PICTURE", "看见趋势"),
                             title: settings.text("Connect the dots.", "从动态中，发现方向。"),
                             subtitle: settings.text("Explore the ideas shaping recent AI news.", "沿着热门主题，探索近期 AI 动态。")) {
                    HStack(spacing: 18) {
                        Label(settings.text("\(news.articles.count) stories", "\(news.articles.count) 篇资讯"), systemImage: "newspaper")
                        Label(settings.text("\(topics.count) topics", "\(topics.count) 个主题"), systemImage: "circle.hexagongrid")
                    }.font(.caption.weight(.medium))
                }
                if topics.isEmpty {
                    EmptyStateView(symbol: "chart.bar", title: settings.text("No trends yet", "暂无主题趋势"), message: settings.text("Explore Discover to find the latest stories.", "前往资讯页，发现最新动态。"))
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        SectionHeader(settings.text("On the radar", "值得关注"), subtitle: settings.text("Topic mentions in \(news.articles.count) recent stories", "\(news.articles.count) 篇近期资讯中的主题提及次数"))
                        Chart(topics) { topic in
                            BarMark(x: .value("Count", topic.count), y: .value("Topic", topic.label.value(for: settings.language)))
                                .cornerRadius(5)
                                .foregroundStyle(LinearGradient(colors: [AppTheme.teal, AppTheme.violet], startPoint: .leading, endPoint: .trailing))
                                .annotation(position: .trailing) { Text("\(topic.count)").font(.caption.bold()) }
                        }
                        .chartXAxis(.hidden)
                        .frame(height: CGFloat(max(180, topics.count * 48)))
                        .padding(.trailing, 24)
                        .accessibilityIdentifier("trends.chart")
                        .accessibilityLabel(settings.text("Topic signals", "主题信号"))
                        .accessibilityValue(topics.map { "\($0.label.value(for: settings.language)): \($0.count)" }.joined(separator: ", "))
                        Text(settings.text("A snapshot of these sources, not the entire industry.", "仅反映这些来源的近期内容，不代表整个行业。"))
                            .font(.caption).foregroundStyle(.secondary)
                    }.modifier(SurfaceCard())
                    SectionHeader(settings.text("Follow a topic", "沿主题继续探索"))
                    ForEach(topics) { topic in
                        NavigationLink {
                            TopicArticlesView(topic: topic)
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "arrow.up.right").font(.headline).foregroundStyle(AppTheme.violet)
                                    .frame(width: 40, height: 40).background(AppTheme.violet.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
                                Text(topic.label.value(for: settings.language)).font(.headline).foregroundStyle(.primary)
                                Spacer()
                                Text("\(topic.count)").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
                                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                            }.modifier(SurfaceCard())
                        }.buttonStyle(.plain).accessibilityIdentifier("trend.\(topic.id)")
                    }
                }
            }.padding(20)
        }
        .background(AppTheme.canvas)
        .navigationTitle(settings.text("Trends", "趋势"))
    }
}

private struct TopicArticlesView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var news: NewsService
    @EnvironmentObject private var translations: NewsTranslationStore
    let topic: TrendTopic

    // Recompute membership after a refresh rather than retaining stale article IDs.
    private var articles: [NewsArticle] {
        let ids = Set(TrendAnalyzer.topics(from: news.articles).first { $0.id == topic.id }?.articleIDs ?? [])
        return news.articles.filter { ids.contains($0.id) }
    }

    var body: some View {
        List {
            if articles.isEmpty {
                EmptyStateView(symbol: "newspaper", title: settings.text("No recent stories", "暂无近期资讯"), message: settings.text("New stories will appear here when available.", "有新资讯时会显示在这里。"))
            }
            ForEach(articles) { article in
                NavigationLink { ArticleDetailView(article: article) } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(article.sourceName).font(.caption.bold()).foregroundStyle(AppTheme.teal)
                        Text(translations.translated(article.title, language: settings.language)).font(.headline)
                        Text(article.publishedAt, format: .dateTime.month().day()).font(.caption).foregroundStyle(.secondary)
                    }.padding(.vertical, 8)
                }
            }
        }
        .navigationTitle(topic.label.value(for: settings.language))
        .navigationBarTitleDisplayMode(.inline)
    }
}
