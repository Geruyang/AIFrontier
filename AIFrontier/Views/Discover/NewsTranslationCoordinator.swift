import SwiftUI
@preconcurrency import Translation

struct NewsTranslationCoordinator: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var translations: NewsTranslationStore
    let articles: [NewsArticle]
    @State private var configuration: TranslationSession.Configuration?

    private var workID: String {
        settings.language.rawValue + ":\(scenePhase == .background ? "background" : "foreground"):\(translations.retryCount):" + articles.filter { $0.languageCode.lowercased().hasPrefix("en") }.map {
            NewsTranslationStore.key(for: $0.title + "\n" + $0.summary)
        }.sorted().joined(separator: ":")
    }

    var body: some View {
        Color.clear.frame(width: 0, height: 0)
            .task(id: workID) {
                translations.retainTranslations(for: articles)
                guard scenePhase != .background, settings.language == .simplifiedChinese, !translations.failed, !translations.pending(for: articles).isEmpty else {
                    configuration = nil
                    return
                }
                // The system translation engine is unavailable in iOS simulators.
                #if targetEnvironment(simulator)
                translations.markUnavailable()
                #else
                if configuration == nil {
                    configuration = .init(source: Locale.Language(identifier: "en"), target: Locale.Language(identifier: "zh-Hans"))
                } else { configuration?.invalidate() }
                #endif
            }
            .translationTask(configuration) { session in
                await translations.run(inputs: translations.pending(for: articles)) { batch in
                    try await session.prepareTranslation()
                    let responses = try await Self.translate(batch, using: session)
                    return responses.compactMap { response in
                        guard let id = response.clientIdentifier else { return nil }
                        return TranslationOutput(id: id, source: response.sourceText, text: response.targetText)
                    }
                }
            }
    }

    nonisolated private static func translate(_ batch: [TranslationInput], using session: TranslationSession) async throws -> [TranslationSession.Response] {
        let requests = batch.map { TranslationSession.Request(sourceText: $0.text, clientIdentifier: $0.id) }
        return try await session.translations(from: requests)
    }
}

struct NewsTranslationStatus: View {
    @EnvironmentObject private var translations: NewsTranslationStore
    var body: some View {
        if translations.isTranslating {
            ProgressView("正在设备端翻译英文资讯…").font(.footnote)
        } else if translations.failed {
            VStack(alignment: .leading, spacing: 8) {
                #if targetEnvironment(simulator)
                Text("当前模拟器不支持 Apple 翻译引擎，保留英文原文。请在真机测试翻译及语言包下载。")
                    .font(.footnote).foregroundStyle(.secondary)
                #else
                Text("译文暂不可用，保留英文原文。首次翻译请联网下载 Apple 语言包，或稍后重试。")
                    .font(.footnote).foregroundStyle(.secondary)
                #endif
                Button("重试翻译") { translations.retry() }.font(.footnote)
            }
        } else {
            Text("英文标题和摘要在本机智能翻译，译文自动缓存。首次使用可能需要下载 Apple 语言包。")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }
}
