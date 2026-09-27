import Foundation
import SwiftUI

@MainActor
final class AppSettings: ObservableObject {
    @Published var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Keys.language) }
    }
    @Published var preferredLevel: AudienceLevel? {
        didSet { defaults.set(preferredLevel?.rawValue, forKey: Keys.level) }
    }
    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.onboarding) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let language = "app.language"
        static let level = "app.preferredLevel"
        static let onboarding = "app.hasCompletedOnboarding"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let arguments = ProcessInfo.processInfo.arguments
        let isOnboardingUITesting = arguments.contains("-onboarding-ui-testing")
        let isUITesting = arguments.contains("-ui-testing") || arguments.contains("-storekit-ui-testing") || isOnboardingUITesting
        language = arguments.contains("-chinese-news-ui-testing") ? .simplifiedChinese : (isUITesting ? .english : (AppLanguage(rawValue: defaults.string(forKey: Keys.language) ?? "") ?? .english))
        let oldLevel = defaults.string(forKey: Keys.level) ?? ""
        preferredLevel = oldLevel == "research" ? .university : AudienceLevel(rawValue: oldLevel)
        hasCompletedOnboarding = isOnboardingUITesting ? false : defaults.bool(forKey: Keys.onboarding)
    }

    func text(_ english: String, _ chinese: String) -> String {
        language == .english ? english : chinese
    }
}
