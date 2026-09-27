import SwiftUI

struct PagePurposeView: View {
    @EnvironmentObject private var settings: AppSettings
    let core: String
    let purpose: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(settings.text("Core content", "核心内容") + ": " + core)
            Text(settings.text("Purpose", "目的") + ": " + purpose)
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}

enum AppTheme {
    static let teal = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.25, green: 0.78, blue: 0.76, alpha: 1)
            : UIColor(red: 0.0, green: 0.51, blue: 0.51, alpha: 1)
    })
    static let navy = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.78, green: 0.93, blue: 0.96, alpha: 1)
            : UIColor(red: 0.04, green: 0.16, blue: 0.22, alpha: 1)
    })
    static let paleTeal = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.05, green: 0.22, blue: 0.23, alpha: 1)
            : UIColor(red: 0.90, green: 0.97, blue: 0.96, alpha: 1)
    })
}

struct SectionHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.title2.bold()).foregroundStyle(AppTheme.navy)
            if let subtitle { Text(subtitle).font(.subheadline).foregroundStyle(.secondary) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        ContentUnavailableView(title, systemImage: symbol, description: Text(message))
    }
}

struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.caption2.bold())
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .foregroundStyle(.white)
            .background(AppTheme.teal, in: Capsule())
            .accessibilityLabel("Pro")
    }
}
