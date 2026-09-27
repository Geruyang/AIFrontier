import Foundation

struct BilingualText: Codable, Hashable, Sendable {
    let en: String
    let zhHans: String

    func value(for language: AppLanguage) -> String {
        language == .english ? en : zhHans
    }
}

enum AppLanguage: String, Codable, CaseIterable, Identifiable, Sendable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"

    var id: String { rawValue }
    var displayName: String { self == .english ? "English" : "简体中文" }
}

enum AudienceLevel: String, Codable, CaseIterable, Identifiable, Sendable {
    case explorer
    case secondary
    case university

    var id: String { rawValue }

    var label: BilingualText {
        switch self {
        case .explorer: .init(en: "Beginner", zhHans: "入门")
        case .secondary: .init(en: "Fundamentals", zhHans: "基础")
        case .university: .init(en: "Advanced", zhHans: "进阶")
        }
    }

    var coreContent: BilingualText {
        switch self {
        case .explorer: .init(en: "What AI is, everyday recognition and recommendation, and safe use through simple examples.", zhHans: "通过生活例子认识 AI，了解识别、推荐、生成与安全使用。")
        case .secondary: .init(en: "How data trains models, how results are evaluated, and how prompts and generative AI work.", zhHans: "理解数据与模型学习、训练与评估，以及提示词和生成式 AI 的基本方法。")
        case .university: .init(en: "Task design, model selection, evaluation, retrieval, deployment, and responsible application.", zhHans: "学习任务设计、模型选型、效果评估、检索增强、部署与负责任应用。")
        }
    }

    var purpose: BilingualText {
        switch self {
        case .explorer: .init(en: "Recognize where AI helps, explain it in your own words, and know when to ask a person.", zhHans: "建立 AI 的直观认识，能用自己的话解释用途，知道何时需要人的帮助。")
        case .secondary: .init(en: "Understand why AI succeeds or makes mistakes, and choose and use tools more effectively.", zhHans: "理解 AI 为什么有效、为什么会出错，更合理地选择和使用工具。")
        case .university: .init(en: "Apply AI to practical problems, compare solutions, and identify improvements and risks.", zhHans: "把 AI 方法用于实际问题，能比较方案、评估效果并识别改进方向与风险。")
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        // Keep old users' bookmarks/progress when migrating the removed audience.
        if raw == "research" { self = .university; return }
        guard let value = Self(rawValue: raw) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown audience")
        }
        self = value
    }
}

enum CourseTrack: String, Codable, CaseIterable, Identifiable, Sendable {
    case foundations, dataLearning, modelsEvaluation, generativeAI, responsibleAI

    var id: String { rawValue }

    var title: BilingualText {
        switch self {
        case .foundations: .init(en: "AI Foundations", zhHans: "AI 基础")
        case .dataLearning: .init(en: "Data & Learning", zhHans: "数据与学习")
        case .modelsEvaluation: .init(en: "Models & Evaluation", zhHans: "模型与评估")
        case .generativeAI: .init(en: "Generative AI", zhHans: "生成式 AI")
        case .responsibleAI: .init(en: "Responsible Use", zhHans: "负责任使用")
        }
    }

    var symbol: String {
        switch self {
        case .foundations: "sparkles"
        case .dataLearning: "point.3.connected.trianglepath.dotted"
        case .modelsEvaluation: "chart.xyaxis.line"
        case .generativeAI: "wand.and.stars"
        case .responsibleAI: "checkmark.shield"
        }
    }

    var coreContent: BilingualText {
        switch self {
        case .foundations: .init(en: "AI concepts, task goals, reasoning, search, and common applications.", zhHans: "AI 概念、任务目标、推理、搜索与常见应用。")
        case .dataLearning: .init(en: "Data collection, labels, features, and learning from examples.", zhHans: "数据采集、标注、特征与从样本中学习的方法。")
        case .modelsEvaluation: .init(en: "Model predictions, errors, evaluation, and practical comparisons.", zhHans: "模型预测、误差、效果评估与实际方案比较。")
        case .generativeAI: .init(en: "Text and image generation, prompts, retrieval, and output quality.", zhHans: "文本与图像生成、提示词、检索增强与输出质量。")
        case .responsibleAI: .init(en: "Privacy, fairness, reliability, human oversight, and safe use.", zhHans: "隐私、公平性、可靠性、人工核验与安全使用。")
        }
    }

    var purpose: BilingualText {
        switch self {
        case .foundations: .init(en: "Build a clear picture of what AI can do and how to define a useful task.", zhHans: "建立清晰的 AI 知识框架，学会定义有用的任务。")
        case .dataLearning: .init(en: "Understand how data quality affects results and how to prepare useful examples.", zhHans: "理解数据质量如何影响结果，学会准备有效样本。")
        case .modelsEvaluation: .init(en: "Judge whether a model works well for its intended use.", zhHans: "判断模型是否真正适合目标用途。")
        case .generativeAI: .init(en: "Use generative tools effectively and check the usefulness of their outputs.", zhHans: "更有效地使用生成工具，并检查输出是否有用。")
        case .responsibleAI: .init(en: "Make informed choices and keep people in control of important decisions.", zhHans: "作出有依据的选择，让重要决策保留人的判断。")
        }
    }
}

struct LessonSection: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let title: BilingualText
    let body: BilingualText
    let symbol: String
    let example: BilingualText?
}

struct CurriculumReference: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let authors: String
    let year: Int
    let locator: String
    let url: URL
}

struct QuizQuestion: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let contextSectionID: String?
    let context: BilingualText?
    let prompt: BilingualText
    let choices: [BilingualText]
    let correctIndex: Int
    let explanation: BilingualText
}

struct Lesson: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let order: Int
    let track: CourseTrack
    let level: AudienceLevel
    let title: BilingualText
    let summary: BilingualText
    let keyIdea: BilingualText
    let sections: [LessonSection]
    let questions: [QuizQuestion]
    let estimatedMinutes: Int
    let isFree: Bool
    let referenceIDs: [String]
}

struct NewsSource: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let name: String
    let feedURL: URL
    let homepageURL: URL
    let kind: String

    static let defaults: [NewsSource] = [
        .init(id: "openai", name: "OpenAI News", feedURL: URL(string: "https://openai.com/news/rss.xml")!, homepageURL: URL(string: "https://openai.com/news/")!, kind: "Official announcement"),
        .init(id: "google-ai", name: "Google AI", feedURL: URL(string: "https://blog.google/technology/ai/rss/")!, homepageURL: URL(string: "https://blog.google/technology/ai/")!, kind: "Official announcement"),
        .init(id: "deepmind", name: "Google DeepMind", feedURL: URL(string: "https://deepmind.google/blog/rss.xml")!, homepageURL: URL(string: "https://deepmind.google/blog/")!, kind: "Official research announcement"),
        .init(id: "nvidia-ai", name: "NVIDIA AI", feedURL: URL(string: "https://blogs.nvidia.com/blog/category/generative-ai/feed/")!, homepageURL: URL(string: "https://blogs.nvidia.com/")!, kind: "Official announcement"),
        .init(id: "microsoft-ai", name: "Microsoft AI", feedURL: URL(string: "https://www.microsoft.com/en-us/ai/blog/feed/")!, homepageURL: URL(string: "https://www.microsoft.com/en-us/ai/blog/")!, kind: "Official announcement"),
        .init(id: "aws-ml", name: "AWS Machine Learning", feedURL: URL(string: "https://aws.amazon.com/blogs/machine-learning/feed/")!, homepageURL: URL(string: "https://aws.amazon.com/blogs/machine-learning/")!, kind: "Official announcement"),
        .init(id: "hugging-face", name: "Hugging Face", feedURL: URL(string: "https://huggingface.co/blog/feed.xml")!, homepageURL: URL(string: "https://huggingface.co/blog")!, kind: "Official community and research"),
        .init(id: "mit-ai", name: "MIT News · AI", feedURL: URL(string: "https://news.mit.edu/rss/topic/artificial-intelligence2")!, homepageURL: URL(string: "https://news.mit.edu/topic/artificial-intelligence2")!, kind: "University news"),
        .init(id: "berkeley-ai", name: "Berkeley AI Research", feedURL: URL(string: "https://bair.berkeley.edu/blog/feed.xml")!, homepageURL: URL(string: "https://bair.berkeley.edu/blog/")!, kind: "University research announcement")
    ]
}

struct NewsArticle: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let summary: String
    let url: URL
    let sourceName: String
    let publishedAt: Date
    let languageCode: String
    let categories: [String]
    var isReviewed: Bool
}

struct TrendTopic: Identifiable, Hashable, Sendable {
    let id: String
    let label: BilingualText
    let count: Int
    let articleIDs: [String]
}

struct AppUserData: Codable, Equatable, Sendable {
    var completedLessonIDs: Set<String> = []
    var lessonScores: [String: Int] = [:]
    var bookmarkedArticleIDs: Set<String> = []
    var cachedArticles: [NewsArticle] = []
    var lastNewsRefresh: Date?
    var selectedLevel: AudienceLevel?
    var savedArticles: [NewsArticle] = []
    var latestLessonScores: [String: Int] = [:]
    var lastVisitedLessonID: String?

    private enum CodingKeys: String, CodingKey {
        case completedLessonIDs, lessonScores, bookmarkedArticleIDs, cachedArticles, lastNewsRefresh, selectedLevel
        case savedArticles, latestLessonScores, lastVisitedLessonID
    }

}

extension AppUserData {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        completedLessonIDs = try values.decodeIfPresent(Set<String>.self, forKey: .completedLessonIDs) ?? []
        lessonScores = try values.decodeIfPresent([String: Int].self, forKey: .lessonScores) ?? [:]
        bookmarkedArticleIDs = try values.decodeIfPresent(Set<String>.self, forKey: .bookmarkedArticleIDs) ?? []
        cachedArticles = try values.decodeIfPresent([NewsArticle].self, forKey: .cachedArticles) ?? []
        lastNewsRefresh = try values.decodeIfPresent(Date.self, forKey: .lastNewsRefresh)
        selectedLevel = try values.decodeIfPresent(AudienceLevel.self, forKey: .selectedLevel)
        savedArticles = try values.decodeIfPresent([NewsArticle].self, forKey: .savedArticles)
            ?? cachedArticles.filter { bookmarkedArticleIDs.contains($0.id) }
        latestLessonScores = try values.decodeIfPresent([String: Int].self, forKey: .latestLessonScores) ?? lessonScores
        lastVisitedLessonID = try values.decodeIfPresent(String.self, forKey: .lastVisitedLessonID)
    }
}
