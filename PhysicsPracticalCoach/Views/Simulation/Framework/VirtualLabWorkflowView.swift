//
//  VirtualLabWorkflowView.swift
//  PhysicsPracticalCoach
//
//  Generic screen shell for every "Virtual Lab Experiment". Renders Stages
//  1, 2, 3, 8, 9, 10, 11 entirely from `VirtualLabExperiment`'s static
//  config; Stage 4-7 ("Perform & Record", covering the spec's Perform ->
//  Record Results -> Graph -> Calculations) is supplied by the concrete
//  experiment as its own existing Lab view via the `coreContent` builder —
//  for Pendulum this is the existing `PendulumLabView`'s content, completely
//  unmodified apart from the small `onFinished` hook added to its view model.
//

import SwiftUI

struct VirtualLabWorkflowView<CoreContent: View>: View {
    @State var viewModel: VirtualLabWorkflowViewModel
    @ViewBuilder var coreContent: () -> CoreContent

    init(viewModel: VirtualLabWorkflowViewModel, @ViewBuilder coreContent: @escaping () -> CoreContent) {
        _viewModel = State(initialValue: viewModel)
        self.coreContent = coreContent
    }

    var body: some View {
        VStack(spacing: 0) {
            StageChecklistHeader(currentStage: viewModel.stage)
            ScrollView {
                stageContent
                    .padding(20)
                    .id(viewModel.stage)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.97)),
                        removal: .opacity
                    ))
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.experiment.title)
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeOut(duration: 0.25), value: viewModel.stage)
    }

    @ViewBuilder
    private var stageContent: some View {
        switch viewModel.stage {
        case .introduction:
            IntroductionStageView(viewModel: viewModel)
        case .collectApparatus:
            CollectApparatusStageView(viewModel: viewModel)
        case .setUp:
            SetUpStageView(viewModel: viewModel)
        case .coreExperiment:
            coreContent()
        case .practicalQuestions:
            PracticalQuestionsStageView(viewModel: viewModel)
        case .conclusion:
            ConclusionStageView(viewModel: viewModel)
        case .results:
            ResultsStageView(viewModel: viewModel)
        case .examinerFeedback:
            ExaminerFeedbackStageView(viewModel: viewModel)
        }
    }
}

// MARK: - Stage checklist header

/// Replaces the old "Stage 3 of 8" progress bar with an at-a-glance
/// checklist so students immediately know where they are and what's left —
/// each stage shows its emoji + label, with a checkmark for completed
/// stages and a filled dot for the current one.
private struct StageChecklistHeader: View {
    let currentStage: LabExperimentStage

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(LabExperimentStage.allCases) { stage in
                    stageChip(for: stage)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private func stageChip(for stage: LabExperimentStage) -> some View {
        let isDone = stage.rawValue < currentStage.rawValue
        let isCurrent = stage == currentStage

        HStack(spacing: 4) {
            Text(stage.emoji).font(.footnote)
            Text(stage.shortLabel)
                .font(.caption2.weight(isCurrent ? .bold : .regular))
                .foregroundStyle(isCurrent ? .primary : .secondary)
            if isDone {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
            } else if isCurrent {
                Image(systemName: "circle.fill")
                    .font(.system(size: 6))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            isCurrent ? Color.accentColor.opacity(0.15) : Color(.secondarySystemGroupedBackground),
            in: Capsule()
        )
    }
}



// MARK: - Hand-drawn apparatus icons

/// Small bespoke vector icons per apparatus item, in the same hand-drawn
/// `Canvas` style as `ApparatusVisuals.swift`'s instrument renderers, rather
/// than generic SF Symbols. Falls back to the item's `systemImage` for any
/// apparatus type not yet given bespoke line-art (future experiments can add
/// a case here incrementally without breaking anything).
private struct ApparatusIconCanvas: View {
    let item: LabApparatusItem
    let tint: Color

    var body: some View {
        Canvas { context, size in
            switch item.id {
            case "retort_stand": drawRetortStand(context: &context, size: size)
            case "clamp": drawClamp(context: &context, size: size)
            case "string": drawString(context: &context, size: size)
            case "bob": drawBob(context: &context, size: size)
            case "metre_rule": drawMetreRule(context: &context, size: size)
            case "stopwatch": drawStopwatch(context: &context, size: size)
            default: drawFallback(context: &context, size: size)
            }
        }
        .frame(width: 40, height: 40)
    }

    private func drawRetortStand(context: inout GraphicsContext, size: CGSize) {
        var path = Path()
        path.move(to: CGPoint(x: size.width * 0.2, y: size.height * 0.92))
        path.addLine(to: CGPoint(x: size.width * 0.8, y: size.height * 0.92))
        path.move(to: CGPoint(x: size.width * 0.35, y: size.height * 0.92))
        path.addLine(to: CGPoint(x: size.width * 0.35, y: size.height * 0.1))
        context.stroke(path, with: .color(tint), style: StrokeStyle(lineWidth: 3, lineCap: .round))
    }

    private func drawClamp(context: inout GraphicsContext, size: CGSize) {
        var jaw = Path()
        jaw.move(to: CGPoint(x: size.width * 0.15, y: size.height * 0.4))
        jaw.addLine(to: CGPoint(x: size.width * 0.75, y: size.height * 0.4))
        jaw.move(to: CGPoint(x: size.width * 0.15, y: size.height * 0.6))
        jaw.addLine(to: CGPoint(x: size.width * 0.75, y: size.height * 0.6))
        context.stroke(jaw, with: .color(tint), style: StrokeStyle(lineWidth: 4, lineCap: .round))
        var screw = Path()
        screw.move(to: CGPoint(x: size.width * 0.8, y: size.height * 0.3))
        screw.addLine(to: CGPoint(x: size.width * 0.8, y: size.height * 0.7))
        context.stroke(screw, with: .color(tint), style: StrokeStyle(lineWidth: 3, lineCap: .round))
    }

    private func drawString(context: inout GraphicsContext, size: CGSize) {
        var path = Path()
        path.move(to: CGPoint(x: size.width * 0.5, y: size.height * 0.05))
        path.addCurve(
            to: CGPoint(x: size.width * 0.5, y: size.height * 0.95),
            control1: CGPoint(x: size.width * 0.75, y: size.height * 0.35),
            control2: CGPoint(x: size.width * 0.25, y: size.height * 0.65)
        )
        context.stroke(path, with: .color(tint), style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }

    private func drawBob(context: inout GraphicsContext, size: CGSize) {
        let r = size.width * 0.28
        let center = CGPoint(x: size.width / 2, y: size.height * 0.6)
        var hang = Path()
        hang.move(to: CGPoint(x: center.x, y: size.height * 0.05))
        hang.addLine(to: CGPoint(x: center.x, y: center.y - r))
        context.stroke(hang, with: .color(tint), style: StrokeStyle(lineWidth: 2))
        context.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)), with: .color(tint))
    }

    private func drawMetreRule(context: inout GraphicsContext, size: CGSize) {
        let rect = CGRect(x: size.width * 0.35, y: size.height * 0.05, width: size.width * 0.3, height: size.height * 0.9)
        context.stroke(RoundedRectangle(cornerRadius: 2).path(in: rect), with: .color(tint), lineWidth: 2)
        var ticks = Path()
        for i in 1..<8 {
            let y = rect.minY + rect.height * CGFloat(i) / 8
            ticks.move(to: CGPoint(x: rect.minX, y: y))
            ticks.addLine(to: CGPoint(x: rect.minX + rect.width * 0.4, y: y))
        }
        context.stroke(ticks, with: .color(tint), lineWidth: 1)
    }

    private func drawStopwatch(context: inout GraphicsContext, size: CGSize) {
        let r = size.width * 0.35
        let center = CGPoint(x: size.width / 2, y: size.height * 0.58)
        context.stroke(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)), with: .color(tint), lineWidth: 2.5)
        var crown = Path()
        crown.move(to: CGPoint(x: center.x, y: center.y - r))
        crown.addLine(to: CGPoint(x: center.x, y: center.y - r - size.height * 0.12))
        context.stroke(crown, with: .color(tint), lineWidth: 2.5)
        var hand = Path()
        hand.move(to: center)
        hand.addLine(to: CGPoint(x: center.x + r * 0.5, y: center.y - r * 0.5))
        context.stroke(hand, with: .color(tint), lineWidth: 1.5)
    }

    private func drawFallback(context: inout GraphicsContext, size: CGSize) {
        context.draw(
            Image(systemName: item.systemImage).font(.title2).foregroundColor(tint),
            at: CGPoint(x: size.width / 2, y: size.height / 2)
        )
    }
}

// MARK: - Stage 1: Introduction

private struct IntroductionStageView: View {
    let viewModel: VirtualLabWorkflowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(viewModel.experiment.title)
                .font(.largeTitle.bold())

            labelledSection(title: "Aim", text: viewModel.experiment.aim)
            labelledSection(title: "Theory", text: viewModel.experiment.theory)
            labelledSection(title: "Learning outcome", text: viewModel.experiment.learningOutcome)

            Button("Start Experiment") { viewModel.startExperiment() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        }
    }

    private func labelledSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(text).font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Stage 2: Collect Apparatus

/// Real per-item drop targets rather than one shared bench — each apparatus
/// item has its own labelled zone, so dropping a piece of apparatus into a
/// zone that belongs to something else surfaces that item's own
/// `placementHint` (teaching, not just rejecting) instead of guessing at
/// order.
private struct CollectApparatusStageView: View {
    let viewModel: VirtualLabWorkflowViewModel
    @State private var zoneFrames: [String: CGRect] = [:]
    @State private var isChecking = false
    @State private var checkPassed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Collect Apparatus").font(.headline)
                Spacer()
                Text("\(viewModel.experiment.apparatusStageMarks) marks").font(.caption).foregroundStyle(.secondary)
            }

            Text("Drag each item onto its labelled spot on the bench.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let hint = viewModel.apparatusHint {
                Label(hint, systemImage: "lightbulb.fill")
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .transition(.opacity)
            }

            benchWithZones

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(viewModel.experiment.apparatusItems) { item in
                    ApparatusCard(
                        item: item,
                        isPlaced: viewModel.placedApparatus.contains(item.id),
                        zoneFrames: zoneFrames,
                        onDrop: { dropPoint in
                            handleDrop(of: item, at: dropPoint)
                        }
                    )
                }
            }

            if isChecking {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Teacher checks setup\u{2026}").font(.subheadline).foregroundStyle(.secondary)
                }
                .transition(.opacity)
            } else if checkPassed {
                Label("Correct \u{2014} well set up!", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
                Button("Proceed to Set Up") { viewModel.proceedToSetUp() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            }
        }
        .animation(.spring(response: 0.35), value: viewModel.allApparatusPlaced)
        .animation(.spring(response: 0.35), value: isChecking)
        .onChange(of: viewModel.allApparatusPlaced) { _, allPlaced in
            guard allPlaced else { return }
            isChecking = true
            Task {
                try? await Task.sleep(for: .seconds(0.9))
                isChecking = false
                checkPassed = true
            }
        }
    }

    private func handleDrop(of item: LabApparatusItem, at point: CGPoint) {
        guard let landedZoneID = zoneFrames.first(where: { $0.value.contains(point) })?.key else { return }
        viewModel.placeApparatus(item, isCorrectDrop: landedZoneID == item.id)
    }

    /// Wooden bench: warm gradient "wood grain" strokes, a faint alignment
    /// grid, and a soft shadow to lift it off the page.
    private var benchWithZones: some View {
        VStack(spacing: 6) {
            ForEach(viewModel.experiment.apparatusItems) { item in
                dropZone(for: item)
            }
        }
        .padding(10)
        .background(woodBenchBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }

    private func dropZone(for item: LabApparatusItem) -> some View {
        let isPlaced = viewModel.placedApparatus.contains(item.id)
        return HStack {
            Text(item.name)
                .font(.caption.weight(.medium))
                .foregroundStyle(isPlaced ? Color.white : Color.white.opacity(0.6))
            Spacer()
            if isPlaced {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.white.opacity(isPlaced ? 0.5 : 0.25), style: StrokeStyle(lineWidth: 1, dash: isPlaced ? [] : [4, 3]))
        )
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { zoneFrames[item.id] = geo.frame(in: .global) }
                    .onChange(of: geo.size) { _, _ in zoneFrames[item.id] = geo.frame(in: .global) }
            }
        )
    }

    private var woodBenchBackground: some View {
        Canvas { context, size in
            let woodBase = Color(red: 0.55, green: 0.38, blue: 0.24)
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(woodBase))

            // Wood-grain strokes: irregular-ish horizontal lines.
            var grain = Path()
            var y: CGFloat = 6
            while y < size.height {
                grain.move(to: CGPoint(x: 0, y: y))
                grain.addLine(to: CGPoint(x: size.width, y: y))
                y += 9
            }
            context.stroke(grain, with: .color(.black.opacity(0.08)), lineWidth: 1)

            // Faint alignment grid.
            var grid = Path()
            var x: CGFloat = 0
            while x < size.width {
                grid.move(to: CGPoint(x: x, y: 0))
                grid.addLine(to: CGPoint(x: x, y: size.height))
                x += 24
            }
            context.stroke(grid, with: .color(.white.opacity(0.05)), lineWidth: 1)
        }
    }
}

private struct ApparatusCard: View {
    let item: LabApparatusItem
    let isPlaced: Bool
    let zoneFrames: [String: CGRect]
    let onDrop: (CGPoint) -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var cardFrame: CGRect = .zero
    @State private var showingInfo = false

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Spacer()
                Button {
                    showingInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            ApparatusIconCanvas(item: item, tint: isPlaced ? .green : .accentColor)
            Text(item.name)
                .font(.caption.weight(.medium))
                .multilineTextAlignment(.center)
            if isPlaced {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .opacity(isPlaced ? 0.5 : 1)
        .offset(dragOffset)
        .background(
            GeometryReader { geo in
                Color.clear.onAppear { cardFrame = geo.frame(in: .global) }
            }
        )
        .highPriorityGesture(
            DragGesture(coordinateSpace: .global)
                .onChanged { value in
                    guard !isPlaced else { return }
                    dragOffset = value.translation
                }
                .onEnded { value in
                    guard !isPlaced else { return }
                    let dropPoint = CGPoint(x: cardFrame.midX + value.translation.width, y: cardFrame.midY + value.translation.height)
                    onDrop(dropPoint)
                    withAnimation(.spring(response: 0.3)) {
                        dragOffset = .zero
                    }
                }
        )
        .allowsHitTesting(!isPlaced)
        .popover(isPresented: $showingInfo) {
            ApparatusInfoView(item: item)
                .presentationCompactAdaptation(.popover)
        }
    }
}

private struct ApparatusInfoView: View {
    let item: LabApparatusItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(item.name).font(.headline)
            if item.precision != "N/A" && !item.precision.isEmpty {
                infoRow(label: "Precision", value: item.precision)
                infoRow(label: "Uncertainty", value: item.uncertainty)
            }
            if !item.usageDescription.isEmpty {
                Text(item.usageDescription)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(width: 260)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.caption.weight(.semibold))
        }
    }
}

// MARK: - Stage 3: Set Up

private struct SetUpStageView: View {
    let viewModel: VirtualLabWorkflowViewModel
    @State private var confirmedSteps: Set<String> = []
    @State private var isChecking = false
    @State private var checkPassed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Assemble the apparatus in order. Tap each step once you've done it.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(viewModel.experiment.apparatusItems) { item in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        confirmedSteps.insert(item.id)
                    }
                } label: {
                    HStack {
                        Image(systemName: confirmedSteps.contains(item.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(confirmedSteps.contains(item.id) ? .green : .secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name).font(.subheadline.weight(.medium))
                            Text(item.setUpInstruction).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            if isChecking {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Teacher checks setup\u{2026}").font(.subheadline).foregroundStyle(.secondary)
                }
                .transition(.opacity)
            } else if checkPassed {
                Label("Correct \u{2014} ready to begin!", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
                Button("Begin Experiment") { viewModel.proceedToCoreExperiment() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            }
        }
        .animation(.spring(response: 0.35), value: confirmedSteps.count)
        .animation(.spring(response: 0.35), value: isChecking)
        .onChange(of: confirmedSteps.count) { _, count in
            guard count == viewModel.experiment.apparatusItems.count else { return }
            isChecking = true
            Task {
                try? await Task.sleep(for: .seconds(0.9))
                isChecking = false
                checkPassed = true
            }
        }
    }
}

// MARK: - Stage 8: Practical Questions

private struct PracticalQuestionsStageView: View {
    let viewModel: VirtualLabWorkflowViewModel
    @State private var answers: [String: String] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Practical Questions").font(.headline)
                Spacer()
                Text("\(viewModel.experiment.questionStageMarks) marks").font(.caption).foregroundStyle(.secondary)
            }

            Text("Answer each question the way you would on the real exam paper.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(viewModel.experiment.practicalQuestions) { question in
                VStack(alignment: .leading, spacing: 8) {
                    Text(question.prompt).font(.subheadline.weight(.medium))
                    TextField("Your answer", text: Binding<String>(
                        get: { answers[question.id] ?? "" },
                        set: { newValue in
                            answers[question.id] = newValue
                            viewModel.recordAnswer(for: question, text: newValue)
                        }
                    ), axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    Text("\(question.marks) mark\(question.marks == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button("Continue to Conclusion") { viewModel.proceedToConclusion() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Stage 9: Conclusion

private struct ConclusionStageView: View {
    let viewModel: VirtualLabWorkflowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Conclusion").font(.headline)
                Spacer()
                Text("\(viewModel.experiment.conclusionStageMarks) marks").font(.caption).foregroundStyle(.secondary)
            }

            Text("Select the conclusion that best matches your results.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(Array(viewModel.experiment.conclusionOptions.enumerated()), id: \.offset) { index, option in
                Button {
                    viewModel.selectConclusion(index)
                } label: {
                    HStack {
                        Image(systemName: viewModel.conclusionSelection == index ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(viewModel.conclusionSelection == index ? Color.accentColor : Color.secondary)
                        Text(option).font(.subheadline)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Button("Finish Experiment") { viewModel.finishExperiment() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(viewModel.conclusionSelection == nil)
        }
    }
}

// MARK: - Stage 10: Results

private struct ResultsStageView: View {
    let viewModel: VirtualLabWorkflowViewModel

    private var totalScore: Int { viewModel.sectionScores.reduce(0) { $0 + $1.score } }
    private var totalMax: Int { viewModel.sectionScores.reduce(0) { $0 + $1.maxScore } }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Examiner Report").font(.title2.bold())

            VStack(spacing: 0) {
                ForEach(viewModel.sectionScores) { section in
                    HStack {
                        Text(section.section).font(.subheadline)
                        Spacer()
                        Text("\(section.score)/\(section.maxScore)").font(.subheadline.weight(.semibold))
                    }
                    .padding(.vertical, 10)
                    if section.id != viewModel.sectionScores.last?.id {
                        Divider()
                    }
                }
                Divider()
                HStack {
                    Text("Total").font(.headline)
                    Spacer()
                    Text("\(totalScore)/\(totalMax)").font(.headline)
                }
                .padding(.top, 10)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Button("View examiner feedback") { viewModel.viewExaminerFeedback() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Stage 11: Examiner Feedback

private struct ExaminerFeedbackStageView: View {
    let viewModel: VirtualLabWorkflowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Examiner Feedback").font(.title2.bold())

            ForEach(viewModel.examinerNotes) { note in
                ExaminerNoteRow(note: note)
            }

            Button("New attempt") { viewModel.restart() }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
        }
    }
}

private struct ExaminerNoteRow: View {
    let note: ExaminerFeedbackNote

    private var iconName: String {
        if note.isPositive {
            return "checkmark.circle.fill"
        } else {
            return "arrow.up.circle.fill"
        }
    }

    private var tintColor: Color {
        if note.isPositive {
            return Color.green
        } else {
            return Color.orange
        }
    }

    var body: some View {
        Label(note.text, systemImage: iconName)
            .font(.subheadline)
            .foregroundStyle(tintColor)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tintColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
