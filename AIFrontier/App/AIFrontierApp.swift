import BackgroundTasks
import SwiftUI

@main
struct AIFrontierApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var settings: AppSettings
    @StateObject private var store: LocalStore
    @StateObject private var news: NewsService
    @StateObject private var purchases: PurchaseManager
    @StateObject private var translations: NewsTranslationStore

    private let isUITesting: Bool
    private static let refreshIdentifier = "com.geruyang.aifrontier.refresh"

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let testing = arguments.contains("-ui-testing") || arguments.contains("-onboarding-ui-testing")
        let storeKitTesting = arguments.contains("-storekit-ui-testing")
        let defaults = testing ? UserDefaults(suiteName: "AIFrontier.UITesting")! : .standard
        if testing {
            defaults.removePersistentDomain(forName: "AIFrontier.UITesting")
        }
        let localStore = LocalStore(defaults: defaults)
        if testing {
            localStore.updateArticles([
                .init(id: "ui-news", title: "New AI model release", summary: "A simulated announcement used only by automated interface tests.",
                      url: URL(string: "https://example.com/ai-release")!, sourceName: NewsSource.defaults[0].name,
                      publishedAt: .now, languageCode: "en", categories: ["AI"], isReviewed: false)
            ])
        }
        _settings = StateObject(wrappedValue: AppSettings(defaults: defaults))
        _store = StateObject(wrappedValue: localStore)
        _news = StateObject(wrappedValue: NewsService(store: localStore))
        _purchases = StateObject(wrappedValue: PurchaseManager(startAutomatically: !testing))
        let translationStore = NewsTranslationStore(defaults: defaults)
        if testing, arguments.contains("-chinese-news-ui-testing") {
            defaults.set("zh-Hans", forKey: "app.language")
            let inputs = translationStore.pending(for: localStore.data.cachedArticles)
            _ = translationStore.accept(inputs.map { .init(id: $0.id, source: $0.text, text: $0.text == "New AI model release" ? "新 AI 模型发布" : "仅用于自动化界面测试的模拟公告。") }, for: inputs)
        }
        _translations = StateObject(wrappedValue: translationStore)
        isUITesting = testing || storeKitTesting
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(store)
                .environmentObject(news)
                .environmentObject(purchases)
                .environmentObject(translations)
                .task(id: scenePhase) {
                    guard !isUITesting else { return }
                    switch scenePhase {
                    case .active:
                        // Keep news independent of StoreKit response times.
                        async let entitlements: Void = purchases.refreshEntitlements()
                        await news.refreshWhileActive()
                        await entitlements
                    case .background:
                        await scheduleRefresh()
                    default:
                        break
                    }
                }
        }
        .backgroundTask(.appRefresh(Self.refreshIdentifier)) {
            await news.refresh()
            await scheduleRefresh()
        }
    }

    @MainActor
    private func scheduleRefresh() async {
        guard !isUITesting else { return }
        let pending = await BGTaskScheduler.shared.pendingTaskRequests()
        let existing = pending.first { $0.identifier == Self.refreshIdentifier }
        let now = Date()
        guard NewsRefreshPolicy.needsBackgroundRequest(hasPending: existing != nil,
                                                      earliestDate: existing?.earliestBeginDate, now: now) else { return }
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshIdentifier)
        request.earliestBeginDate = now.addingTimeInterval(NewsRefreshPolicy.interval)
        // iOS decides the actual run time; replacement only shortens an older request.
        try? BGTaskScheduler.shared.submit(request)
    }
}
