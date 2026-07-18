//
//  GraphCoachView.swift
//  PhysicsPracticalCoach
//
//  Replaces `GraphCoachListFragment` + `GraphCoachPracticeFragment`. Renders
//  the generated scatter dataset with a native `Canvas`, takes the
//  student's gradient estimate, and marks it via `GraphGradientMarker`.
//
//  Redesigned into a 7-step exam-style wizard (scale -> labels -> units ->
//  plot -> best-fit line -> gradient -> examiner report) with live
//  checklist feedback, interactive tap-to-plot, a tap-two-points gradient
//  triangle tool, and focused practice modes. The original dataset
//  generation and gradient-marking logic (`GraphDatasetGenerator`,
//  `GraphGradientMarker`) is untouched and reused as-is for step 6/7, and
//  `ScatterPlotCanvasView` is kept exactly as before since four other lab
//  views (`OhmsLawLabView`, `PotentiometerLabView`, `SpringLabView`,
//  `LensLabView`) render their own student datasets with it.
//

import SwiftUI

// MARK: - Graph paper rendering

/// A sensible "units per grid square" step close to `maxValue / targetSquares`,
/// rounded to 1, 2, 5, or 10 × a power of ten — the same rule real graph
/// paper and exam mark schemes use, so auto-picked grids never land on an
/// awkward step like 3 or 7.
func niceGridStep(for maxValue: Double, targetSquares: Double = 8) -> Double {
    let raw = max(maxValue, 0.0001) / targetSquares
    let magnitude = pow(10, floor(log10(raw)))
    let residual = raw / magnitude
    let niceResidual: Double = residual <= 1.5 ? 1 : (residual <= 3.5 ? 2 : (residual <= 7.5 ? 5 : 10))
    return niceResidual * magnitude
}

func formatGridTick(_ value: Double) -> String {
    if abs(value.rounded() - value) < 0.0001 {
        return String(Int(value.rounded()))
    }
    return String(format: "%.2g", value)
}

/// Draws real-graph-paper-style axes: each major square (one `stepX`/`stepY`
/// unit — the scale the student chose) is subdivided into `minorDivisions`
/// finer, unlabeled minor gridlines, with darker major gridlines and a
/// numbered tick label at every major line (e.g. 0, 2, 4, 6, 8, 10). This
/// mirrors real exam graph paper: fine squares for precise plotting, with
/// only the major lines carrying numbers.
func drawGraphPaper(
    context: GraphicsContext,
    plotRect: CGRect,
    maxX: Double,
    maxY: Double,
    stepX: Double,
    stepY: Double,
    minorDivisions: Int = 5
) {
    guard stepX > 0, stepY > 0, maxX > 0, maxY > 0 else { return }
    let majorColumns = max(1, Int((maxX / stepX).rounded()))
    let majorRows = max(1, Int((maxY / stepY).rounded()))
    let minorColumns = majorColumns * minorDivisions
    let minorRows = majorRows * minorDivisions

    var minor = Path()
    var major = Path()

    for c in 0...minorColumns {
        let x = plotRect.minX + plotRect.width * CGFloat(c) / CGFloat(minorColumns)
        var line = Path()
        line.move(to: CGPoint(x: x, y: plotRect.minY))
        line.addLine(to: CGPoint(x: x, y: plotRect.maxY))
        if c % minorDivisions == 0 { major.addPath(line) } else { minor.addPath(line) }
    }
    for r in 0...minorRows {
        // r = 0 at the bottom (the origin), increasing upward — matches
        // domain values, which grow upward on the screen.
        let y = plotRect.maxY - plotRect.height * CGFloat(r) / CGFloat(minorRows)
        var line = Path()
        line.move(to: CGPoint(x: plotRect.minX, y: y))
        line.addLine(to: CGPoint(x: plotRect.maxX, y: y))
        if r % minorDivisions == 0 { major.addPath(line) } else { minor.addPath(line) }
    }

    context.stroke(minor, with: .color(.secondary.opacity(0.2)), lineWidth: 0.5)
    context.stroke(major, with: .color(.secondary.opacity(0.6)), lineWidth: 1)

    for c in stride(from: 0, through: minorColumns, by: minorDivisions) {
        let x = plotRect.minX + plotRect.width * CGFloat(c) / CGFloat(minorColumns)
        context.draw(
            Text(formatGridTick(Double(c / minorDivisions) * stepX)).font(.system(size: 9)).foregroundStyle(.secondary),
            at: CGPoint(x: x, y: plotRect.maxY + 11)
        )
    }
    for r in stride(from: 0, through: minorRows, by: minorDivisions) {
        let y = plotRect.maxY - plotRect.height * CGFloat(r) / CGFloat(minorRows)
        context.draw(
            Text(formatGridTick(Double(r / minorDivisions) * stepY)).font(.system(size: 9)).foregroundStyle(.secondary),
            at: CGPoint(x: plotRect.minX - 15, y: y)
        )
    }
}

struct GraphCoachListView: View {
    let profile: CurriculumProfile
    @State private var practiceMode: GraphCoachPracticeMode = .fullExam
    @State private var tip = GraphExamTips.random()

    var body: some View {
        List {
            Section {
                Text(tip)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 2)
            } header: {
                Label("Exam tip", systemImage: "lightbulb.fill")
            }

            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(GraphCoachPracticeMode.allCases) { mode in
                            ModeChip(mode: mode, isSelected: mode == practiceMode) {
                                withAnimation(.snappy) { practiceMode = mode }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .listRowInsets(EdgeInsets())
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            } header: {
                Text("Practice mode")
            }

            Section {
                ForEach(profile.graphTypes) { type in
                    NavigationLink {
                        destination(for: type)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(type.label).font(.headline)
                            Text(type.definition.gradientMeaning).font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                Text("Graph type")
            }
        }
        .navigationTitle("Graph Coach")
    }

    @ViewBuilder
    private func destination(for type: GraphCoachType) -> some View {
        if practiceMode == .identifyErrors {
            FindTheMistakeContainerView(graphType: type, curriculum: profile.curriculum)
        } else {
            GraphCoachPracticeContainerView(graphType: type, curriculum: profile.curriculum, mode: practiceMode)
        }
    }
}

private struct ModeChip: View {
    let mode: GraphCoachPracticeMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(mode.label, systemImage: mode.systemImage)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Color.purple : Color(.secondarySystemGroupedBackground),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

struct GraphCoachPracticeContainerView: View {
    let graphType: GraphCoachType
    let curriculum: Curriculum
    var mode: GraphCoachPracticeMode = .fullExam
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        GraphCoachPracticeView(
            graphType: graphType, curriculum: curriculum,
            repository: AttemptRepository(modelContext: modelContext),
            mode: mode
        )
    }
}

@MainActor
@Observable
final class GraphCoachPracticeViewModel {
    private let generator = GraphDatasetGenerator()
    private let marker = GraphGradientMarker()
    private let repository: AttemptRepository
    let graphType: GraphCoachType
    let curriculum: Curriculum
    let mode: GraphCoachPracticeMode
    let examTip = GraphExamTips.random()

    private(set) var dataset: GraphDataset
    var studentGradientInput: String = ""
    private(set) var result: GraphGradientResult?

    /// The ordered wizard steps this session walks through (a focused
    /// subset for drill modes, or all seven for Full Exam Practice).
    let steps: [Int]
    private(set) var stepIndex = 0
    private(set) var finished = false

    // Step 1 — scale (independent per axis, since X and Y ranges can differ
    // in magnitude by a lot — e.g. extension in metres vs force in newtons —
    // and forcing one shared "units per square" value onto both axes left
    // whichever axis had the smaller range with almost no gridlines at all).
    var selectedScaleX: Double?
    var selectedScaleY: Double?
    // Step 2 — axis labels
    var xAxisLabelInput = ""
    var yAxisLabelInput = ""
    // Step 3 — units
    var xUnitInput = ""
    var yUnitInput = ""
    var titleInput = ""
    // Step 4 — plotted points (student-entered, in real data units)
    var plottedPoints: [GraphPoint] = []
    // Step 5 — best-fit line, stored as fractional plot-space endpoints
    // (0,0) = top-left of the plot area, (1,1) = bottom-right, so the line
    // is resolution independent.
    var lineStart = CGPoint(x: 0.10, y: 0.82)
    var lineEnd = CGPoint(x: 0.88, y: 0.18)
    // Step 6 — the two points the student tapped on their line to build the
    // gradient triangle, in the same fractional plot-space.
    var gradientTapA: CGPoint?
    var gradientTapB: CGPoint?

    init(
        graphType: GraphCoachType, curriculum: Curriculum, repository: AttemptRepository,
        mode: GraphCoachPracticeMode = .fullExam
    ) {
        self.graphType = graphType
        self.curriculum = curriculum
        self.repository = repository
        self.mode = mode
        self.steps = mode.steps.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : mode.steps
        self.dataset = generator.generate(type: graphType, seed: Int.random(in: 0...Int(Int32.max)), curriculum: curriculum)
        prefillSkippedSteps()
    }

    private var def: GraphCoachType.Definition { graphType.definition }

    /// Modes that jump into the middle of the workflow (e.g. "Calculate
    /// Gradient" starting at step 6) pre-fill every earlier step correctly,
    /// so the checklist and final report still make sense without forcing
    /// the student to redo work outside the mode's focus.
    private func prefillSkippedSteps() {
        let firstStep = steps.first ?? 1
        if firstStep > 1 {
            selectedScaleX = niceScaleCandidates(for: axisMaxX).last
            selectedScaleY = niceScaleCandidates(for: axisMaxY).last
            xAxisLabelInput = def.xLabel
            yAxisLabelInput = def.yLabel
            xUnitInput = def.xUnit
            yUnitInput = def.yUnit
            titleInput = "\(def.yLabel) vs \(def.xLabel)"
        }
        if firstStep > 4 {
            plottedPoints = dataset.points
        }
        if firstStep > 5 {
            let regression = LinearRegression.fit(dataset.points.map { RegressionPoint(x: $0.x, y: $0.y) })
            lineStart = fractionalPoint(x: 0, y: LinearRegression.yAt(0, result: regression))
            lineEnd = fractionalPoint(x: axisMaxX, y: LinearRegression.yAt(axisMaxX, result: regression))
        }
    }

    // MARK: - Axis scaling helpers, shared with the interactive canvases

    var axisMaxX: Double { max(dataset.points.map(\.x).max() ?? 1, 0.001) * 1.15 }
    var axisMaxY: Double { max(dataset.points.map(\.y).max() ?? 1, 0.001) * 1.15 }

    /// A handful of sensible "units per grid square" choices for the scale
    /// step, spanning from cramped to a good exam-style scale.
    func niceScaleCandidates(for maxValue: Double) -> [Double] {
        let rawStep = maxValue / 8.0
        let magnitude = pow(10, floor(log10(max(rawStep, 1e-9))))
        let bases: [Double] = [1, 2, 5, 10]
        return bases.map { $0 * magnitude }
    }

    /// The exam-marking heuristic: a good scale uses more than half the
    /// graph paper, i.e. the data spans at least ~5 grid squares.
    func isGoodScale(_ scale: Double, maxValue: Double) -> Bool {
        let squares = maxValue / scale
        return squares >= 5 && squares <= 12
    }

    func fractionalPoint(x: Double, y: Double) -> CGPoint {
        CGPoint(x: x / axisMaxX, y: 1 - (y / axisMaxY))
    }

    func domainPoint(fraction: CGPoint) -> GraphPoint {
        GraphPoint(x: fraction.x * axisMaxX, y: (1 - fraction.y) * axisMaxY)
    }

    // MARK: - Live checklist (updates instantly as the student works)

    var scaleChosen: Bool { selectedScaleX != nil && selectedScaleY != nil }
    var scaleOK: Bool {
        guard let sx = selectedScaleX, let sy = selectedScaleY else { return false }
        return isGoodScale(sx, maxValue: axisMaxX) && isGoodScale(sy, maxValue: axisMaxY)
    }

    var xLabelOK: Bool {
        xAxisLabelInput.trimmingCharacters(in: .whitespaces).lowercased()
            .contains(def.xLabel.lowercased())
    }
    var yLabelOK: Bool {
        yAxisLabelInput.trimmingCharacters(in: .whitespaces).lowercased()
            .contains(def.yLabel.lowercased())
    }
    var labelsOK: Bool { xLabelOK && yLabelOK }

    var xUnitOK: Bool {
        def.xUnit.isEmpty || xUnitInput.trimmingCharacters(in: .whitespaces).lowercased() == def.xUnit.lowercased()
    }
    var yUnitOK: Bool {
        def.yUnit.isEmpty || yUnitInput.trimmingCharacters(in: .whitespaces).lowercased() == def.yUnit.lowercased()
    }
    var unitsOK: Bool { xUnitOK && yUnitOK }

    var titleOK: Bool { !titleInput.trimmingCharacters(in: .whitespaces).isEmpty }

    /// Fraction of the student's plotted points that land within a small
    /// tolerance of *some* unmatched real data point — order-independent,
    /// since a student tapping points in a different order than the
    /// dataset's internal x-ascending order is not a plotting mistake.
    var plottingAccuracy: Double {
        guard !plottedPoints.isEmpty else { return 0 }
        let tolerance = max(axisMaxX, axisMaxY) * 0.05
        var unmatched = dataset.points
        var matches = 0
        for student in plottedPoints {
            guard let closestIndex = unmatched.indices.min(by: { a, b in
                distance(student, unmatched[a]) < distance(student, unmatched[b])
            }) else { break }
            if distance(student, unmatched[closestIndex]) <= tolerance {
                matches += 1
                unmatched.remove(at: closestIndex)
            }
        }
        return Double(matches) / Double(dataset.points.count)
    }
    private func distance(_ a: GraphPoint, _ b: GraphPoint) -> Double {
        hypot((a.x - b.x) / max(axisMaxX, 0.001), (a.y - b.y) / max(axisMaxY, 0.001)) * max(axisMaxX, axisMaxY)
    }
    var plottingOK: Bool { plottedPoints.count >= dataset.points.count && plottingAccuracy >= 0.7 }

    /// How close the drawn line is to the true least-squares regression,
    /// measured as mean vertical distance at the data points' x-values.
    var lineQuality: Double {
        let regression = LinearRegression.fit(dataset.points.map { RegressionPoint(x: $0.x, y: $0.y) })
        let startDomain = domainPoint(fraction: lineStart)
        let endDomain = domainPoint(fraction: lineEnd)
        guard endDomain.x != startDomain.x else { return 0 }
        let drawnSlope = (endDomain.y - startDomain.y) / (endDomain.x - startDomain.x)
        let drawnIntercept = startDomain.y - drawnSlope * startDomain.x
        let meanError = dataset.points.map { p -> Double in
            abs((drawnSlope * p.x + drawnIntercept) - LinearRegression.yAt(p.x, result: regression))
        }.reduce(0, +) / Double(dataset.points.count)
        return meanError / max(axisMaxY, 0.001)
    }
    var lineOK: Bool { lineQuality <= 0.08 }

    var gradientTriangleReady: Bool { gradientTapA != nil && gradientTapB != nil }

    // MARK: - Step navigation

    var currentStep: Int { steps[stepIndex] }
    var progressFraction: Double { Double(stepIndex + 1) / Double(steps.count) }
    var progressLabel: String { "Step \(stepIndex + 1) of \(steps.count)" }
    var isFirstStep: Bool { stepIndex == 0 }
    var isLastStep: Bool { stepIndex == steps.count - 1 }

    /// Whether the *current* step's own requirement is satisfied — used to
    /// gate the Next button so a student can't skip ahead (e.g. leaving the
    /// axis label blank, or plotting zero points) and still see later steps
    /// render as if that work were done.
    var currentStepComplete: Bool {
        switch currentStep {
        case 1: return scaleChosen
        case 2: return labelsOK
        case 3: return unitsOK && titleOK
        case 4: return plottingOK
        case 5: return lineOK
        case 6: return gradientTriangleReady && !studentGradientInput.trimmingCharacters(in: .whitespaces).isEmpty
        default: return true
        }
    }

    /// Short nudge shown under a disabled Next button, explaining what's
    /// still needed to unlock the current step.
    var currentStepIncompleteHint: String {
        switch currentStep {
        case 1: return "Choose a scale to continue."
        case 2: return "Fill in both axis labels to continue."
        case 3: return "Fill in the units and title to continue."
        case 4: return "Plot every point accurately to continue."
        case 5: return "Balance the best-fit line through the trend to continue."
        case 6: return "Tap two points on the line and enter your gradient to continue."
        default: return ""
        }
    }

    func advance() {
        guard !isLastStep, currentStepComplete else { return }
        stepIndex += 1
    }

    func retreat() {
        guard !isFirstStep else { return }
        stepIndex -= 1
    }

    // MARK: - Gradient marking (existing logic, unchanged)

    func submit(onSaved: () -> Void) {
        let gradient = Double(studentGradientInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
        let outcome = marker.mark(dataset: dataset, studentGradient: gradient, curriculum: curriculum)
        result = outcome
        SoundManager.shared.play(outcome.correct ? .success : .error)
        repository.save(
            curriculum: curriculum, mode: .graphCoach, target: graphType.label,
            score: outcome.score, maxScore: 100, feedback: outcome.feedback
        )
        onSaved()
    }

    /// For focused modes that end before the gradient/report steps (Plot
    /// Points ends at step 4, Draw Best-Fit ends at step 5) — saves an
    /// attempt using the checklist completed so far, since there's no
    /// gradient to mark.
    func finishShortMode(onSaved: () -> Void) {
        let checklistScore = estimatedMarkOutOf10 * 10
        SoundManager.shared.play(.complete)
        repository.save(
            curriculum: curriculum, mode: .graphCoach,
            target: "\(graphType.label) - \(mode.label)",
            score: checklistScore, maxScore: 100,
            feedback: ["Checklist-based score for \(mode.label)."]
        )
        finished = true
        onSaved()
    }

    func nextDataset() {
        dataset = generator.generate(type: graphType, seed: Int.random(in: 0...Int(Int32.max)), curriculum: curriculum)
        studentGradientInput = ""
        result = nil
        selectedScaleX = nil
        selectedScaleY = nil
        xAxisLabelInput = ""; yAxisLabelInput = ""
        xUnitInput = ""; yUnitInput = ""
        titleInput = ""
        plottedPoints = []
        lineStart = CGPoint(x: 0.10, y: 0.82)
        lineEnd = CGPoint(x: 0.88, y: 0.18)
        gradientTapA = nil; gradientTapB = nil
        stepIndex = 0
        finished = false
        prefillSkippedSteps()
    }

    /// Blends the checklist completion with the gradient-marking score into
    /// a single mark out of 10 for the final examiner report.
    var estimatedMarkOutOf10: Int {
        var earned = 0.0
        var total = 0.0
        let items: [Bool] = [scaleOK, labelsOK, unitsOK, titleOK, plottingOK, lineOK]
        for ok in items { total += 1; earned += ok ? 1 : 0 }
        if let result {
            total += 2
            earned += result.correct ? 2 : (result.score >= 45 ? 0.8 : 0)
        }
        guard total > 0 else { return 0 }
        return Int((earned / total * 10).rounded())
    }
}

struct GraphCoachPracticeView: View {
    @State private var viewModel: GraphCoachPracticeViewModel
    var onSaved: (() -> Void)?
    @FocusState private var inputFocused: Bool

    init(
        graphType: GraphCoachType, curriculum: Curriculum, repository: AttemptRepository,
        mode: GraphCoachPracticeMode = .fullExam, onSaved: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: GraphCoachPracticeViewModel(
            graphType: graphType, curriculum: curriculum, repository: repository, mode: mode
        ))
        self.onSaved = onSaved
    }

    private var def: GraphCoachType.Definition { viewModel.graphType.definition }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                progressHeader

                if viewModel.stepIndex == 0 {
                    TipBanner(text: viewModel.examTip)
                }

                stepContent

                LiveChecklistCard(viewModel: viewModel)

                navigationButtons
            }
            .padding(20)
            .animation(.snappy, value: viewModel.stepIndex)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.graphType.label)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.progressLabel)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            ProgressView(value: viewModel.progressFraction)
                .tint(.purple)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case 1: ScaleStepView(viewModel: viewModel)
        case 2: LabelsStepView(viewModel: viewModel)
        case 3: UnitsStepView(viewModel: viewModel)
        case 4: PlotStepView(viewModel: viewModel)
        case 5: BestFitStepView(viewModel: viewModel)
        case 6: GradientStepView(viewModel: viewModel, inputFocused: $inputFocused)
        default: ReportStepView(viewModel: viewModel, onSaved: onSaved)
        }
    }

    private var navigationButtons: some View {
        VStack(spacing: 12) {
            if viewModel.finished {
                Label("Nice work! That's saved to your progress.", systemImage: "checkmark.seal.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.green)
                Button("Practice again") {
                    inputFocused = false
                    viewModel.nextDataset()
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .frame(maxWidth: .infinity)
            } else if viewModel.currentStep != 7 {
                HStack(spacing: 12) {
                    if !viewModel.isFirstStep {
                        Button("Back") { viewModel.retreat() }
                            .buttonStyle(.bordered)
                    }
                    let isShortModeEnd = viewModel.isLastStep && viewModel.currentStep != 6
                    VStack(spacing: 6) {
                        Button(viewModel.isLastStep ? "Finish" : "Next") {
                            inputFocused = false
                            if isShortModeEnd {
                                viewModel.finishShortMode(onSaved: { onSaved?() })
                            } else {
                                viewModel.advance()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        .frame(maxWidth: .infinity)
                        .disabled(!viewModel.currentStepComplete)

                        if !viewModel.currentStepComplete {
                            Text(viewModel.currentStepIncompleteHint)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else if !viewModel.isFirstStep {
                Button("Back") { viewModel.retreat() }
                    .buttonStyle(.bordered)
            }
        }
    }
}

// MARK: - Shared step chrome

private struct TipBanner: View {
    let text: String

    var body: some View {
        Label {
            Text(text).font(.footnote)
        } icon: {
            Image(systemName: "lightbulb.fill").foregroundStyle(.yellow)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct StepCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.title3.bold())
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct LiveChecklistCard: View {
    let viewModel: GraphCoachPracticeViewModel

    private var items: [(String, ChecklistState)] {
        var rows: [(String, ChecklistState)] = []
        if viewModel.currentStep >= 1 {
            rows.append(("Suitable scale", viewModel.scaleChosen ? (viewModel.scaleOK ? .good : .warning) : .missing))
        }
        if viewModel.currentStep >= 2 {
            rows.append(("X-axis label", viewModel.xLabelOK ? .good : .missing))
            rows.append(("Y-axis label", viewModel.yLabelOK ? .good : .missing))
        }
        if viewModel.currentStep >= 3 {
            rows.append(("Units", viewModel.unitsOK ? .good : .missing))
            rows.append(("Graph title", viewModel.titleOK ? .good : .missing))
        }
        if viewModel.currentStep >= 4 {
            rows.append(("Data plotting", viewModel.plottedPoints.isEmpty ? .missing : (viewModel.plottingOK ? .good : .warning)))
        }
        if viewModel.currentStep >= 5 {
            rows.append(("Best-fit line", viewModel.lineOK ? .good : .warning))
        }
        return rows
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Live examiner feedback")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            ForEach(items, id: \.0) { label, state in
                HStack(spacing: 8) {
                    Image(systemName: state.systemImage).foregroundStyle(state.color)
                    Text(label).font(.footnote)
                    Spacer()
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private enum ChecklistState {
    case good, warning, missing

    var systemImage: String {
        switch self {
        case .good: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .missing: return "xmark.circle.fill"
        }
    }
    var color: Color {
        switch self {
        case .good: return .green
        case .warning: return .orange
        case .missing: return .red
        }
    }
}

// MARK: - Step 1: Scale

private struct ScaleStepView: View {
    let viewModel: GraphCoachPracticeViewModel

    var body: some View {
        StepCard(title: "Choose a scale", subtitle: "Pick a scale for each axis that uses more than half the graph paper.") {
            VStack(alignment: .leading, spacing: 16) {
                ScaleAxisPicker(
                    title: "X-axis (\(viewModel.graphType.definition.xLabel))",
                    candidates: viewModel.niceScaleCandidates(for: viewModel.axisMaxX),
                    maxValue: viewModel.axisMaxX,
                    viewModel: viewModel,
                    selection: Binding(get: { viewModel.selectedScaleX }, set: { viewModel.selectedScaleX = $0 })
                )
                ScaleAxisPicker(
                    title: "Y-axis (\(viewModel.graphType.definition.yLabel))",
                    candidates: viewModel.niceScaleCandidates(for: viewModel.axisMaxY),
                    maxValue: viewModel.axisMaxY,
                    viewModel: viewModel,
                    selection: Binding(get: { viewModel.selectedScaleY }, set: { viewModel.selectedScaleY = $0 })
                )
            }
        }
    }
}

/// One axis's row of scale candidates ("units per square") in the Scale
/// step. Pulled out so X and Y can be chosen independently — each axis can
/// have a very different range, so one shared scale value doesn't fit both.
private struct ScaleAxisPicker: View {
    let title: String
    let candidates: [Double]
    let maxValue: Double
    let viewModel: GraphCoachPracticeViewModel
    @Binding var selection: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 10) {
                ForEach(candidates, id: \.self) { candidate in
                    let selected = selection == candidate
                    let good = viewModel.isGoodScale(candidate, maxValue: maxValue)
                    Button {
                        withAnimation(.snappy) { selection = candidate }
                    } label: {
                        VStack(spacing: 4) {
                            Text(String(format: "%.3g", candidate)).font(.headline)
                            Text("per square").font(.caption2).foregroundStyle(.secondary)
                            if selected {
                                Text(good ? "Good scale" : "Too cramped")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(good ? .green : .orange)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selected ? Color.purple.opacity(0.18) : Color(.tertiarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(selected ? Color.purple : .clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Step 2: Labels

private struct LabelsStepView: View {
    let viewModel: GraphCoachPracticeViewModel

    var body: some View {
        StepCard(title: "Label the axes", subtitle: "Write what each axis represents.") {
            VStack(alignment: .leading, spacing: 12) {
                LabelledField(title: "X-axis label", text: Binding(get: { viewModel.xAxisLabelInput }, set: { viewModel.xAxisLabelInput = $0 }), placeholder: "e.g. \(viewModel.graphType.definition.xLabel)", isValid: viewModel.xLabelOK)
                LabelledField(title: "Y-axis label", text: Binding(get: { viewModel.yAxisLabelInput }, set: { viewModel.yAxisLabelInput = $0 }), placeholder: "e.g. \(viewModel.graphType.definition.yLabel)", isValid: viewModel.yLabelOK)
            }
        }
    }
}

private struct LabelledField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let isValid: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            HStack {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
                if !text.isEmpty {
                    Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(isValid ? .green : .red)
                }
            }
        }
    }
}

// MARK: - Step 3: Units + title

private struct UnitsStepView: View {
    let viewModel: GraphCoachPracticeViewModel

    var body: some View {
        StepCard(title: "Add units and a title", subtitle: "Every axis needs a unit; every graph needs a title.") {
            VStack(alignment: .leading, spacing: 12) {
                LabelledField(title: "X-axis unit", text: Binding(get: { viewModel.xUnitInput }, set: { viewModel.xUnitInput = $0 }), placeholder: viewModel.graphType.definition.xUnit.isEmpty ? "(none)" : viewModel.graphType.definition.xUnit, isValid: viewModel.xUnitOK)
                LabelledField(title: "Y-axis unit", text: Binding(get: { viewModel.yUnitInput }, set: { viewModel.yUnitInput = $0 }), placeholder: viewModel.graphType.definition.yUnit.isEmpty ? "(none)" : viewModel.graphType.definition.yUnit, isValid: viewModel.yUnitOK)
                LabelledField(title: "Graph title", text: Binding(get: { viewModel.titleInput }, set: { viewModel.titleInput = $0 }), placeholder: "\(viewModel.graphType.definition.yLabel) vs \(viewModel.graphType.definition.xLabel)", isValid: viewModel.titleOK)
            }
        }
    }
}

// MARK: - Step 4: Plot the data

/// The raw (x, y) values the student is meant to plot. Without this, Step 4
/// is a blank grid with no way to know where a point should go — this is
/// the exam's results table, shown the same way it would sit on a real exam
/// paper next to blank graph paper.
private struct RawDataTableCard: View {
    let definition: GraphCoachType.Definition
    let points: [GraphPoint]

    private func format(_ value: Double) -> String { String(format: "%.3g", value) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your results table").font(.caption.weight(.bold)).foregroundStyle(.secondary)
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                GridRow {
                    Text("\(definition.xLabel)\(definition.xUnit.isEmpty ? "" : " / \(definition.xUnit)")").font(.caption.weight(.semibold))
                    Text("\(definition.yLabel)\(definition.yUnit.isEmpty ? "" : " / \(definition.yUnit)")").font(.caption.weight(.semibold))
                }
                Divider().gridCellColumns(2)
                ForEach(points, id: \.self) { p in
                    GridRow {
                        Text(format(p.x)).font(.caption.monospacedDigit())
                        Text(format(p.y)).font(.caption.monospacedDigit())
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct PlotStepView: View {
    let viewModel: GraphCoachPracticeViewModel

    var body: some View {
        StepCard(title: "Plot the data", subtitle: "Use the results table below — tap the grid to place each point, drag to fine-tune.") {
            VStack(alignment: .leading, spacing: 10) {
                RawDataTableCard(definition: viewModel.graphType.definition, points: viewModel.dataset.points)

                InteractivePlotCanvas(
                    definition: viewModel.graphType.definition,
                    axisMaxX: viewModel.axisMaxX,
                    axisMaxY: viewModel.axisMaxY,
                    scaleX: viewModel.selectedScaleX,
                    scaleY: viewModel.selectedScaleY,
                    targetCount: viewModel.dataset.points.count,
                    points: Binding(get: { viewModel.plottedPoints }, set: { viewModel.plottedPoints = $0 })
                )
                .frame(height: 280)

                HStack {
                    Text("\(viewModel.plottedPoints.count) of \(viewModel.dataset.points.count) points placed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Clear") { withAnimation { viewModel.plottedPoints = [] } }
                        .font(.caption)
                        .disabled(viewModel.plottedPoints.isEmpty)
                }
            }
        }
    }
}

/// Tap-anywhere-to-plot canvas: tapping the grid adds a point (up to the
/// target count) snapped to the nearest grid intersection; dragging an
/// existing point moves it for fine adjustment, re-snapping on release.
/// Points are real SwiftUI views (not Canvas-drawn) so they get large,
/// animated, easily-tappable hit targets rather than tiny fixed dots.
/// A single plotted point, draggable for fine adjustment. Movement during
/// the drag is purely visual (a local offset on top of the fixed starting
/// position), and the real position only commits on release — the same
/// safe pattern used for apparatus drag-and-drop elsewhere in the app,
/// which avoids double-counting movement that a "base position + gesture
/// translation" approach suffers from once the base position itself starts
/// shifting mid-drag.
private struct DraggableGraphPoint: View {
    let screenPosition: CGPoint
    let onCommit: (CGPoint) -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    var body: some View {
        Circle()
            .fill(Color.blue)
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .frame(width: isDragging ? 20 : 16, height: isDragging ? 20 : 16)
            .contentShape(Circle().size(width: 48, height: 48))
            .position(x: screenPosition.x + dragOffset.width, y: screenPosition.y + dragOffset.height)
            .gesture(
                DragGesture(minimumDistance: 2, coordinateSpace: .local)
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        let finalPosition = CGPoint(x: screenPosition.x + value.translation.width, y: screenPosition.y + value.translation.height)
                        onCommit(finalPosition)
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            dragOffset = .zero
                            isDragging = false
                        }
                    }
            )
    }
}

private struct InteractivePlotCanvas: View {
    let definition: GraphCoachType.Definition
    let axisMaxX: Double
    let axisMaxY: Double
    let scaleX: Double?
    let scaleY: Double?
    let targetCount: Int
    @Binding var points: [GraphPoint]

    @State private var plotFrame: CGRect = .zero

    private var effectiveScaleX: Double { scaleX ?? niceGridStep(for: axisMaxX) }
    private var effectiveScaleY: Double { scaleY ?? niceGridStep(for: axisMaxY) }

    var body: some View {
        GeometryReader { geo in
            let margin: CGFloat = 44
            let plotRect = CGRect(x: margin, y: 16, width: geo.size.width - margin - 16, height: geo.size.height - margin - 32)

            ZStack(alignment: .topLeading) {
                Canvas { context, size in
                    drawGraphPaper(context: context, plotRect: plotRect, maxX: axisMaxX, maxY: axisMaxY, stepX: effectiveScaleX, stepY: effectiveScaleY)
                    var axes = Path()
                    axes.move(to: CGPoint(x: plotRect.minX, y: plotRect.minY))
                    axes.addLine(to: CGPoint(x: plotRect.minX, y: plotRect.maxY))
                    axes.addLine(to: CGPoint(x: plotRect.maxX, y: plotRect.maxY))
                    context.stroke(axes, with: .color(.primary), lineWidth: 1.5)
                    context.draw(Text(definition.xLabel).font(.caption2), at: CGPoint(x: plotRect.midX, y: size.height - 8))
                    context.draw(Text(definition.yLabel).font(.caption2).italic(), at: CGPoint(x: 8, y: plotRect.midY), anchor: .center)
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    guard points.count < targetCount, plotRect.insetBy(dx: -10, dy: -10).contains(location) else { return }
                    let snapped = snap(location, plotRect: plotRect)
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                        points.append(domainPoint(from: snapped, plotRect: plotRect))
                    }
                }

                ForEach(Array(points.enumerated()), id: \.offset) { index, p in
                    DraggableGraphPoint(
                        screenPosition: screenPoint(for: p, plotRect: plotRect),
                        onCommit: { finalScreenPosition in
                            let snapped = snap(finalScreenPosition, plotRect: plotRect)
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                                points[index] = domainPoint(from: snapped, plotRect: plotRect)
                            }
                        }
                    )
                    .animation(.spring(response: 0.28, dampingFraction: 0.78), value: p)
                }
            }
            .background(
                GeometryReader { inner in
                    Color.clear.onAppear { plotFrame = plotRect }
                }
            )
        }
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityLabel("Interactive plot of \(definition.label). Tap to place points.")
    }

    private func screenPoint(for p: GraphPoint, plotRect: CGRect) -> CGPoint {
        CGPoint(
            x: plotRect.minX + CGFloat(p.x / axisMaxX) * plotRect.width,
            y: plotRect.maxY - CGFloat(p.y / axisMaxY) * plotRect.height
        )
    }

    private func domainPoint(from screen: CGPoint, plotRect: CGRect) -> GraphPoint {
        let fx = Double((screen.x - plotRect.minX) / plotRect.width)
        let fy = Double((plotRect.maxY - screen.y) / plotRect.height)
        return GraphPoint(x: max(0, fx) * axisMaxX, y: max(0, fy) * axisMaxY)
    }

    /// Snaps a screen point to the nearest minor grid intersection — the
    /// finer subdivisions now drawn on the graph paper, five per major
    /// square — so plotting resolution matches what the student can
    /// actually see and aim for, not just the coarser labelled lines.
    private func snap(_ screen: CGPoint, plotRect: CGRect) -> CGPoint {
        let domain = domainPoint(from: screen, plotRect: plotRect)
        let minorStepX = effectiveScaleX / 5
        let minorStepY = effectiveScaleY / 5
        let snappedX = (domain.x / minorStepX).rounded() * minorStepX
        let snappedY = (domain.y / minorStepY).rounded() * minorStepY
        return CGPoint(
            x: plotRect.minX + CGFloat(snappedX / axisMaxX) * plotRect.width,
            y: plotRect.maxY - CGFloat(snappedY / axisMaxY) * plotRect.height
        )
    }
}

// MARK: - Step 5: Best-fit line

private struct BestFitStepView: View {
    let viewModel: GraphCoachPracticeViewModel
    @State private var isFreehand = false

    var body: some View {
        StepCard(
            title: "Draw the best-fit line",
            subtitle: isFreehand
                ? "Swipe once across the trend in a single stroke, like a pencil on paper — don't join every point."
                : "Drag the two handles so the line balances the scatter — don't join every point."
        ) {
            RawDataTableCard(definition: viewModel.graphType.definition, points: viewModel.dataset.points)

            Button(isFreehand ? "\u{1F590}\u{FE0F} Switch to drag handles" : "\u{270F}\u{FE0F} Draw freehand instead") {
                isFreehand.toggle()
            }
            .font(.caption)

            BestFitLineCanvas(
                definition: viewModel.graphType.definition,
                axisMaxX: viewModel.axisMaxX,
                axisMaxY: viewModel.axisMaxY,
                points: viewModel.plottedPoints,
                start: Binding(get: { viewModel.lineStart }, set: { viewModel.lineStart = $0 }),
                end: Binding(get: { viewModel.lineEnd }, set: { viewModel.lineEnd = $0 }),
                isFreehand: isFreehand
            )
            .frame(height: 280)

            Label(
                viewModel.lineOK ? "Nicely balanced through the trend." : "Try to balance points above and below the line.",
                systemImage: viewModel.lineOK ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
            )
            .font(.caption)
            .foregroundStyle(viewModel.lineOK ? .green : .orange)
        }
    }
}

/// Draws the scatter, plus a straight line the student positions either by
/// dragging two large handles, or — when `isFreehand` is true — by swiping
/// a single continuous stroke across the plot area. The stroke itself is
/// never graded directly (a shaky finger stroke is not a meaningful
/// "wobbly line" penalty the way it would be on paper): on release it's
/// least-squares fitted with the same `LinearRegression` the checklist
/// already uses, and only the resulting straight line becomes `start`/`end`
/// — so freehand mode is a genuinely different *input* gesture feeding the
/// exact same grading (`lineQuality`/`lineOK`) as the handle-drag mode,
/// with zero new grading logic to keep in sync.
/// A large draggable line-endpoint handle. Same safe local-offset drag
/// pattern as `DraggableGraphPoint`: moves live during the gesture via a
/// purely visual offset, and commits its real position once on release.
private struct LineHandle: View {
    let position: CGPoint
    let onCommit: (CGPoint) -> Void

    @State private var dragOffset: CGSize = .zero

    var body: some View {
        Circle()
            .fill(Color.purple)
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .frame(width: 22, height: 22)
            .contentShape(Circle().size(width: 50, height: 50))
            .position(x: position.x + dragOffset.width, y: position.y + dragOffset.height)
            .gesture(
                DragGesture(minimumDistance: 2, coordinateSpace: .local)
                    .onChanged { value in dragOffset = value.translation }
                    .onEnded { value in
                        let finalPosition = CGPoint(x: position.x + value.translation.width, y: position.y + value.translation.height)
                        onCommit(finalPosition)
                        dragOffset = .zero
                    }
            )
    }
}

private struct BestFitLineCanvas: View {
    let definition: GraphCoachType.Definition
    let axisMaxX: Double
    let axisMaxY: Double
    let points: [GraphPoint]
    @Binding var start: CGPoint
    @Binding var end: CGPoint
    var isFreehand: Bool = false

    @State private var strokeScreenPoints: [CGPoint] = []

    var body: some View {
        GeometryReader { geo in
            let margin: CGFloat = 44
            let plotRect = CGRect(x: margin, y: 16, width: geo.size.width - margin - 16, height: geo.size.height - margin - 32)
            let startScreen = screenPoint(for: start, plotRect: plotRect)
            let endScreen = screenPoint(for: end, plotRect: plotRect)

            ZStack {
                Canvas { context, size in
                    drawGraphPaper(
                        context: context, plotRect: plotRect, maxX: axisMaxX, maxY: axisMaxY,
                        stepX: niceGridStep(for: axisMaxX), stepY: niceGridStep(for: axisMaxY)
                    )
                    var axes = Path()
                    axes.move(to: CGPoint(x: plotRect.minX, y: plotRect.minY))
                    axes.addLine(to: CGPoint(x: plotRect.minX, y: plotRect.maxY))
                    axes.addLine(to: CGPoint(x: plotRect.maxX, y: plotRect.maxY))
                    context.stroke(axes, with: .color(.primary), lineWidth: 1.5)
                    context.draw(Text(definition.xLabel).font(.caption2), at: CGPoint(x: plotRect.midX, y: size.height - 8))
                    context.draw(Text(definition.yLabel).font(.caption2).italic(), at: CGPoint(x: 8, y: plotRect.midY), anchor: .center)

                    for p in points {
                        let center = CGPoint(
                            x: plotRect.minX + CGFloat(p.x / axisMaxX) * plotRect.width,
                            y: plotRect.maxY - CGFloat(p.y / axisMaxY) * plotRect.height
                        )
                        var cross = Path()
                        cross.move(to: CGPoint(x: center.x - 4, y: center.y - 4))
                        cross.addLine(to: CGPoint(x: center.x + 4, y: center.y + 4))
                        cross.move(to: CGPoint(x: center.x - 4, y: center.y + 4))
                        cross.addLine(to: CGPoint(x: center.x + 4, y: center.y - 4))
                        context.stroke(cross, with: .color(.blue), lineWidth: 2)
                    }

                    var line = Path()
                    line.move(to: startScreen)
                    line.addLine(to: endScreen)
                    context.stroke(line, with: .color(.purple), lineWidth: 2.5)

                    if strokeScreenPoints.count > 1 {
                        var stroke = Path()
                        stroke.move(to: strokeScreenPoints[0])
                        for p in strokeScreenPoints.dropFirst() { stroke.addLine(to: p) }
                        context.stroke(stroke, with: .color(.orange), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [1, 6]))
                    }
                }

                if isFreehand {
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 1, coordinateSpace: .local)
                                .onChanged { value in strokeScreenPoints.append(value.location) }
                                .onEnded { _ in
                                    commitFreehandStroke(plotRect: plotRect)
                                    strokeScreenPoints = []
                                }
                        )
                } else {
                    handle(at: startScreen) { newValue in start = fraction(for: newValue, plotRect: plotRect) }
                    handle(at: endScreen) { newValue in end = fraction(for: newValue, plotRect: plotRect) }
                }
            }
        }
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    /// Least-squares fits the raw stroke (converted from screen space into
    /// real data units, same conversion the handle-drag path already uses)
    /// and re-expresses the result as the two fractional endpoints
    /// `start`/`end` expect — a stroke becomes a straight line the same
    /// way a student's wobbly pencil line is judged by its overall trend,
    /// not its wobble.
    private func commitFreehandStroke(plotRect: CGRect) {
        guard strokeScreenPoints.count >= 2 else { return }
        let domainPoints: [RegressionPoint] = strokeScreenPoints.map { screen in
            let f = fraction(for: screen, plotRect: plotRect)
            return RegressionPoint(x: Double(f.x) * axisMaxX, y: Double(1 - f.y) * axisMaxY)
        }
        // A near-vertical swipe (all points at ~same x) has no meaningful
        // slope to fit — ignore it rather than committing a wild line.
        let xSpread = (domainPoints.map(\.x).max() ?? 0) - (domainPoints.map(\.x).min() ?? 0)
        guard xSpread > axisMaxX * 0.1 else { return }

        let regression = LinearRegression.fit(domainPoints)
        let y0 = LinearRegression.yAt(0, result: regression)
        let y1 = LinearRegression.yAt(axisMaxX, result: regression)
        start = CGPoint(x: 0, y: min(max(1 - y0 / axisMaxY, -0.5), 1.5))
        end = CGPoint(x: 1, y: min(max(1 - y1 / axisMaxY, -0.5), 1.5))
    }

    private func handle(at position: CGPoint, onMove: @escaping (CGPoint) -> Void) -> some View {
        LineHandle(position: position, onCommit: onMove)
    }

    private func screenPoint(for fraction: CGPoint, plotRect: CGRect) -> CGPoint {
        CGPoint(x: plotRect.minX + fraction.x * plotRect.width, y: plotRect.minY + fraction.y * plotRect.height)
    }

    private func fraction(for screen: CGPoint, plotRect: CGRect) -> CGPoint {
        CGPoint(
            x: min(max((screen.x - plotRect.minX) / plotRect.width, 0), 1),
            y: min(max((screen.y - plotRect.minY) / plotRect.height, 0), 1)
        )
    }
}

// MARK: - Step 6: Gradient

private struct GradientStepView: View {
    let viewModel: GraphCoachPracticeViewModel
    var inputFocused: FocusState<Bool>.Binding

    var body: some View {
        StepCard(title: "Calculate the gradient", subtitle: "Tap two points on your line to build a gradient triangle.") {
            VStack(alignment: .leading, spacing: 12) {
                GradientTriangleTool(
                    definition: viewModel.graphType.definition,
                    axisMaxX: viewModel.axisMaxX,
                    axisMaxY: viewModel.axisMaxY,
                    lineStart: viewModel.lineStart,
                    lineEnd: viewModel.lineEnd,
                    points: viewModel.plottedPoints,
                    tapA: Binding(get: { viewModel.gradientTapA }, set: { viewModel.gradientTapA = $0 }),
                    tapB: Binding(get: { viewModel.gradientTapB }, set: { viewModel.gradientTapB = $0 })
                )
                .frame(height: 280)

                if let a = viewModel.gradientTapA, let b = viewModel.gradientTapB {
                    let da = viewModel.domainPoint(fraction: a)
                    let db = viewModel.domainPoint(fraction: b)
                    let deltaY = abs(db.y - da.y)
                    let deltaX = abs(db.x - da.x)
                    HStack(spacing: 20) {
                        VStack(alignment: .leading) {
                            Text("ΔY").font(.caption).foregroundStyle(.secondary)
                            Text(String(format: "%.3f", deltaY)).font(.headline)
                        }
                        VStack(alignment: .leading) {
                            Text("ΔX").font(.caption).foregroundStyle(.secondary)
                            Text(String(format: "%.3f", deltaX)).font(.headline)
                        }
                    }
                } else {
                    Text("Tap two points on the purple line to measure ΔY and ΔX.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    TextField("Your gradient", text: Binding(get: { viewModel.studentGradientInput }, set: { viewModel.studentGradientInput = $0 }))
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .focused(inputFocused)
                    Text("\(viewModel.graphType.definition.yUnit)/\(viewModel.graphType.definition.xUnit)")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

/// Reuses the best-fit line's endpoints; the student taps two points along
/// that line (not the data points) to build a right-angled gradient
/// triangle, matching real practical-exam gradient technique.
private struct GradientTriangleTool: View {
    let definition: GraphCoachType.Definition
    let axisMaxX: Double
    let axisMaxY: Double
    let lineStart: CGPoint
    let lineEnd: CGPoint
    let points: [GraphPoint]
    @Binding var tapA: CGPoint?
    @Binding var tapB: CGPoint?

    var body: some View {
        GeometryReader { geo in
            let margin: CGFloat = 44
            let plotRect = CGRect(x: margin, y: 16, width: geo.size.width - margin - 16, height: geo.size.height - margin - 32)
            let startScreen = CGPoint(x: plotRect.minX + lineStart.x * plotRect.width, y: plotRect.minY + lineStart.y * plotRect.height)
            let endScreen = CGPoint(x: plotRect.minX + lineEnd.x * plotRect.width, y: plotRect.minY + lineEnd.y * plotRect.height)

            ZStack {
                Canvas { context, size in
                    drawGraphPaper(
                        context: context, plotRect: plotRect, maxX: axisMaxX, maxY: axisMaxY,
                        stepX: niceGridStep(for: axisMaxX), stepY: niceGridStep(for: axisMaxY)
                    )
                    var axes = Path()
                    axes.move(to: CGPoint(x: plotRect.minX, y: plotRect.minY))
                    axes.addLine(to: CGPoint(x: plotRect.minX, y: plotRect.maxY))
                    axes.addLine(to: CGPoint(x: plotRect.maxX, y: plotRect.maxY))
                    context.stroke(axes, with: .color(.primary), lineWidth: 1.5)
                    context.draw(Text(definition.xLabel).font(.caption2), at: CGPoint(x: plotRect.midX, y: size.height - 8))
                    context.draw(Text(definition.yLabel).font(.caption2).italic(), at: CGPoint(x: 8, y: plotRect.midY), anchor: .center)

                    for p in points {
                        let center = CGPoint(
                            x: plotRect.minX + CGFloat(p.x / axisMaxX) * plotRect.width,
                            y: plotRect.maxY - CGFloat(p.y / axisMaxY) * plotRect.height
                        )
                        var cross = Path()
                        cross.move(to: CGPoint(x: center.x - 3, y: center.y - 3))
                        cross.addLine(to: CGPoint(x: center.x + 3, y: center.y + 3))
                        cross.move(to: CGPoint(x: center.x - 3, y: center.y + 3))
                        cross.addLine(to: CGPoint(x: center.x + 3, y: center.y - 3))
                        context.stroke(cross, with: .color(.blue.opacity(0.6)), lineWidth: 1.5)
                    }

                    var line = Path()
                    line.move(to: startScreen)
                    line.addLine(to: endScreen)
                    context.stroke(line, with: .color(.purple), lineWidth: 2.5)

                    if let a = tapA, let b = tapB {
                        let pa = CGPoint(x: plotRect.minX + a.x * plotRect.width, y: plotRect.minY + a.y * plotRect.height)
                        let pb = CGPoint(x: plotRect.minX + b.x * plotRect.width, y: plotRect.minY + b.y * plotRect.height)
                        let corner = CGPoint(x: pb.x, y: pa.y)
                        var triangle = Path()
                        triangle.move(to: pa)
                        triangle.addLine(to: corner)
                        triangle.addLine(to: pb)
                        context.stroke(triangle, with: .color(.orange), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                        for tapPoint in [pa, pb] {
                            context.fill(Path(ellipseIn: CGRect(x: tapPoint.x - 5, y: tapPoint.y - 5, width: 10, height: 10)), with: .color(.orange))
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    guard plotRect.insetBy(dx: -10, dy: -10).contains(location) else { return }
                    let closest = closestPointOnLine(to: location, start: startScreen, end: endScreen)
                    let fraction = CGPoint(x: (closest.x - plotRect.minX) / plotRect.width, y: (closest.y - plotRect.minY) / plotRect.height)
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                        if tapA == nil { tapA = fraction }
                        else if tapB == nil { tapB = fraction }
                        else { tapA = fraction; tapB = nil }
                    }
                }
            }
        }
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityLabel("Tap two points on the best-fit line to build a gradient triangle.")
    }

    private func closestPointOnLine(to point: CGPoint, start: CGPoint, end: CGPoint) -> CGPoint {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let lengthSquared = dx * dx + dy * dy
        guard lengthSquared > 0 else { return start }
        var t = ((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared
        t = min(max(t, 0), 1)
        return CGPoint(x: start.x + t * dx, y: start.y + t * dy)
    }
}

// MARK: - Step 7: Final examiner report

private struct ReportStepView: View {
    let viewModel: GraphCoachPracticeViewModel
    let onSaved: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.result == nil {
                StepCard(title: "Ready to submit?", subtitle: "Check your gradient to generate your examiner report.") {
                    Button("Check gradient") {
                        viewModel.submit(onSaved: { onSaved?() })
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .frame(maxWidth: .infinity)
                }
            } else {
                ExaminerReportCard(viewModel: viewModel)
                Button("Practice again") { viewModel.nextDataset() }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct ExaminerReportCard: View {
    let viewModel: GraphCoachPracticeViewModel

    private var mark: Int { viewModel.estimatedMarkOutOf10 }
    private var band: String {
        switch mark {
        case 9...10: return "Excellent"
        case 7...8: return "Good"
        case 5...6: return "Fair"
        default: return "Needs practice"
        }
    }

    private var strengths: [String] {
        var items: [String] = []
        if viewModel.scaleOK { items.append("Scale") }
        if viewModel.labelsOK { items.append("Labels") }
        if viewModel.unitsOK { items.append("Units") }
        if viewModel.titleOK { items.append("Title") }
        if viewModel.plottingOK { items.append("Plotting") }
        if viewModel.lineOK { items.append("Best-fit line") }
        if viewModel.result?.correct == true { items.append("Gradient") }
        return items
    }

    private var improvements: [String] {
        var items: [String] = []
        if !viewModel.scaleOK { items.append("Choose a scale that uses more of the graph paper.") }
        if !viewModel.labelsOK { items.append("Axis labels should name the plotted quantity.") }
        if !viewModel.unitsOK { items.append("Add the correct unit to each axis label.") }
        if !viewModel.titleOK { items.append("Add a graph title.") }
        if !viewModel.plottingOK { items.append("Plot every point accurately at its grid position.") }
        if !viewModel.lineOK { items.append("Balance the best-fit line through the trend, not through every point.") }
        if let result = viewModel.result, !result.correct { items.append("Gradient triangle slightly inaccurate — use two points far apart on the line.") }
        return items
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 4) {
                Text("Graph Score").font(.caption).foregroundStyle(.secondary)
                Text("\(mark) / 10").font(.system(size: 40, weight: .bold, design: .rounded))
                Text(band).font(.headline).foregroundStyle(mark >= 7 ? .green : .orange)
            }
            .frame(maxWidth: .infinity)

            if !strengths.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Strengths").font(.subheadline.bold())
                    ForEach(strengths, id: \.self) { item in
                        Label(item, systemImage: "checkmark.circle.fill").font(.footnote).foregroundStyle(.green)
                    }
                }
            }

            if !improvements.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Needs Improvement").font(.subheadline.bold())
                    ForEach(improvements, id: \.self) { item in
                        Label(item, systemImage: "exclamationmark.triangle.fill").font(.footnote).foregroundStyle(.orange)
                    }
                }
            }

            if let result = viewModel.result {
                Divider()
                Text(result.explanation).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct ScatterPlotCanvasView: View {
    let dataset: GraphDataset
    let definition: GraphCoachType.Definition

    var body: some View {
        Canvas { context, size in
            let margin: CGFloat = 44
            let plotRect = CGRect(x: margin, y: 12, width: size.width - margin - 12, height: size.height - margin - 24)

            guard let maxX = dataset.points.map(\.x).max(), let maxY = dataset.points.map(\.y).max(), maxX > 0, maxY > 0 else { return }

            drawGraphPaper(
                context: context, plotRect: plotRect, maxX: maxX, maxY: maxY,
                stepX: niceGridStep(for: maxX), stepY: niceGridStep(for: maxY)
            )

            var axes = Path()
            axes.move(to: CGPoint(x: plotRect.minX, y: plotRect.minY))
            axes.addLine(to: CGPoint(x: plotRect.minX, y: plotRect.maxY))
            axes.addLine(to: CGPoint(x: plotRect.maxX, y: plotRect.maxY))
            context.stroke(axes, with: .color(.primary), lineWidth: 1.5)

            func point(_ p: GraphPoint) -> CGPoint {
                CGPoint(
                    x: plotRect.minX + CGFloat(p.x / maxX) * plotRect.width,
                    y: plotRect.maxY - CGFloat(p.y / maxY) * plotRect.height
                )
            }

            for p in dataset.points {
                let center = point(p)
                var cross = Path()
                cross.move(to: CGPoint(x: center.x - 4, y: center.y - 4))
                cross.addLine(to: CGPoint(x: center.x + 4, y: center.y + 4))
                cross.move(to: CGPoint(x: center.x - 4, y: center.y + 4))
                cross.addLine(to: CGPoint(x: center.x + 4, y: center.y - 4))
                context.stroke(cross, with: .color(.blue), lineWidth: 2)
            }

            context.draw(Text(definition.xLabel).font(.caption2), at: CGPoint(x: plotRect.midX, y: size.height - 8))
            context.draw(
                Text(definition.yLabel).font(.caption2).italic(),
                at: CGPoint(x: 8, y: plotRect.midY),
                anchor: .center
            )
        }
        .accessibilityLabel("Scatter plot of \(definition.label)")
        .padding(12)
    }
}
