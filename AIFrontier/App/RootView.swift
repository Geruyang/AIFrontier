import SwiftUI

struct RootView: View {
    @EnvironmentObject private var settings: AppSettings

    private var bypassOnboarding: Bool {
        let arguments = ProcessInfo.processInfo.arguments
        return arguments.contains("-ui-testing") || arguments.contains("-storekit-ui-testing")
    }

    var body: some View {
        Group {
            if settings.hasCompletedOnboarding || bypassOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .environment(\.locale, Locale(identifier: settings.language.rawValue))
        .tint(.teal)
    }
}

struct MainTabView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var news: NewsService

    var body: some View {
        TabView {
            NavigationStack { LearnView() }
                .tabItem {
                    Label(settings.text("Learn", "学习"), systemImage: "book.pages")
                        .accessibilityIdentifier("tab.learn")
                }

            NavigationStack { DiscoverView() }
                .tabItem {
                    Label(settings.text("Discover", "资讯"), systemImage: "safari")
                        .accessibilityIdentifier("tab.discover")
                }

            NavigationStack { TrendsView() }
                .tabItem {
                    Label(settings.text("Trends", "趋势"), systemImage: "chart.bar.xaxis")
                        .accessibilityIdentifier("tab.trends")
                }

            NavigationStack { LibraryView() }
                .tabItem {
                    Label(settings.text("Library", "资料库"), systemImage: "books.vertical")
                        .accessibilityIdentifier("tab.library")
                }
        }
        .background { NewsTranslationCoordinator(articles: news.articles) }
    }
}
