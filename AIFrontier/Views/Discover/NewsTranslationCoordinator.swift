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
        if translations.failed {
            HStack {
                Text("译文暂不可用，可先阅读原文。")
                    .font(.footnote).foregroundStyle(.secondary)
                Button("重试翻译") { translations.retry() }.font(.footnote).frame(minHeight: 44)
            }
        }
    }
}
