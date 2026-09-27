import XCTest
@testable import AIFrontier

final class TrendAnalyzerTests: XCTestCase {
    func testCountsMatchingArticlesOncePerTopic() {
        let articles = [
            article(id: "1", title: "Agent tool use benchmark", summary: "Reasoning evaluation"),
            article(id: "2", title: "Multimodal agent", summary: "Image and video"),
            article(id: "3", title: "Cooking", summary: "No AI topic terms here")
        ]
        let topics = TrendAnalyzer.topics(from: articles)
        XCTAssertEqual(topics.first(where: { $0.id == "agents" })?.count, 2)
        XCTAssertEqual(topics.first(where: { $0.id == "multimodal" })?.count, 1)
        XCTAssertEqual(topics.first(where: { $0.id == "evaluation" })?.count, 1)
    }

    func testEmptyInputReturnsNoTopics() {
        XCTAssertTrue(TrendAnalyzer.topics(from: []).isEmpty)
    }

    private func article(id: String, title: String, summary: String) -> NewsArticle {
        .init(id: id, title: title, summary: summary, url: URL(string: "https://example.com/\(id)")!, sourceName: "Test", publishedAt: .now, languageCode: "en", categories: [], isReviewed: false)
    }
}

