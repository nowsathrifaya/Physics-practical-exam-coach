//
//  FindTheMistakeView.swift
//  PhysicsPracticalCoach
//
//  New "Identify Graph Errors" practice mode for Graph Coach. Shows a
//  rendered graph containing one deliberately-introduced flaw (wrong scale,
//  missing unit, missing title, wrong axis label, an over-fitted line, or
//  a mis-plotted point) and asks the student to spot it from four choices,
//  then reveals an examiner-style explanation. Uses the same
//  `GraphDatasetGenerator`-produced datasets as the rest of Graph Coach, via
//  `GraphMistakeGenerator`, so difficulty and units stay consistent with
//  the guided wizard.
//

import SwiftUI

struct FindTheMistakeContainerView: View {
    let graphType: GraphCoachType
    let curriculum: Curriculum
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        FindTheMistakeView(
            graphType: graphType, curriculum: curriculum,
            repository: AttemptRepository(modelContext: modelContext)
        )
    }
}

@MainActor
@Observable
final class FindTheMistakeViewModel {
    private let generator = GraphMistakeGenerator()
    private let repository: AttemptRepository
    let graphType: GraphCoachType
    let curriculum: Curriculum

    private(set) var challenge: GraphMistakeChallenge
    private(set) var selected: GraphMistakeKind?
    private(set) var revealed = false

    init(graphType: GraphCoachType, curriculum: Curriculum, repository: AttemptRepository) {
        self.graphType = graphType
        self.curriculum = curriculum
        self.repository = repository
        self.challenge = generator.generate(type: graphType, curriculum: curriculum)
    }

    var isCorrect: Bool { selected == challenge.mistake }

    func select(_ kind: GraphMistakeKind) {
        guard !revealed else { return }
        selected = kind
    }

    func reveal() {
        guard selected != nil, !revealed else { return }
        revealed = true
        SoundManager.shared.play(isCorrect ? .success : .error)
        repository.save(
            curriculum: curriculum, mode: .graphCoach,
            target: "\(graphType.label) - find the mistake",
            score: isCorrect ? 100 : 40, maxScore: 100,
            feedback: [challenge.mistake.explanation]
        )
    }

    func next() {
        challenge = generator.generate(type: graphType, curriculum: curriculum)
        selected = nil
        revealed = false
    }
}

struct FindTheMistakeView: View {
    @State private var viewModel: FindTheMistakeViewModel

    init(graphType: GraphCoachType, curriculum: Curriculum, repository: AttemptRepository) {
        _viewModel = State(initialValue: FindTheMistakeViewModel(graphType: graphType, curriculum: curriculum, repository: repository))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("This graph has one mistake. Can you spot it?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                FlawedGraphView(challenge: viewModel.challenge)
                    .frame(height: 280)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.challenge.options, id: \.shortLabel) { option in
                        MistakeOptionRow(
                            option: option,
                            isSelected: viewModel.selected == option,
                            revealed: viewModel.revealed,
                            isAnswer: option == viewModel.challenge.mistake
                        ) {
                            viewModel.select(option)
                        }
                    }
                }

                if viewModel.revealed {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(
                            viewModel.isCorrect ? "Correct!" : "Not quite",
                            systemImage: viewModel.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill"
                        )
                        .font(.headline)
                        .foregroundStyle(viewModel.isCorrect ? .green : .red)
                        Text(viewModel.challenge.mistake.explanation)
                            .font(.footnote)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background((viewModel.isCorrect ? Color.green : Color.red).opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Button(viewModel.revealed ? "Next graph" : "Check answer") {
                    if viewModel.revealed {
                        viewModel.next()
                    } else {
                        viewModel.reveal()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .frame(maxWidth: .infinity)
                .disabled(!viewModel.revealed && viewModel.selected == nil)
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Find the Mistake")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MistakeOptionRow: View {
    let option: GraphMistakeKind
    let isSelected: Bool
    let revealed: Bool
    let isAnswer: Bool
    let action: () -> Void

    private var tint: Color {
        guard revealed else { return isSelected ? .purple : .secondary }
        if isAnswer { return .green }
        return isSelected ? .red : .secondary
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: revealed ? (isAnswer ? "checkmark.circle.fill" : (isSelected ? "xmark.circle.fill" : "circle")) : (isSelected ? "largecircle.fill.circle" : "circle"))
                    .foregroundStyle(tint)
                Text(option.shortLabel).font(.subheadline)
                Spacer()
            }
            .padding(12)
            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected && !revealed ? Color.purple : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(revealed)
    }
}

/// Renders the dataset with the challenge's flaw baked into the visuals:
/// a squeezed scale, a missing/wrong label, a missing title, a line joining
/// every point instead of a best-fit line, or one point nudged off-trend.
private struct FlawedGraphView: View {
    let challenge: GraphMistakeChallenge

    private var displayedPoints: [GraphPoint] {
        guard challenge.mistake == .wrongPlotting, let index = challenge.flawedPointIndex, let flawed = challenge.flawedPoint else {
            return challenge.dataset.points
        }
        var points = challenge.dataset.points
        points[index] = flawed
        return points
    }

    var body: some View {
        VStack(spacing: 4) {
            if challenge.mistake != .missingTitle {
                Text("\(challenge.definition.yLabel) vs \(challenge.definition.xLabel)")
                    .font(.caption.bold())
            }

            Canvas { context, size in
                let margin: CGFloat = 44
                let squeeze: CGFloat = challenge.mistake == .wrongScale ? 0.45 : 1.0
                let plotRect = CGRect(
                    x: margin, y: 12,
                    width: (size.width - margin - 12) * squeeze,
                    height: (size.height - margin - 24) * squeeze
                )

                guard let maxX = displayedPoints.map(\.x).max(), let maxY = displayedPoints.map(\.y).max(), maxX > 0, maxY > 0 else { return }

                drawGraphPaper(
                    context: context, plotRect: plotRect, maxX: maxX, maxY: maxY,
                    stepX: niceGridStep(for: maxX), stepY: niceGridStep(for: maxY)
                )

                var axes = Path()
                axes.move(to: CGPoint(x: plotRect.minX, y: plotRect.minY))
                axes.addLine(to: CGPoint(x: plotRect.minX, y: plotRect.maxY))
                axes.addLine(to: CGPoint(x: plotRect.maxX, y: plotRect.maxY))
                context.stroke(axes, with: .color(.primary), lineWidth: 1.5)

                func screenPoint(_ p: GraphPoint) -> CGPoint {
                    CGPoint(
                        x: plotRect.minX + CGFloat(p.x / maxX) * plotRect.width,
                        y: plotRect.maxY - CGFloat(p.y / maxY) * plotRect.height
                    )
                }

                if challenge.mistake == .overFittedLine {
                    var joined = Path()
                    let ordered = displayedPoints.sorted { $0.x < $1.x }
                    if let first = ordered.first { joined.move(to: screenPoint(first)) }
                    for p in ordered.dropFirst() { joined.addLine(to: screenPoint(p)) }
                    context.stroke(joined, with: .color(.purple), lineWidth: 2)
                } else {
                    let regression = LinearRegression.fit(displayedPoints.map { RegressionPoint(x: $0.x, y: $0.y) })
                    var line = Path()
                    line.move(to: screenPoint(GraphPoint(x: 0, y: LinearRegression.yAt(0, result: regression))))
                    line.addLine(to: screenPoint(GraphPoint(x: maxX, y: LinearRegression.yAt(maxX, result: regression))))
                    context.stroke(line, with: .color(.purple), lineWidth: 2)
                }

                for (index, p) in displayedPoints.enumerated() {
                    let center = screenPoint(p)
                    let isFlawed = challenge.mistake == .wrongPlotting && index == challenge.flawedPointIndex
                    var cross = Path()
                    cross.move(to: CGPoint(x: center.x - 4, y: center.y - 4))
                    cross.addLine(to: CGPoint(x: center.x + 4, y: center.y + 4))
                    cross.move(to: CGPoint(x: center.x - 4, y: center.y + 4))
                    cross.addLine(to: CGPoint(x: center.x + 4, y: center.y - 4))
                    context.stroke(cross, with: .color(isFlawed ? .red : .blue), lineWidth: 2)
                }

                let xLabel = challenge.mistake == .wrongAxisLabel ? challenge.definition.yLabel : challenge.definition.xLabel
                let xUnitSuffix = challenge.mistake == .missingUnit ? "" : (challenge.definition.xUnit.isEmpty ? "" : " (\(challenge.definition.xUnit))")
                let yUnitSuffix = challenge.definition.yUnit.isEmpty ? "" : " (\(challenge.definition.yUnit))"
                context.draw(Text(xLabel + xUnitSuffix).font(.caption2), at: CGPoint(x: plotRect.midX, y: size.height - 8))
                context.draw(
                    Text(challenge.definition.yLabel + yUnitSuffix).font(.caption2).italic(),
                    at: CGPoint(x: 8, y: plotRect.midY),
                    anchor: .center
                )
            }
        }
        .padding(12)
        .accessibilityLabel("Graph with one mistake to find")
    }
}
