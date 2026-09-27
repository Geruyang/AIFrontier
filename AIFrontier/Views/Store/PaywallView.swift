import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var purchases: PurchaseManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    Image(systemName: "sparkles.rectangle.stack.fill").font(.system(size: 62)).foregroundStyle(AppTheme.teal)
                    Text("AI Frontier Pro").font(.largeTitle.bold())
                    PagePurposeView(core: settings.text("Full-course access, subscription plans, and available trial terms.", "完整课程权限、订阅套餐与可用的试用条款。"), purpose: settings.text("Understand the benefits and renewal terms before choosing a plan.", "了解权益和续费规则，再选择适合自己的套餐。"))
                    Text(settings.text("Learn deeply. Keep up with the field.", "深入学习，持续跟踪前沿。"))
                        .font(.title3).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    VStack(alignment: .leading, spacing: 14) {
                        benefit("book.closed.fill", settings.text("All \(CurriculumCatalog.lessons.count) bilingual lessons and \(CurriculumCatalog.questionCount) questions", "全部 \(CurriculumCatalog.lessons.count) 节双语课程与 \(CurriculumCatalog.questionCount) 道题"))
                        benefit("books.vertical.fill", settings.text("Concrete examples and textbook / paper references", "具体案例与教材、论文来源"))
                        benefit("wifi.slash", settings.text("Offline access to bundled Pro lessons while entitlement is valid", "权益有效期内离线访问内置 Pro 课程"))
                    }
                    .padding().background(AppTheme.paleTeal, in: RoundedRectangle(cornerRadius: 18))

                    if purchases.products.isEmpty {
                        if case .unavailable = purchases.state {
                            ContentUnavailableView {
                                Label(settings.text("App Store unavailable", "App Store 暂不可用"), systemImage: "cart.badge.questionmark")
                            } description: {
                                Text(settings.text("Check your connection and try again. Your learning progress is still available offline.", "请检查网络后重试。你的学习进度仍可离线使用。"))
                            } actions: {
                                Button(settings.text("Try again", "重试")) { Task { await purchases.load() } }
                                    .buttonStyle(.borderedProminent)
                            }
                        } else {
                            ProgressView(settings.text("Loading App Store products…", "正在加载 App Store 商品…"))
                                .task { await purchases.load() }
                        }
                    } else {
                        ForEach(purchases.products, id: \.id) { product in productButton(product) }
                    }
                    Text(trialDisclosure).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Button(settings.text("Restore purchases", "恢复购买")) { Task { await purchases.restore() } }
                    Link(settings.text("Manage subscription", "管理订阅"), destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                    if let error = purchases.errorMessage { Text(error).font(.footnote).foregroundStyle(.red) }
                }
                .padding()
            }
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(settings.text("Close", "关闭")) { dismiss() } } }
        }
        .accessibilityIdentifier("paywall")
    }

    private var trialDisclosure: String {
        if purchases.isEligibleForTrial {
            settings.text("Eligible new subscribers receive 7 days free. The selected plan renews automatically at the displayed price unless cancelled at least 24 hours before the trial ends. Eligibility is determined by Apple and is available once per subscription group.", "符合条件的新订阅者可免费试用 7 天。若未在试用结束前至少 24 小时取消，所选套餐将按显示价格自动续费。资格由 Apple 判定，同一订阅组仅可享受一次。")
        } else {
            settings.text("The selected plan renews automatically at the displayed price until cancelled. Apple determines trial eligibility; a free trial may not be available for this account.", "所选套餐将按显示价格自动续费，直至取消。试用资格由 Apple 判定，此账户可能无法获得免费试用。")
        }
    }

    private func benefit(_ symbol: String, _ text: String) -> some View {
        HStack { Image(systemName: symbol).foregroundStyle(AppTheme.teal).frame(width: 28); Text(text); Spacer() }
    }

    private func productButton(_ product: Product) -> some View {
        Button {
            Task { await purchases.purchase(product) }
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(product.displayName).font(.headline)
                    if purchases.isEligibleForTrial { Text(settings.text("7 days free", "免费试用 7 天")).font(.caption).foregroundStyle(AppTheme.teal) }
                }
                Spacer()
                Text(product.displayPrice).font(.title3.bold())
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}
