import CryptoKit
import Foundation

struct TranslationInput: Equatable, Sendable {
    let id: String
    let text: String
}

struct TranslationOutput: Sendable {
    let id: String
    let source: String
    let text: String
}

@MainActor
final class NewsTranslationStore: ObservableObject {
    private struct Entry: Codable {
        let text: String
        let created: Date
    }
    @Published private var entries: [String: Entry]
    @Published private(set) var isTranslating = false
    @Published private(set) var failed = false
    @Published private(set) var retryCount = 0
    private let defaults: UserDefaults
    private let storageKey = "news.translations.en.zh-Hans.v1"
    private var activeRunID: UUID?
    private var retainedKeys: Set<String> = []
    private var activeInputKeys: Set<String> = []

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let decoded = defaults.data(forKey: storageKey).flatMap { try? JSONDecoder().decode([String: Entry].self, from: $0) } ?? [:]
        entries = decoded.filter { Date.now.timeIntervalSince($0.value.created) < 32 * 86400 }
    }

    nonisolated static func key(for text: String) -> String {
        SHA256.hash(data: Data(("en→zh-Hans:v1:" + text).utf8)).map { String(format: "%02x", $0) }.joined()
    }

    func translated(_ text: String, language: AppLanguage) -> String {
        language == .simplifiedChinese ? (entries[Self.key(for: text)]?.text ?? text) : text
    }

    func hasTranslation(for article: NewsArticle) -> Bool {
        entries[Self.key(for: article.title)] != nil && (article.summary.isEmpty || entries[Self.key(for: article.summary)] != nil)
    }

    func retainTranslations(for articles: [NewsArticle]) {
        retainedKeys = Set(articles.flatMap { [$0.title, $0.summary] }.map(Self.key(for:)))
    }

    func pending(for articles: [NewsArticle]) -> [TranslationInput] {
        var seen = Set<String>()
        return articles.filter { $0.languageCode.lowercased().hasPrefix("en") }.flatMap { [$0.title, $0.summary] }.compactMap { text in
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            let id = Self.key(for: text)
            guard entries[id] == nil, seen.insert(id).inserted else { return nil }
            return .init(id: id, text: text)
        }
    }

    // Responses can arrive out of order. Validate both the client identifier and original text.
    func accept(_ outputs: [TranslationOutput], for inputs: [TranslationInput]) -> Int {
        let expected = Dictionary(inputs.map { ($0.id, $0.text) }, uniquingKeysWith: { first, _ in first })
        var accepted = Set<String>()
        for output in outputs {
            guard expected[output.id] == output.source, Self.key(for: output.source) == output.id,
                  !output.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            entries[output.id] = Entry(text: output.text, created: .now)
            accepted.insert(output.id)
        }
        if entries.count > 800 {
            // Saved articles can outlive the rolling news cache. Never evict text that
            // is still referenced or belongs to the batch currently being translated.
            let recent = Set(entries.sorted { $0.value.created > $1.value.created }.prefix(800).map(\.key))
            let keep = recent.union(retainedKeys).union(activeInputKeys)
            entries = entries.filter { keep.contains($0.key) }
        }
        if let encoded = try? JSONEncoder().encode(entries) { defaults.set(encoded, forKey: storageKey) }
        return accepted.count
    }

    func retry() { failed = false; retryCount += 1 }
    func markUnavailable() { failed = true }

    func run(inputs: [TranslationInput], translate: @MainActor ([TranslationInput]) async throws -> [TranslationOutput]) async {
        guard !inputs.isEmpty else { return }
        let runID = UUID()
        activeRunID = runID
        activeInputKeys = Set(inputs.map(\.id))
        isTranslating = true
        failed = false
        defer { if activeRunID == runID { isTranslating = false; activeRunID = nil; activeInputKeys = [] } }
        do {
            for start in stride(from: 0, to: inputs.count, by: 40) {
                try Task.checkCancellation()
                let batch = Array(inputs[start..<min(start + 40, inputs.count)])
                let result = try await translate(batch)
                try Task.checkCancellation()
                guard activeRunID == runID else { throw CancellationError() }
                if accept(result, for: batch) != batch.count { failed = true }
            }
        } catch is CancellationError {
            // A user declining preparation needs a retry option; task cancellation is silent.
            if !Task.isCancelled, activeRunID == runID { failed = true }
        } catch { if !Task.isCancelled, activeRunID == runID { failed = true } }
    }
}
