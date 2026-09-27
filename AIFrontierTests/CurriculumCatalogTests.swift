import XCTest
@testable import AIFrontier

final class CurriculumCatalogTests: XCTestCase {
    func testSearchFindsApplicationsInEitherLanguageAndRespectsTheSchoolLevel() {
        let id = "course-expanded-university-guidance-strength"
        XCTAssertTrue(CurriculumCatalog.matchingLessons(query: "garden-robot description", level: .university).contains { $0.id == id })
        XCTAssertTrue(CurriculumCatalog.matchingLessons(query: "提高对园艺机器人描述的强调", level: nil).contains { $0.id == id })
        XCTAssertFalse(CurriculumCatalog.matchingLessons(query: "Guidance strength", level: .explorer).contains { $0.id == id })
        XCTAssertEqual(CurriculumCatalog.matchingLessons(query: "   ", level: .secondary).count, 200)
    }
    func testCatalogHasPromisedContentVolume() {
        XCTAssertEqual(CurriculumCatalog.lessons.count, 600)
        XCTAssertEqual(CurriculumCatalog.lessons.flatMap(\.sections).count, 1800)
        XCTAssertEqual(CurriculumCatalog.questionCount, 1980)
        XCTAssertEqual(CurriculumCatalog.lessons.filter(\.isFree).count, 9)
        XCTAssertEqual(Set(CurriculumCatalog.lessons.map(\.id)).count, 600)
        let newLessons = CurriculumCatalog.lessons.filter { $0.id.hasPrefix("course-expanded-") }
        XCTAssertEqual(newLessons.count, 540)
        XCTAssertEqual(Set(newLessons.map { $0.sections[0].body.en }).count, 540)
        XCTAssertEqual(Set(newLessons.map { $0.sections[1].example!.en }).count, 540)
        XCTAssertEqual(Set(newLessons.map { $0.sections[2].body.en }).count, 540)
    }

    func testEveryLessonIsCompleteAndBilingual() {
        for lesson in CurriculumCatalog.lessons {
            XCTAssertFalse(lesson.title.en.isEmpty)
            XCTAssertFalse(lesson.title.zhHans.isEmpty)
            XCTAssertEqual(lesson.sections.count, 3)
            XCTAssertTrue([3, 6].contains(lesson.questions.count))
            XCTAssertTrue(lesson.questions.allSatisfy { $0.choices.indices.contains($0.correctIndex) })
            XCTAssertEqual(Set(lesson.questions.map { $0.prompt.en }).count, lesson.questions.count)
            XCTAssertEqual(Set(lesson.questions.map(\.correctIndex)), [0, 1, 2])
            for section in lesson.sections {
                XCTAssertFalse(section.body.en.isEmpty)
                XCTAssertFalse(section.body.zhHans.isEmpty)
                if let example = section.example {
                    XCTAssertFalse(example.en.isEmpty)
                    XCTAssertFalse(example.zhHans.isEmpty)
                }
                XCTAssertNotEqual(section.title.en, "See the system")
                XCTAssertNotEqual(section.title.en, "Try it")
            }
            for question in lesson.questions {
                XCTAssertTrue(lesson.sections.contains { $0.id == question.contextSectionID })
                XCTAssertFalse(question.context?.en.isEmpty ?? true)
                XCTAssertFalse(question.context?.zhHans.isEmpty ?? true)
                XCTAssertFalse(question.explanation.en.isEmpty)
                XCTAssertFalse(question.explanation.zhHans.isEmpty)
                XCTAssertTrue(question.choices.allSatisfy { !$0.en.isEmpty && !$0.zhHans.isEmpty })
                XCTAssertEqual(Set(question.choices).count, question.choices.count)
            }
            XCTAssertGreaterThan(lesson.estimatedMinutes, 0)
        }
    }

    func testTracksAndLevelsAreCovered() {
        XCTAssertEqual(Set(CurriculumCatalog.lessons.map(\.track)), Set(CourseTrack.allCases))
        XCTAssertEqual(Set(CurriculumCatalog.lessons.map(\.level)), Set(AudienceLevel.allCases))
        XCTAssertEqual(AudienceLevel.allCases.count, 3)
        for level in AudienceLevel.allCases {
            XCTAssertEqual(CurriculumCatalog.lessons.filter { $0.level == level }.count, 200)
        }
    }

    func testEveryLessonHasResolvableAuthoritativeReferences() {
        XCTAssertEqual(Set(CurriculumCatalog.references.map(\.id)).count, CurriculumCatalog.references.count)
        for lesson in CurriculumCatalog.lessons {
            XCTAssertFalse(lesson.referenceIDs.isEmpty)
            XCTAssertEqual(CurriculumCatalog.references(for: lesson).count, lesson.referenceIDs.count)
            for reference in CurriculumCatalog.references(for: lesson) {
                XCTAssertEqual(reference.url.scheme, "https")
                XCTAssertFalse(reference.authors.isEmpty)
                XCTAssertFalse(reference.locator.isEmpty)
            }
        }
    }

    func testOldResearchPreferenceMigratesWithoutLosingUserData() throws {
        let value = AppUserData(completedLessonIDs: ["lesson-01"], bookmarkedArticleIDs: ["saved"])
        let encoded = try JSONEncoder().encode(value)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object["selectedLevel"] = "research"
        let decoded = try JSONDecoder().decode(AppUserData.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(decoded.selectedLevel, .university)
        XCTAssertEqual(decoded.bookmarkedArticleIDs, ["saved"])
        XCTAssertEqual(decoded.completedLessonIDs, ["lesson-01"])
    }
}
