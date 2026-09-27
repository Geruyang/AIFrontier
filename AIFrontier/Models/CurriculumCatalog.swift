import Foundation

enum CurriculumCatalog {
    private struct Content: Decodable {
        let schemaVersion: Int
        let references: [CurriculumReference]
        let lessons: [Lesson]
    }

    private static let content: Content = {
        guard let url = Bundle.main.url(forResource: "Curriculum", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let content = try? JSONDecoder().decode(Content.self, from: data),
              content.schemaVersion == 3 else {
            preconditionFailure("The bundled curriculum is missing or invalid.")
        }
        return content
    }()

    static var lessons: [Lesson] { content.lessons }
    static var references: [CurriculumReference] { content.references }
    static var questionCount: Int { lessons.reduce(0) { $0 + $1.questions.count } }
    private static let searchIndex = Dictionary(uniqueKeysWithValues: lessons.map { lesson in
        let texts = [lesson.title, lesson.summary] + lesson.sections.map(\.body) + lesson.sections.compactMap(\.example)
        return (lesson.id, texts.map { $0.en + "\n" + $0.zhHans }.joined(separator: "\n"))
    })

    static func matchingLessons(query: String, level: AudienceLevel?) -> [Lesson] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return lessons.filter { lesson in
            (level == nil || lesson.level == level) && (query.isEmpty || searchIndex[lesson.id]?.localizedCaseInsensitiveContains(query) == true)
        }
    }

    static func references(for lesson: Lesson) -> [CurriculumReference] {
        lesson.referenceIDs.compactMap { id in references.first { $0.id == id } }
    }
}
