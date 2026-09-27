import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var step = 0

    private let pages: [(String, BilingualText, BilingualText, BilingualText)] = [
        ("brain.head.profile", .init(en: "Learn AI clearly", zhHans: "清晰学习 AI"), .init(en: "\(CurriculumCatalog.lessons.count) bilingual lessons and \(CurriculumCatalog.questionCount) questions at Beginner, Fundamentals, and Advanced levels, with examples and references.", zhHans: "入门、基础、进阶共 \(CurriculumCatalog.lessons.count) 节双语课程与 \(CurriculumCatalog.questionCount) 道习题，配有例子和来源。"), .init(en: "Find your starting point and learn to understand and apply AI step by step.", zhHans: "找到适合自己的起点，逐步学会理解和应用 AI。")),
        ("dot.radiowaves.left.and.right", .init(en: "Track the frontier", zhHans: "跟踪技术前沿"), .init(en: "Important AI announcements from the past month, refreshed whenever you open or return to the app.", zhHans: "近一个月的重要 AI 公告，每次打开或返回应用时刷新。"), .init(en: "Keep up with developments and discover topics worth investigating.", zhHans: "掌握最新动态，发现值得深入了解的技术方向。")),
        ("iphone.and.arrow.forward", .init(en: "Private by default", zhHans: "默认保护隐私"), .init(en: "No account or app-owned cloud server. Progress and bookmarks stay on this device.", zhHans: "无需账号，不使用自有云服务器；进度和收藏保存在本机。"), .init(en: "Learn with control over your local progress and saved material.", zhHans: "自主掌握本地学习记录与收藏，安心学习。"))
    ]

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 20)
                    Image(systemName: pages[step].0)
                        .font(.system(size: 72, weight: .light))
                        .foregroundStyle(AppTheme.teal)
                        .symbolEffect(.pulse, value: step)
                    Text(pages[step].1.value(for: settings.language))
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    PagePurposeView(core: pages[step].2.value(for: settings.language), purpose: pages[step].3.value(for: settings.language))
                        .padding(.horizontal)
                    Spacer(minLength: 20)
                    Picker(settings.text("Language", "语言"), selection: $settings.language) {
                        ForEach(AppLanguage.allCases) { language in Text(language.displayName).tag(language) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    Button(step == pages.count - 1 ? settings.text("Start learning", "开始学习") : settings.text("Continue", "继续")) {
                        if step < pages.count - 1 { withAnimation { step += 1 } }
                        else { settings.hasCompletedOnboarding = true }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityIdentifier("onboarding.continue")
                    Button(settings.text("Skip", "跳过")) { settings.hasCompletedOnboarding = true }
                        .foregroundStyle(.secondary)
                }
                .padding(24)
                .frame(minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}
