import SwiftUI

/// Original, local illustrations for examples where a diagram clarifies the idea.
struct CourseExampleIllustration: View {
    @EnvironmentObject private var settings: AppSettings
    let sectionID: String

    @ViewBuilder var body: some View {
        switch sectionID {
        case "course-explorer-what-ai-concept-1":
            flow([
                ("camera", settings.text("Flower photo", "花朵照片")),
                ("sparkles", settings.text("Suggest: daisy", "提示：雏菊")),
                ("eye", settings.text("Check petals", "检查花瓣"))
            ])
        case "course-explorer-pixels-concept-1":
            VStack(spacing: 8) {
                Grid(horizontalSpacing: 3, verticalSpacing: 3) {
                    ForEach(0..<4) { row in
                        GridRow {
                            ForEach(0..<4) { column in
                                Rectangle().fill(isDark(row, column) ? Color.black : Color.yellow)
                                    .frame(width: 32, height: 32)
                            }
                        }
                    }
                }
                Text("4 × 4 = 16").font(.headline.monospaced())
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(settings.text("Four by four pixel picture, sixteen pixels", "4乘4像素图，共16像素"))
        case "course-explorer-routes-concept-2":
            flow([
                ("building.2", settings.text("School", "学校")),
                ("tree", settings.text("Park", "公园")),
                ("books.vertical", settings.text("Library", "图书馆"))
            ])
        case "course-secondary-linear-fit-concept-1":
            equation("y = 2x + 5", "x = 3 → y = 11")
        case "course-secondary-loss-concept-2":
            equation("w = 3, ∇L = 6", "3 − 0.1 × 6 = 2.4")
        case "course-secondary-metrics-concept-2":
            VStack(alignment: .leading, spacing: 8) {
                Text(settings.text("8 found · 2 false alarms · 2 missed", "检出8 · 误报2 · 漏报2")).font(.subheadline.bold())
                Text(settings.text("Precision = 8 / (8 + 2) = 80%", "精确率 = 8 / (8 + 2) = 80%"))
                Text(settings.text("Recall = 8 / (8 + 2) = 80%", "召回率 = 8 / (8 + 2) = 80%"))
            }.font(.subheadline.monospaced())
        case "course-university-transformer-concept-1":
            VStack(alignment: .leading, spacing: 10) {
                weightBar(value: "2", weight: 0.25)
                weightBar(value: "6", weight: 0.75)
                Text("0.25 × 2 + 0.75 × 6 = 5").font(.subheadline.monospaced().bold())
            }
        case "course-university-diffusion-model-concept-3":
            flow([
                ("circle.dotted", settings.text("Noise", "噪声")),
                ("arrow.triangle.2.circlepath", settings.text("Reverse steps", "反向步骤")),
                ("photo", settings.text("Sample", "样本"))
            ])
        default:
            EmptyView()
        }
    }

    private func flow(_ stages: [(String, String)]) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                ForEach(stages.indices, id: \.self) { index in
                    if index > 0 { Image(systemName: "arrow.right").foregroundStyle(.secondary) }
                    stage(stages[index])
                }
            }
            VStack(spacing: 8) {
                ForEach(stages.indices, id: \.self) { index in
                    if index > 0 { Image(systemName: "arrow.down").foregroundStyle(.secondary) }
                    stage(stages[index])
                }
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 8)
    }

    private func stage(_ item: (String, String)) -> some View {
        VStack(spacing: 8) {
            Image(systemName: item.0).font(.title).foregroundStyle(AppTheme.teal).accessibilityHidden(true)
            Text(item.1).font(.caption.bold()).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
        }
        .padding(10).background(.background, in: RoundedRectangle(cornerRadius: 10))
    }

    private func equation(_ formula: String, _ substitution: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(formula).font(.headline.monospaced())
            Text(substitution).font(.subheadline.monospaced())
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
    }

    private func weightBar(value: String, weight: Double) -> some View {
        HStack {
            Text(settings.text("Value ", "值 ") + value).font(.caption.monospaced()).frame(width: 70, alignment: .leading)
            GeometryReader { proxy in
                RoundedRectangle(cornerRadius: 4).fill(AppTheme.teal)
                    .frame(width: proxy.size.width * weight)
            }.frame(height: 12)
            Text(weight.formatted(.percent)).font(.caption.monospaced()).frame(width: 45)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.text("Value \(value), weight \(weight.formatted(.percent))", "值\(value)，权重\(weight.formatted(.percent))"))
    }

    private func isDark(_ row: Int, _ column: Int) -> Bool {
        (row == 1 && (column == 0 || column == 3)) || (row == 3 && (column == 1 || column == 2))
    }
}
