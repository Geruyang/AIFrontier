import SwiftUI

struct QuizView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: LocalStore
    let lesson: Lesson
    @State private var index = 0
    @State private var selected: Int?
    @State private var score = 0
    @State private var complete = false
    @State private var checked = false

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    if complete { resultView.id("top") } else { questionView.id("top") }
                }
                .onChange(of: index) { _, _ in proxy.scrollTo("top", anchor: .top) }
                .onChange(of: complete) { _, _ in proxy.scrollTo("top", anchor: .top) }
            }
            .padding()
            .safeAreaInset(edge: .bottom) {
                if !complete {
                    Button(settings.text(checked ? (index == lesson.questions.count - 1 ? "Finish" : "Next") : "Check answer", checked ? (index == lesson.questions.count - 1 ? "完成" : "下一题") : "检查答案")) { submit() }
                        .buttonStyle(.borderedProminent).controlSize(.large)
                        .disabled(selected == nil)
                        .accessibilityIdentifier("quiz.next")
                        .frame(maxWidth: .infinity).padding().background(.regularMaterial)
                }
            }
            .navigationTitle(settings.text("Knowledge check", "知识测验"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(settings.text("Close", "关闭")) { dismiss() } } }
        }
        .interactiveDismissDisabled(!complete)
    }

    private var questionView: some View {
        let question = lesson.questions[index]
        return VStack(alignment: .leading, spacing: 18) {
            ProgressView(value: Double(index + 1), total: Double(lesson.questions.count))
            Text(settings.text("Question \(index + 1) of \(lesson.questions.count)", "第 \(index + 1) / \(lesson.questions.count) 题"))
                .font(.caption).foregroundStyle(.secondary)
            PagePurposeView(core: settings.text("Questions about ", "围绕以下主题的习题：") + lesson.title.value(for: settings.language), purpose: settings.text("Use the linked example to check your understanding, then learn from the answer explanation.", "结合对应例子检查理解，通过答案解释查漏补缺。"))
            Text(question.prompt.value(for: settings.language)).font(.title2.bold())
            if let section = lesson.sections.first(where: { $0.id == question.contextSectionID }) {
                VStack(alignment: .leading, spacing: 8) {
                    Label(settings.text("Example for this question", "本题对应的例子"), systemImage: "text.bubble")
                        .font(.headline).foregroundStyle(AppTheme.teal)
                    Text(lesson.title.value(for: settings.language)).font(.caption).foregroundStyle(.secondary)
                    Text(section.title.value(for: settings.language)).font(.subheadline.bold())
                    if let example = question.context ?? section.example { Text(example.value(for: settings.language)).lineSpacing(4) }
                }
                .padding().frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.paleTeal, in: RoundedRectangle(cornerRadius: 14))
                .accessibilityIdentifier("quiz.context")
            }
            ForEach(question.choices.indices, id: \.self) { choiceIndex in
                Button {
                    selected = choiceIndex
                } label: {
                    HStack {
                        Image(systemName: selected == choiceIndex ? "largecircle.fill.circle" : "circle")
                        Text(question.choices[choiceIndex].value(for: settings.language)).multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding()
                    .background(selected == choiceIndex ? AppTheme.paleTeal : Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(checked)
                .accessibilityIdentifier("quiz.choice.\(choiceIndex)")
            }
            if checked {
                VStack(alignment: .leading, spacing: 10) {
                    Label(selected == question.correctIndex ? settings.text("Correct", "回答正确") : settings.text("Let's review", "一起复习"), systemImage: selected == question.correctIndex ? "checkmark.circle.fill" : "lightbulb.fill")
                        .font(.headline).foregroundStyle(AppTheme.teal)
                    Text(settings.text("Answer: ", "答案：") + question.choices[question.correctIndex].value(for: settings.language)).bold()
                    Text(question.explanation.value(for: settings.language)).lineSpacing(4)
                }
                .padding().frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.paleTeal, in: RoundedRectangle(cornerRadius: 14))
                .accessibilityIdentifier("quiz.feedback")
            }
        }
    }

    private var resultView: some View {
        VStack(spacing: 20) {
            Image(systemName: passed ? "checkmark.seal.fill" : "arrow.clockwise.circle.fill")
                .font(.system(size: 70)).foregroundStyle(passed ? AppTheme.teal : .orange)
            Text(settings.text("You scored \(score) of \(lesson.questions.count)", "得分：\(score) / \(lesson.questions.count)")).font(.largeTitle.bold())
            PagePurposeView(core: settings.text("Your score for ", "本次测验成绩：") + lesson.title.value(for: settings.language), purpose: settings.text("Decide whether to continue learning or review the lesson and try again.", "判断是否继续学习，或复习课程后再次测验。"))
            Text(passed ? settings.text("Good work. Explain one counterexample before moving on.", "完成得很好。继续前，请尝试解释一个反例。") : settings.text("Review the key idea and try again.", "复习关键观点后再试一次。"))
                .foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button(settings.text("Done", "完成")) { dismiss() }
                .buttonStyle(.borderedProminent).controlSize(.large)
                .accessibilityIdentifier("quiz.done")
        }
        .frame(maxHeight: .infinity)
    }

    private var passed: Bool {
        score * 3 >= lesson.questions.count * 2
    }

    private func submit() {
        guard let selected else { return }
        if !checked {
            if selected == lesson.questions[index].correctIndex { score += 1 }
            checked = true
            return
        }
        if index == lesson.questions.count - 1 {
            store.complete(lessonID: lesson.id, score: score)
            complete = true
        } else {
            index += 1
            self.selected = nil
            checked = false
        }
    }
}
