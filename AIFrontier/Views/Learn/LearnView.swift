import SwiftUI

struct LearnView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: LocalStore
    @EnvironmentObject private var purchases: PurchaseManager
    @State private var selectedLevel: AudienceLevel?
    @State private var showPaywall = false
    @State private var searchText = ""
    @State private var visibleLimits: [String: Int] = [:]

    private var filteredLessons: [Lesson] {
        CurriculumCatalog.matchingLessons(query: searchText, level: selectedLevel)
    }

    private var progress: Double {
        Double(completedCount) / Double(CurriculumCatalog.lessons.count)
    }

    private var completedCount: Int {
        let lessonIDs = Set(CurriculumCatalog.lessons.map(\.id))
        return store.data.completedLessonIDs.intersection(lessonIDs).count
    }

    var body: some View {
        let matching = filteredLessons
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 22) {
                    progressCard.id("learn.top")
                    levelPicker
                    ForEach(CourseTrack.allCases) { track in
                        let lessons = matching.filter { $0.track == track }
                        if !lessons.isEmpty { trackSection(track, lessons: lessons) }
                    }
                }
                .padding()
            }
            .onChange(of: searchText) { _, _ in proxy.scrollTo("learn.top", anchor: .top) }
            .onChange(of: selectedLevel) { _, _ in proxy.scrollTo("learn.top", anchor: .top) }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(settings.text("Learn", "学习"))
        .searchable(text: $searchText, prompt: settings.text("Search concepts and applications", "搜索概念与应用"))
        .navigationDestination(for: Lesson.self) { LessonDetailView(lesson: $0) }
        .toolbar {
            if !purchases.hasPro {
                Button { showPaywall = true } label: { ProBadge() }
                    .accessibilityIdentifier("learn.pro")
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onAppear { selectedLevel = selectedLevel ?? settings.preferredLevel }
        .onChange(of: settings.preferredLevel) { _, newLevel in selectedLevel = newLevel }
        .onChange(of: selectedLevel) { _, _ in visibleLimits = [:] }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(settings.text("Your learning path", "你的学习路径")).font(.headline)
                    Text(settings.text("\(completedCount) of \(CurriculumCatalog.lessons.count) lessons complete", "已完成 \(completedCount) / \(CurriculumCatalog.lessons.count) 节"))
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Text(progress, format: .percent.precision(.fractionLength(0))).font(.title.bold()).foregroundStyle(AppTheme.teal)
            }
            ProgressView(value: progress).tint(AppTheme.teal)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityIdentifier("learn.progress")
    }

    private var levelPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(settings.text("Learning levels", "学习级别"), subtitle: settings.text("Choose by your experience and learning goals.", "按已有经验与学习目标选择。"))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    levelButton(nil, label: settings.text("All", "全部"))
                    ForEach(AudienceLevel.allCases) { level in levelButton(level, label: level.label.value(for: settings.language)) }
                }
            }
            PagePurposeView(
                core: selectedLevel?.coreContent.value(for: settings.language) ?? settings.text("600 lessons across Beginner, Fundamentals, and Advanced, with concepts and practical examples.", "入门、基础、进阶共 600 节课程，涵盖核心概念与实际案例。"),
                purpose: selectedLevel?.purpose.value(for: settings.language) ?? settings.text("Choose a suitable starting point and build the skills to understand and apply AI.", "找到适合自己的起点，逐步建立理解和应用 AI 的能力。")
            )
            .accessibilityIdentifier("learn.levelPurpose")
        }
    }

    private func levelButton(_ level: AudienceLevel?, label: String) -> some View {
        Button(label) { selectedLevel = level }
            .buttonStyle(.borderedProminent)
            .tint(selectedLevel == level ? AppTheme.teal : Color(.tertiarySystemFill))
            .foregroundStyle(selectedLevel == level ? .white : AppTheme.navy)
    }

    @ViewBuilder
    private func trackSection(_ track: CourseTrack, lessons: [Lesson]) -> some View {
        let isSearching = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let limit = isSearching ? lessons.count : min(visibleLimits[track.id] ?? 8, lessons.count)
        LazyVStack(alignment: .leading, spacing: 10) {
            Label(track.title.value(for: settings.language), systemImage: track.symbol)
                .font(.title2.bold()).foregroundStyle(AppTheme.navy)
            PagePurposeView(core: track.coreContent.value(for: settings.language), purpose: track.purpose.value(for: settings.language))
            ForEach(Array(lessons.prefix(limit))) { lesson in
                if lesson.isFree || purchases.hasPro {
                    NavigationLink(value: lesson) { LessonRow(lesson: lesson, locked: false) }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("lesson.\(lesson.id)")
                } else {
                    Button { showPaywall = true } label: { LessonRow(lesson: lesson, locked: true) }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("lesson.\(lesson.id)")
                }
            }
            if limit < lessons.count {
                Button(settings.text("Show \(min(10, lessons.count - limit)) more · \(limit) of \(lessons.count) shown", "再显示 \(min(10, lessons.count - limit)) 节 · 已显示 \(limit) / \(lessons.count) 节")) {
                    visibleLimits[track.id] = limit + 10
                }
                .buttonStyle(.bordered).frame(maxWidth: .infinity)
                .accessibilityIdentifier("learn.more.\(track.id)")
            }
        }
    }
}

private struct LessonRow: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: LocalStore
    let lesson: Lesson
    let locked: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(AppTheme.paleTeal).frame(width: 52, height: 52)
                Image(systemName: store.isCompleted(lesson.id) ? "checkmark.circle.fill" : lesson.track.symbol).foregroundStyle(AppTheme.teal)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.title.value(for: settings.language)).font(.headline).foregroundStyle(.primary)
                HStack {
                    Text(lesson.level.label.value(for: settings.language))
                    Text("·")
                    Text(settings.text("\(lesson.estimatedMinutes) min", "\(lesson.estimatedMinutes) 分钟"))
                    if let score = store.score(for: lesson.id) { Text("· \(score)/\(lesson.questions.count)") }
                }
                .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: locked ? "lock.fill" : "chevron.right").foregroundStyle(.tertiary)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
    }
}
