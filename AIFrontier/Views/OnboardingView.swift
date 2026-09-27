import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var step = 0

    private let pages: [(String, BilingualText, BilingualText)] = [
        ("brain.head.profile", .init(en: "Learn AI clearly", zhHans: "清晰学习 AI"), .init(en: "Find your starting point. Build practical AI skills with 600 bilingual lessons.", zhHans: "从适合你的起点出发，通过 600 节双语课程，逐步掌握 AI。")),
        ("dot.radiowaves.left.and.right", .init(en: "Track the frontier", zhHans: "跟踪技术前沿"), .init(en: "Follow recent research and releases, with every story linked to its publisher.", zhHans: "关注新研究与新发布，每条资讯都能追溯原文。")),
        ("iphone.and.arrow.forward", .init(en: "Private by default", zhHans: "默认保护隐私"), .init(en: "No account needed. Your learning progress and bookmarks stay on this device.", zhHans: "无需账号，学习进度与收藏保存在你的设备上。"))
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
                    Text(pages[step].2.value(for: settings.language))
                        .font(.title3).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center).padding(.horizontal)
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
                    .buttonStyle(.borderedProminent).tint(AppTheme.action)
                    .controlSize(.large)
                    .accessibilityIdentifier("onboarding.continue")
                    Button(settings.text("Skip", "跳过")) { settings.hasCompletedOnboarding = true }
                        .foregroundStyle(.secondary)
                }
                .padding(24)
                .frame(minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(AppTheme.canvas)
        }
    }
}
