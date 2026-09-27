import SwiftUI

struct LessonDetailView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: LocalStore
    @EnvironmentObject private var purchases: PurchaseManager
    let lesson: Lesson
    @State private var showQuiz = false

    var body: some View {
        if lesson.isFree || purchases.hasPro {
            lessonContent.onAppear { store.visit(lessonID: lesson.id) }
        } else {
            PaywallView()
        }
    }

    private var lessonContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Label(lesson.track.title.value(for: settings.language), systemImage: lesson.track.symbol)
                    .font(.subheadline.bold()).foregroundStyle(AppTheme.teal)
                Text(lesson.title.value(for: settings.language)).font(.largeTitle.bold()).foregroundStyle(AppTheme.navy)
                Text(lesson.summary.value(for: settings.language)).font(.title3).foregroundStyle(.secondary)
                keyIdea
                ForEach(lesson.sections.filter { $0.body != lesson.keyIdea || $0.example != nil }) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Label(section.title.value(for: settings.language), systemImage: section.symbol).font(.title2.bold())
                        if section.body != lesson.keyIdea, section.body != section.example {
                            Text(section.body.value(for: settings.language)).font(.body).lineSpacing(5)
                        }
                        if let example = section.example {
                            VStack(alignment: .leading, spacing: 8) {
                                Label(settings.text("A vivid example", "生动的例子"), systemImage: "text.bubble.fill")
                                    .font(.subheadline.bold()).foregroundStyle(AppTheme.teal)
                                Text(example.value(for: settings.language)).lineSpacing(5)
                                CourseExampleIllustration(sectionID: section.id)
                            }
                            .padding().frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.paleTeal, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
                }
                referenceSection
                Button {
                    showQuiz = true
                } label: {
                    Label(store.isCompleted(lesson.id) ? settings.text("Retake knowledge check", "重新测验") : settings.text("Start knowledge check", "开始测验"), systemImage: "checkmark.seal")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(AppTheme.action).controlSize(.large)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showQuiz = true } label: { Image(systemName: "checkmark.seal") }
                    .accessibilityLabel(settings.text("Start knowledge check", "开始知识测验"))
                    .accessibilityIdentifier("lesson.startQuiz")
            }
        }
        .sheet(isPresented: $showQuiz) { QuizView(lesson: lesson) }
    }

    private var referenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(settings.text("Sources & further reading", "来源与延伸阅读"), systemImage: "books.vertical")
                .font(.title2.bold())
            Text(settings.text("Original explanations, examples, and questions. The references below explain the underlying ideas; examples are illustrative, not reported research results.", "讲解、例子和习题均为原创编写。以下来源介绍相关原理；例子用于教学，不是论文实验结果。"))
                .font(.footnote).foregroundStyle(.secondary)
            ForEach(CurriculumCatalog.references(for: lesson)) { reference in
                Link(destination: reference.url) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(reference.title).font(.subheadline.bold()).foregroundStyle(AppTheme.teal)
                        Text("\(reference.authors) · \(reference.year)").font(.caption).foregroundStyle(Color.secondary)
                        Text(reference.locator).font(.caption).foregroundStyle(Color.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding().background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private var keyIdea: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(settings.text("Core content", "核心内容")).font(.caption.bold()).foregroundStyle(AppTheme.teal)
            Text(lesson.keyIdea.value(for: settings.language)).font(.title3.bold()).foregroundStyle(AppTheme.navy)
            Text(settings.text("Purpose: Explain this concept with an example, identify a useful application, and recognize its limits.", "目的：能结合例子解释这个概念，了解实际用途，并识别使用边界。"))
                .font(.footnote).foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.paleTeal, in: RoundedRectangle(cornerRadius: 18))
    }
}
