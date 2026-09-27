import XCTest

@MainActor
final class AIFrontierUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCompletesFirstLessonQuiz() {
        let app = launchApp()
        XCTAssertTrue(app.navigationBars["Learn"].waitForExistence(timeout: 5))
        app.buttons["lesson.course-explorer-what-ai"].tap()
        let startQuiz = app.buttons["lesson.startQuiz"]
        for _ in 0..<5 where !startQuiz.exists { app.swipeUp() }
        XCTAssertTrue(startQuiz.waitForExistence(timeout: 3))
        startQuiz.tap()
        for question in 0..<6 {
            let choice = app.buttons["quiz.choice.\(question % 3)"]
            XCTAssertTrue(choice.waitForExistence(timeout: 3))
            XCTAssertTrue(app.staticTexts["Example for this question"].exists)
            reveal(choice, in: app)
            choice.tap()
            app.buttons["quiz.next"].tap()
            XCTAssertTrue(app.staticTexts["Correct"].waitForExistence(timeout: 3))
            app.buttons["quiz.next"].tap()
        }
        XCTAssertTrue(app.staticTexts["You scored 6 of 6"].waitForExistence(timeout: 3))
        app.buttons["quiz.done"].tap()
    }

    func testLearningLevelsExplainContentAndPurpose() {
        let app = launchApp()
        let levels = [
            ("Beginner", "What AI is, everyday recognition and recommendation, and safe use through simple examples.", "Recognize where AI helps, explain it in your own words, and know when to ask a person."),
            ("Fundamentals", "How data trains models, how results are evaluated, and how prompts and generative AI work.", "Understand why AI succeeds or makes mistakes, and choose and use tools more effectively."),
            ("Advanced", "Task design, model selection, evaluation, retrieval, deployment, and responsible application.", "Apply AI to practical problems, compare solutions, and identify improvements and risks.")
        ]
        for (label, core, purpose) in levels {
            app.buttons[label].tap()
            XCTAssertTrue(app.staticTexts["Core content: " + core].waitForExistence(timeout: 5))
            XCTAssertTrue(app.staticTexts["Purpose: " + purpose].exists)
        }
        XCTAssertFalse(app.buttons["Elementary"].exists)
        XCTAssertFalse(app.buttons["Secondary"].exists)
        XCTAssertFalse(app.buttons["University"].exists)
        attachScreenshot(app, name: "Advanced level content and purpose")
    }

    func testChinesePagesExplainContentAndPurpose() {
        let app = launchApp(arguments: ["-ui-testing", "-chinese-news-ui-testing"])
        for level in ["入门", "基础", "进阶"] {
            app.buttons[level].tap()
            assertChinesePurpose(in: app)
        }
        XCTAssertTrue(app.staticTexts["核心内容: 学习任务设计、模型选型、效果评估、检索增强、部署与负责任应用。"].exists)
        for (identifier, label) in [("tab.discover", "资讯"), ("tab.trends", "趋势"), ("tab.library", "资料库")] {
            tapTab(identifier, label: label, in: app)
            assertChinesePurpose(in: app)
        }
        app.buttons["library.settings"].tap()
        assertChinesePurpose(in: app)
        app.staticTexts["隐私摘要"].tap()
        assertChinesePurpose(in: app)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.staticTexts["使用条款"].tap()
        assertChinesePurpose(in: app)
        attachScreenshot(app, name: "Chinese page content and purpose")
    }

    private func assertChinesePurpose(in app: XCUIApplication) {
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "核心内容:")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "目的:")).firstMatch.exists)
    }

    func testReadsCurrentNewsAndEvidenceBoundary() {
        let app = launchApp()
        tapTab("tab.discover", label: "Discover", in: app)
        XCTAssertTrue(app.navigationBars["Discover"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Important AI news · past month"].exists)
        app.staticTexts["New AI model release"].tap()
        XCTAssertTrue(app.buttons["Open original"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Evidence note"].exists)
    }

    func testWrongAnswerShowsExplanationWithoutChangingScore() {
        let app = launchApp()
        app.buttons["lesson.course-explorer-what-ai"].tap()
        app.buttons["lesson.startQuiz"].tap()
        reveal(app.buttons["quiz.choice.1"], in: app)
        app.buttons["quiz.choice.1"].tap()
        app.buttons["quiz.next"].tap()
        XCTAssertTrue(app.staticTexts["Let's review"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Answer: Suggesting a flower name from a photo"].exists)
        XCTAssertFalse(app.buttons["quiz.choice.0"].isEnabled)
        app.buttons["quiz.next"].tap()
        XCTAssertTrue(app.staticTexts["Question 2 of 6"].waitForExistence(timeout: 3))
    }

    func testChineseNewsDisplaysTranslationAndEnglishOriginal() {
        let app = launchApp(arguments: ["-ui-testing", "-chinese-news-ui-testing"])
        tapTab("tab.discover", label: "资讯", in: app)
        let title = app.staticTexts["新 AI 模型发布"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        let original = app.buttons["查看英文标题与摘要"]
        reveal(original, in: app)
        original.tap()
        XCTAssertTrue(app.staticTexts["New AI model release"].exists)
        attachScreenshot(app, name: "Chinese translated news and original")
        let save = app.buttons["收藏"]
        reveal(save, in: app)
        save.tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        tapTab("tab.library", label: "资料库", in: app)
        XCTAssertTrue(app.staticTexts["新 AI 模型发布"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["New AI model release"].exists)
        attachScreenshot(app, name: "Chinese saved news")
    }

    func testSearchOpensNewUniversityLessonAndShowsExplicitQuizContext() {
        let app = launchApp()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Guidance strength")
        let lesson = app.buttons["lesson.course-expanded-university-guidance-strength"]
        XCTAssertTrue(lesson.waitForExistence(timeout: 5))
        lesson.tap()
        #if DEVELOPER_ACCESS
        XCTAssertTrue(app.buttons["lesson.startQuiz"].waitForExistence(timeout: 3))
        app.buttons["lesson.startQuiz"].tap()
        XCTAssertTrue(app.staticTexts["Example for this question"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["An image helper increases emphasis on the user's garden-robot description."].exists)
        attachScreenshot(app, name: "New lesson explicit quiz example")
        #else
        XCTAssertTrue(app.staticTexts["AI Frontier Pro"].waitForExistence(timeout: 3))
        #endif
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<8 where !element.isHittable { app.swipeUp() }
        XCTAssertTrue(element.isHittable)
    }

    func testBrowseMoreRevealsAdditionalUniversityKnowledge() {
        let app = launchApp()
        app.buttons["Advanced"].tap()
        let lesson = app.buttons["lesson.course-expanded-university-constraint-propagation"]
        XCTAssertFalse(lesson.exists)
        let more = app.buttons["learn.more.foundations"]
        reveal(more, in: app)
        more.tap()
        // Short drags keep a newly inserted row from being skipped by a full-screen swipe.
        let scroll = app.scrollViews.firstMatch
        for _ in 0..<12 where !lesson.isHittable {
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.72))
                .press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
        }
        XCTAssertTrue(lesson.isHittable)
        lesson.tap()
        #if DEVELOPER_ACCESS
        XCTAssertTrue(app.buttons["lesson.startQuiz"].waitForExistence(timeout: 5))
        #else
        XCTAssertTrue(app.staticTexts["AI Frontier Pro"].waitForExistence(timeout: 5))
        #endif
    }

    func testLessonShowsExamplesIllustrationsAndSources() {
        let app = launchApp()
        XCTAssertTrue(app.buttons["Beginner"].exists)
        XCTAssertTrue(app.buttons["Fundamentals"].exists)
        XCTAssertTrue(app.buttons["Advanced"].exists)
        XCTAssertFalse(app.buttons["Research"].exists)
        app.buttons["lesson.course-explorer-what-ai"].tap()
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["A vivid example"].firstMatch.exists)
        XCTAssertTrue(app.staticTexts["Suggest: daisy"].exists)
        attachScreenshot(app, name: "Lesson example")
        let sources = app.staticTexts["Sources & further reading"]
        for _ in 0..<6 where !sources.isHittable { app.swipeUp() }
        XCTAssertTrue(sources.isHittable)
        XCTAssertTrue(app.staticTexts["Artificial Intelligence: Foundations of Computational Agents, 3rd ed."].firstMatch.exists)
        attachScreenshot(app, name: "Lesson sources")
    }

    private func attachScreenshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testOpensSettingsAndPrivacySummary() {
        let app = launchApp()
        tapTab("tab.library", label: "Library", in: app)
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 3))
        app.buttons["library.settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        app.staticTexts["Privacy summary"].tap()
        XCTAssertTrue(app.navigationBars["Privacy summary"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Stored on device"].exists)
    }

    func testOnboardingSupportsChineseAndLargeText() {
        let app = launchApp(arguments: [
            "-onboarding-ui-testing",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge"
        ])
        XCTAssertTrue(app.staticTexts["Learn AI clearly"].waitForExistence(timeout: 5))
        let chinese = app.buttons["简体中文"]
        XCTAssertTrue(chinese.waitForExistence(timeout: 3))
        chinese.tap()
        XCTAssertTrue(app.staticTexts["清晰学习 AI"].waitForExistence(timeout: 3))

        for _ in 0..<2 {
            let next = app.buttons["onboarding.continue"]
            XCTAssertTrue(next.waitForExistence(timeout: 3))
            next.tap()
        }
        XCTAssertTrue(app.buttons["开始学习"].waitForExistence(timeout: 3))
        app.buttons["开始学习"].tap()
        XCTAssertTrue(app.navigationBars["学习"].waitForExistence(timeout: 5))
    }

    func testAllFilterSurvivesReturningFromLesson() {
        let app = launchApp()
        tapTab("tab.library", label: "Library", in: app)
        app.buttons["library.settings"].tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Preferred level,")).firstMatch.tap()
        app.buttons["Beginner"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        tapTab("tab.learn", label: "Learn", in: app)
        app.buttons["All"].tap()
        app.buttons["lesson.course-explorer-what-ai"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let otherLevel = app.buttons["lesson.course-secondary-search"]
        reveal(otherLevel, in: app)
        XCTAssertTrue(otherLevel.exists)

    }

    func testSearchEmptyStateCanClearFilters() {
        let app = launchApp()
        let search = app.searchFields.firstMatch
        search.tap()
        search.typeText("zzzz-no-such-concept")
        XCTAssertTrue(app.staticTexts["No lessons found"].waitForExistence(timeout: 5))
        app.buttons["learn.clearFilters"].tap()
        XCTAssertTrue(app.buttons["lesson.course-explorer-what-ai"].waitForExistence(timeout: 5))
    }

    func testFailedQuizAppearsInReviewAndCanResume() {
        let app = launchApp()
        app.buttons["lesson.course-explorer-what-ai"].tap()
        app.buttons["lesson.startQuiz"].tap()
        for question in 0..<6 {
            let choice = app.buttons["quiz.choice.\((question + 1) % 3)"]
            reveal(choice, in: app)
            choice.tap()
            app.buttons["quiz.next"].tap()
            app.buttons["quiz.next"].tap()
        }
        XCTAssertTrue(app.staticTexts["You scored 0 of 6"].waitForExistence(timeout: 3))
        app.buttons["quiz.done"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["learn.continue"].waitForExistence(timeout: 3))
        app.buttons["learn.continue"].tap()
        XCTAssertTrue(app.buttons["lesson.startQuiz"].waitForExistence(timeout: 3))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        tapTab("tab.library", label: "Library", in: app)
        XCTAssertTrue(app.staticTexts["0 / 600"].waitForExistence(timeout: 3))
        let review = app.buttons["review.course-explorer-what-ai"]
        XCTAssertTrue(review.exists)
        review.tap()
        XCTAssertTrue(app.buttons["lesson.startQuiz"].waitForExistence(timeout: 3))
    }

    func testClosingStartedQuizRequiresConfirmation() {
        let app = launchApp()
        app.buttons["lesson.course-explorer-what-ai"].tap()
        app.buttons["lesson.startQuiz"].tap()
        let choice = app.buttons["quiz.choice.0"]
        reveal(choice, in: app)
        choice.tap()
        app.buttons["Close"].tap()
        XCTAssertTrue(app.alerts["Leave this quiz?"].waitForExistence(timeout: 3))
        app.alerts.buttons["Keep learning"].tap()
        XCTAssertTrue(app.buttons["quiz.next"].isEnabled)
        app.buttons["Close"].tap()
        app.alerts.buttons["Leave quiz"].tap()
        XCTAssertTrue(app.buttons["lesson.startQuiz"].waitForExistence(timeout: 3))
    }

    private func launchApp(arguments: [String] = ["-ui-testing"]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        return app
    }

    private func tapTab(_ identifier: String, label: String, in app: XCUIApplication) {
        let tab = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
        if tab.waitForExistence(timeout: 1) {
            tab.tap()
        } else {
            let phoneTab = app.tabBars.buttons[label]
            XCTAssertTrue(phoneTab.waitForExistence(timeout: 5), "Missing tab \(identifier)")
            phoneTab.tap()
        }
    }
}
