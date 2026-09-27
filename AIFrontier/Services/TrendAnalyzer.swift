import Foundation

enum TrendAnalyzer {
    private struct Definition {
        let id: String
        let label: BilingualText
        let terms: [String]
    }

    private static let definitions: [Definition] = [
        .init(id: "agents", label: .init(en: "Agents & tools", zhHans: "智能体与工具"), terms: ["agent", "tool use", "reasoning"]),
        .init(id: "multimodal", label: .init(en: "Multimodal", zhHans: "多模态"), terms: ["multimodal", "vision-language", "image", "video"]),
        .init(id: "efficiency", label: .init(en: "Efficiency", zhHans: "效率优化"), terms: ["efficient", "quantization", "inference", "small model"]),
        .init(id: "evaluation", label: .init(en: "Evaluation", zhHans: "评估"), terms: ["benchmark", "evaluation", "robust", "safety"]),
        .init(id: "open-source", label: .init(en: "Open source", zhHans: "开源生态"), terms: ["open source", "release", "library", "dataset"]),
        .init(id: "generative", label: .init(en: "Generative models", zhHans: "生成模型"), terms: ["language model", "diffusion", "generation", "llm"])
    ]

    static func topics(from articles: [NewsArticle]) -> [TrendTopic] {
        definitions.compactMap { definition in
            let matches = articles.filter { article in
                let haystack = (article.title + " " + article.summary).lowercased()
                return definition.terms.contains { haystack.contains($0) }
            }
            guard !matches.isEmpty else { return nil }
            return TrendTopic(id: definition.id, label: definition.label, count: matches.count, articleIDs: matches.map(\.id))
        }.sorted { lhs, rhs in
            lhs.count == rhs.count ? lhs.id < rhs.id : lhs.count > rhs.count
        }
    }
}
