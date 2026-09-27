import XCTest
@testable import AIFrontier

@MainActor
final class AppSettingsTests: XCTestCase {
    func testDefaultsToEnglishAndPersistsChoice() {
        let suite = "AppSettingsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = AppSettings(defaults: defaults)
        XCTAssertEqual(settings.language, .english)
        settings.language = .simplifiedChinese
        XCTAssertEqual(AppSettings(defaults: defaults).language, .simplifiedChinese)
    }
}

