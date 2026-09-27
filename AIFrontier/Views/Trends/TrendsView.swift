import Charts
import SwiftUI

struct TrendsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var news: NewsService

    private var topics: [TrendTopic] { TrendAnalyzer.topics(from: news.articles) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PagePurposeView(core: settings.text("AI topic mentions in the news fetched during the past month.", "已获取的近一个月资讯中，各 AI 主题的提及情况。"), purpose: settings.text("Spot topics to investigate and compare their coverage in the current news sample.", "发现值得深入研究的方向，比较当前资讯样本对各主题的关注情况。"))
                scopeNotice
                if topics.isEmpty {
                    EmptyStateView(symbol: "chart.bar", title: settings.text("Not enough local data", "本地数据不足"), message: settings.text("Refresh Discover to build a topic view from fetched items.", "请在资讯页刷新，以便根据已获取内容生成主题视图。"))
                } else {
                    SectionHeader(settings.text("Topic signals", "主题信号"), subtitle: settings.text("Mentions in the current on-device article cache", "当前本机资讯缓存中的提及次数"))
                    Chart(topics) { topic in
                        BarMark(x: .value("Count", topic.count), y: .value("Topic", topic.label.value(for: settings.language)))
                            .foregroundStyle(AppTheme.teal.gradient)
                            .annotation(position: .trailing) { Text("\(topic.count)").font(.caption.bold()) }
                    }
                    .frame(height: CGFloat(max(240, topics.count * 52)))
                    .accessibilityIdentifier("trends.chart")
                    .accessibilityLabel(settings.text("Topic signals", "主题信号"))
                    .accessibilityValue(topics.map { "\($0.label.value(for: settings.language)): \($0.count)" }.joined(separator: ", "))
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(settings.text("How to interpret this", "如何解读"))
                        insightRow("arrow.triangle.branch", settings.text("A larger bar means more matching items in this cache, not greater importance.", "更长的柱形只表示缓存中匹配条目更多，并不表示更重要。"))
                        insightRow("calendar", settings.text("Source availability and refresh time change the sample.", "来源可用性和刷新时间会改变样本。"))
                        insightRow("checkmark.seal", settings.text("Open original sources before making a technical or business decision.", "作出技术或商业决策前，请打开原始来源核验。"))
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(settings.text("Trends", "趋势"))
    }

    private var scopeNotice: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(settings.text("Local sample", "本地样本"), systemImage: "iphone")
                .font(.headline).foregroundStyle(AppTheme.teal)
            Text(settings.text("This view analyzes only recent articles fetched on this device. It is not a measurement of the entire AI industry.", "此页面只分析本机获取的近期资讯，并不代表整个 AI 行业。"))
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .padding().background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    private func insightRow(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top) { Image(systemName: symbol).foregroundStyle(AppTheme.teal).frame(width: 28); Text(text); Spacer() }
    }
}
