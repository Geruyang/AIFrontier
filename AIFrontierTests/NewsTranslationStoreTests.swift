import XCTest
@testable import AIFrontier

@MainActor
final class NewsTranslationStoreTests: XCTestCase {
    private func defaults() -> UserDefaults { UserDefaults(suiteName: "translation.tests.\(UUID())")! }
    private func article(title: String = "New AI model", summary: String = "A research release") -> NewsArticle {
        .init(id: "one", title: title, summary: summary, url: URL(string: "https://example.com/news")!, sourceName: "OpenAI News", publishedAt: .now, languageCode: "en", categories: ["AI"], isReviewed: false)
    }

    func testLargeActiveArticleSetDoesNotEvictItsOwnTranslations() async {
        let store = NewsTranslationStore(defaults: defaults())
        let articles = (0..<401).map { article(title: "Title \($0)", summary: "Summary \($0)") }
        await store.run(inputs: store.pending(for: articles)) { inputs in
            inputs.map { .init(id: $0.id, source: $0.text, text: "译文 " + $0.text) }
        }
        XCTAssertTrue(store.pending(for: articles).isEmpty)
    }

    func testOutOfOrderResponsesMatchOriginalTextAndRejectWrongIdentifiers() {
        let store = NewsTranslationStore(defaults: defaults())
        let news = article()
        let inputs = store.pending(for: [news])
        let outputs = [TranslationOutput(id: inputs[1].id, source: inputs[1].text, text: "研究发布"),
                       .init(id: inputs[0].id, source: "A different source", text: "错误译文"),
                       .init(id: "unknown", source: inputs[0].text, text: "错误匹配"),
                       .init(id: inputs[0].id, source: inputs[0].text, text: "新 AI 模型")]
        XCTAssertEqual(store.accept(outputs, for: inputs), 2)
        XCTAssertEqual(store.translated(news.title, language: .simplifiedChinese), "新 AI 模型")
        XCTAssertEqual(store.translated(news.summary, language: .simplifiedChinese), "研究发布")
    }

    func testAnEditedArticleRequiresFreshTranslationAndEnglishRemainsOriginal() {
        let store = NewsTranslationStore(defaults: defaults())
        let news = article()
        let inputs = store.pending(for: [news])
        _ = store.accept(inputs.map { .init(id: $0.id, source: $0.text, text: "已翻译") }, for: inputs)
        let edited = article(summary: "An updated research release")
        XCTAssertTrue(store.hasTranslation(for: news))
        XCTAssertFalse(store.hasTranslation(for: edited))
        XCTAssertEqual(store.pending(for: [edited]).map(\.text), [edited.summary])
        XCTAssertEqual(store.translated(edited.summary, language: .simplifiedChinese), edited.summary)
        XCTAssertEqual(store.translated(news.title, language: .english), news.title)
    }

    func testPersistenceDeduplicationAndEmptySummary() {
        let sharedDefaults = defaults()
        let store = NewsTranslationStore(defaults: sharedDefaults)
        let news = article(summary: "")
        let inputs = store.pending(for: [news, news])
        XCTAssertEqual(inputs.count, 1)
        XCTAssertEqual(store.accept([.init(id: inputs[0].id, source: inputs[0].text, text: "  ")], for: inputs), 0)
        _ = store.accept([.init(id: inputs[0].id, source: inputs[0].text, text: "新模型")], for: inputs)
        let reloaded = NewsTranslationStore(defaults: sharedDefaults)
        XCTAssertTrue(reloaded.hasTranslation(for: news))
        XCTAssertTrue(reloaded.pending(for: [news]).isEmpty)
    }

    func testPartialFailurePreservesSuccessfulTranslationAndOffersRetry() async {
        let store = NewsTranslationStore(defaults: defaults())
        let news = article()
        await store.run(inputs: store.pending(for: [news])) { inputs in
            [.init(id: inputs[0].id, source: inputs[0].text, text: "新模型")]
        }
        XCTAssertTrue(store.failed)
        XCTAssertFalse(store.isTranslating)
        XCTAssertEqual(store.translated(news.title, language: .simplifiedChinese), "新模型")
        XCTAssertEqual(store.translated(news.summary, language: .simplifiedChinese), news.summary)
        store.retry()
        XCTAssertFalse(store.failed)
        XCTAssertEqual(store.retryCount, 1)
        await store.run(inputs: store.pending(for: [news])) { _ in throw URLError(.notConnectedToInternet) }
        XCTAssertTrue(store.failed)
    }

    func testBatchesAreBoundedAndEveryResultIsStored() async {
        let store = NewsTranslationStore(defaults: defaults())
        let articles = (0..<100).map { article(title: "Title \($0)", summary: "Summary \($0)") }
        var batchSizes: [Int] = []
        await store.run(inputs: store.pending(for: articles)) { inputs in
            batchSizes.append(inputs.count)
            return inputs.reversed().map { .init(id: $0.id, source: $0.text, text: "译文\($0.text)") }
        }
        XCTAssertEqual(batchSizes, [40, 40, 40, 40, 40])
        XCTAssertTrue(articles.allSatisfy { store.hasTranslation(for: $0) })
        XCTAssertFalse(store.failed)
    }

    func testSlowSupersededRunCannotOverwriteTheLatestTranslation() async {
        let store = NewsTranslationStore(defaults: defaults())
        let inputs = store.pending(for: [article(summary: "")])
        var continuation: CheckedContinuation<[TranslationOutput], Never>?
        let old = Task { await store.run(inputs: inputs) { _ in
            await withCheckedContinuation { continuation = $0 }
        } }
        while continuation == nil { await Task.yield() }
        await store.run(inputs: inputs) { values in values.map { .init(id: $0.id, source: $0.text, text: "新结果") } }
        continuation?.resume(returning: inputs.map { .init(id: $0.id, source: $0.text, text: "旧结果") })
        await old.value
        XCTAssertEqual(store.translated(inputs[0].text, language: .simplifiedChinese), "新结果")
        XCTAssertFalse(store.isTranslating)
        XCTAssertFalse(store.failed)
    }

    func testCancelledWorkDoesNotPublishTranslationOrFailure() async {
        let store = NewsTranslationStore(defaults: defaults())
        let inputs = store.pending(for: [article(summary: "")])
        var continuation: CheckedContinuation<[TranslationOutput], Never>?
        let task = Task { await store.run(inputs: inputs) { _ in
            await withCheckedContinuation { continuation = $0 }
        } }
        while continuation == nil { await Task.yield() }
        task.cancel()
        continuation?.resume(returning: inputs.map { .init(id: $0.id, source: $0.text, text: "已取消") })
        await task.value
        XCTAssertFalse(store.failed)
        XCTAssertFalse(store.isTranslating)
        XCTAssertEqual(store.pending(for: [article(summary: "")]), inputs)
    }

    func testDecliningLanguagePreparationKeepsOriginalAndAllowsExplicitRetry() async {
        let store = NewsTranslationStore(defaults: defaults())
        let news = article()
        await store.run(inputs: store.pending(for: [news])) { _ in throw CancellationError() }
        XCTAssertTrue(store.failed)
        XCTAssertFalse(store.hasTranslation(for: news))
        XCTAssertEqual(store.translated(news.title, language: .simplifiedChinese), news.title)
        store.retry()
        XCTAssertFalse(store.failed)
    }
}
