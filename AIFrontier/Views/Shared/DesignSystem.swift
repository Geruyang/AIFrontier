import SwiftUI

/// Learning objectives are useful context; operational explanations belong in settings.
struct PagePurposeView: View {
    @EnvironmentObject private var settings: AppSettings
    let core: String
    let purpose: String

    var body: some View {
        DisclosureGroup(settings.text("What you'll learn", "学习目标")) {
            VStack(alignment: .leading, spacing: 8) {
                Text(core)
                Text(purpose).foregroundStyle(.secondary)
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
        }
        .font(.subheadline)
        .tint(AppTheme.teal)
    }
}

enum AppTheme {
    static let teal = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.32, green: 0.88, blue: 0.81, alpha: 1)
            : UIColor(red: 0.0, green: 0.43, blue: 0.41, alpha: 1)
    })
    static let action = Color(red: 0, green: 0.43, blue: 0.41)
    static let navy = Color.primary
    static let violet = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.71, green: 0.64, blue: 1, alpha: 1)
            : UIColor(red: 0.36, green: 0.25, blue: 0.78, alpha: 1)
    })
    static let canvas = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.035, green: 0.045, blue: 0.075, alpha: 1)
            : UIColor(red: 0.955, green: 0.964, blue: 0.984, alpha: 1)
    })
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let paleTeal = teal.opacity(0.09)
    static let hero = LinearGradient(colors: [Color(red: 0.07, green: 0.12, blue: 0.25), Color(red: 0.18, green: 0.13, blue: 0.38)], startPoint: .topLeading, endPoint: .bottomTrailing)
}

struct FrontierHero<Content: View>: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(eyebrow.uppercased()).font(.caption.weight(.bold)).tracking(2.4)
                .foregroundStyle(Color(red: 0.53, green: 0.96, blue: 0.88))
            Text(title).font(.system(.largeTitle, design: .rounded, weight: .bold)).fixedSize(horizontal: false, vertical: true)
            if !subtitle.isEmpty { Text(subtitle).font(.subheadline).foregroundStyle(.white.opacity(0.85)) }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .foregroundStyle(.white)
        .background {
            ZStack(alignment: .topTrailing) {
                AppTheme.hero
                OrbitArtwork().frame(width: 190, height: 190).offset(x: 55, y: -60).opacity(0.35)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }
}

private struct OrbitArtwork: View {
    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                Ellipse().strokeBorder(.white.opacity(0.6), lineWidth: 1)
                    .frame(width: 170, height: 75).rotationEffect(.degrees(Double(index) * 60))
            }
            Circle().fill(Color.cyan.opacity(0.65)).frame(width: 30, height: 30).blur(radius: 8)
            Circle().fill(.white).frame(width: 7, height: 7).offset(x: 58, y: -42)
        }.accessibilityHidden(true)
    }
}

struct SurfaceCard: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(18)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(.primary.opacity(0.045)))
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String?
    init(_ title: String, subtitle: String? = nil) { self.title = title; self.subtitle = subtitle }
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(.title2, design: .rounded, weight: .bold))
            if let subtitle { Text(subtitle).font(.subheadline).foregroundStyle(.secondary) }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var body: some View { ContentUnavailableView(title, systemImage: symbol, description: Text(message)) }
}

struct ProBadge: View {
    var body: some View {
        Text("PRO").font(.caption2.bold()).tracking(1)
            .padding(.horizontal, 10).padding(.vertical, 7)
            .foregroundStyle(AppTheme.violet)
            .background(AppTheme.violet.opacity(0.12), in: Capsule())
            .accessibilityLabel("Pro")
    }
}
