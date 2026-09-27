import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: LocalStore
    @EnvironmentObject private var purchases: PurchaseManager
    @State private var confirmReset = false

    var body: some View {
        Form {
            PagePurposeView(core: settings.text("Language, preferred learning level, access, and local data controls.", "语言、偏好学习级别、访问权限与本地数据管理。"), purpose: settings.text("Adapt the app to your learning habits and control your data and subscription.", "按学习习惯调整应用，管理自己的数据与订阅。"))
            Section(settings.text("Language", "语言")) {
                Picker(settings.text("App language", "应用语言"), selection: $settings.language) {
                    ForEach(AppLanguage.allCases) { Text($0.displayName).tag($0) }
                }
            }
            Section(settings.text("Learning level", "学习级别")) {
                Picker(settings.text("Preferred level", "偏好级别"), selection: $settings.preferredLevel) {
                    Text(settings.text("No filter", "不过滤")).tag(AudienceLevel?.none)
                    ForEach(AudienceLevel.allCases) { level in Text(level.label.value(for: settings.language)).tag(AudienceLevel?.some(level)) }
                }
                if let level = settings.preferredLevel {
                    PagePurposeView(core: level.coreContent.value(for: settings.language), purpose: level.purpose.value(for: settings.language))
                }
            }
            Section(settings.text("Subscription", "订阅")) {
                HStack { Text(settings.text("Access", "访问权限")); Spacer(); Text(EntitlementPolicy.developerAccess ? settings.text("Developer · all content", "开发者 · 全部内容") : (purchases.hasPro ? "Pro" : "Free")).foregroundStyle(.secondary) }
                if !EntitlementPolicy.developerAccess {
                    Button(settings.text("Restore purchases", "恢复购买")) { Task { await purchases.restore() } }
                    Link(settings.text("Manage subscription", "管理订阅"), destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                }
            }
            Section(settings.text("Data & privacy", "数据与隐私")) {
                NavigationLink(settings.text("Privacy summary", "隐私摘要")) { PrivacyView() }
                NavigationLink(settings.text("Terms of use", "使用条款")) { TermsView() }
                Button(settings.text("Delete local learning data", "删除本地学习数据"), role: .destructive) { confirmReset = true }
            }
            Section(settings.text("About", "关于")) {
                LabeledContent(settings.text("Version", "版本"), value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                Text(settings.text("AI Frontier does not operate an account server, content database, cloud model, or analytics service. Public feeds and Apple services remain external dependencies.", "AI Frontier 不运营账号服务器、内容数据库、云模型或分析服务。公开订阅源与 Apple 服务仍属于外部依赖。"))
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle(settings.text("Settings", "设置"))
        .alert(settings.text("Delete local learning data?", "删除本地学习数据？"), isPresented: $confirmReset) {
            Button(settings.text("Delete", "删除"), role: .destructive) { store.clearLearningData() }
            Button(settings.text("Cancel", "取消"), role: .cancel) {}
        } message: {
            Text(settings.text("Completed lessons, scores, and saved items will be removed from this device.", "本机上的课程进度、分数和收藏将被删除。"))
        }
    }
}

private struct PrivacyView: View {
    @EnvironmentObject private var settings: AppSettings
    var body: some View {
        List {
            PagePurposeView(core: settings.text("Where app data stays and what public sources and Apple handle.", "应用数据的保存位置，以及公开来源和 Apple 处理的信息。"), purpose: settings.text("Understand how your information is used and make informed privacy choices.", "了解信息如何被使用，作出知情的隐私选择。"))
            disclosure("iphone", settings.text("Stored on device", "保存在本机"), settings.text("Language, learning progress, quiz scores, bookmarks, article cache, and machine translations. English news is translated on device using Apple Translation; a language-pack download may be required.", "语言、学习进度、测验分数、收藏、资讯缓存和机器译文。英文资讯通过 Apple 翻译在设备端处理，首次使用可能需要下载语言包。"))
            disclosure("network", settings.text("Sent to public sources", "发送至公开来源"), settings.text("Normal network request information, including IP address, may be visible to the source when you refresh or open an article.", "刷新或打开文章时，来源方可能看到包括 IP 地址在内的常规网络请求信息。"))
            disclosure("apple.logo", settings.text("Handled by Apple", "由 Apple 处理"), settings.text("App downloads, purchases, trial eligibility, refunds, and subscription management.", "应用下载、购买、试用资格、退款和订阅管理。"))
            disclosure("hand.raised", settings.text("Not collected by us", "我们不收集"), settings.text("No account, advertising identifier, precise location, contacts, or cross-app tracking.", "不收集账号、广告标识符、精确位置、通讯录，也不进行跨应用跟踪。"))
        }
        .navigationTitle(settings.text("Privacy summary", "隐私摘要"))
    }

    private func disclosure(_ icon: String, _ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) { Label(title, systemImage: icon).font(.headline); Text(body).font(.subheadline).foregroundStyle(.secondary) }.padding(.vertical, 4)
    }
}

private struct TermsView: View {
    @EnvironmentObject private var settings: AppSettings
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PagePurposeView(core: settings.text("Educational use, source availability, and subscription terms.", "教育用途、来源可用性与订阅条款。"), purpose: settings.text("Understand the conditions for using the app and managing a subscription.", "了解应用使用条件与订阅管理规则。"))
                Text(settings.text("Educational use", "教育用途")).font(.title2.bold())
                Text(settings.text("Content is for learning and general information. It is not professional, medical, legal, or investment advice.", "内容用于学习和一般信息，不构成专业、医疗、法律或投资建议。"))
                Text(settings.text("Sources and availability", "来源与可用性")).font(.title2.bold())
                Text(settings.text("Public feeds belong to their respective publishers. Availability, accuracy, and licensing can change. The app may show cached or bundled content when a source is unavailable.", "公开订阅源归各发布者所有，其可用性、准确性和许可可能变化。来源不可用时，应用可能显示缓存或内置内容。"))
                Text(settings.text("Subscriptions", "订阅")).font(.title2.bold())
                Text(settings.text("Payment is charged to the Apple Account after purchase confirmation. Eligible introductory trials convert to the selected paid plan unless cancelled. Manage or cancel in Apple account settings.", "确认购买后，费用由 Apple 账户支付。符合资格的入门试用若未取消，将转为所选付费套餐。可在 Apple 账户设置中管理或取消。"))
            }.padding()
        }
        .navigationTitle(settings.text("Terms of use", "使用条款"))
    }
}
