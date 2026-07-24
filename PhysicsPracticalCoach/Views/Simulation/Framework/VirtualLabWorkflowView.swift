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
import UIKit
import AudioToolbox

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
            .background {
                if usesLabRoomBackdrop {
                    LabRoomBackdrop()
                } else {
                    Color(.systemGroupedBackground)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.experiment.title)
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeOut(duration: 0.25), value: viewModel.stage)
    }

    /// The three "getting ready" stages get the illustrated lab-room
    /// backdrop; the data-heavy stages (perform, questions, results, ...)
    /// stay on a plain grouped background so tables/charts/forms stay easy
    /// to read.
    private var usesLabRoomBackdrop: Bool {
        switch viewModel.stage {
        case .introduction, .collectApparatus, .setUp: true
        default: false
        }
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
    /// Lets call sites render the same line-art bigger (e.g. a large ghost
    /// outline on the bench) or at the original compact shelf size.
    var iconSize: CGFloat = 40

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
        .frame(width: iconSize, height: iconSize)
    }

    private func drawRetortStand(context: inout GraphicsContext, size: CGSize) {
        var path = Path()
        path.move(to: CGPoint(x: size.width * 0.2, y: size.height * 0.92))
        path.addLine(to: CGPoint(x: size.width * 0.8, y: size.height * 0.92))
        path.move(to: CGPoint(x: size.width * 0.35, y: size.height * 0.92))
        path.addLine(to: CGPoint(x: size.width * 0.35, y: size.height * 0.1))
        context.stroke(path, with: .color(tint), style: StrokeStyle(lineWidth: 3, lineCap: .round))

        // Metallic highlight running down the pole, like light catching a rod.
        var highlight = Path()
        highlight.move(to: CGPoint(x: size.width * 0.37, y: size.height * 0.85))
        highlight.addLine(to: CGPoint(x: size.width * 0.37, y: size.height * 0.14))
        context.stroke(highlight, with: .color(.white.opacity(0.35)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
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

        var highlight = Path()
        highlight.move(to: CGPoint(x: size.width * 0.18, y: size.height * 0.42))
        highlight.addLine(to: CGPoint(x: size.width * 0.7, y: size.height * 0.42))
        context.stroke(highlight, with: .color(.white.opacity(0.3)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
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

        // Sphere: radial gradient + a small shine ellipse, rather than a flat fill.
        let ballRect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
        context.fill(
            Path(ellipseIn: ballRect),
            with: .radialGradient(
                Gradient(colors: [tint.opacity(0.9), tint]),
                center: CGPoint(x: center.x - r * 0.35, y: center.y - r * 0.35),
                startRadius: 0,
                endRadius: r * 1.4
            )
        )
        let shineRect = CGRect(x: center.x - r * 0.55, y: center.y - r * 0.6, width: r * 0.55, height: r * 0.4)
        context.fill(Path(ellipseIn: shineRect), with: .color(.white.opacity(0.4)))
    }

    private func drawMetreRule(context: inout GraphicsContext, size: CGSize) {
        let rect = CGRect(x: size.width * 0.35, y: size.height * 0.05, width: size.width * 0.3, height: size.height * 0.9)
        context.fill(
            RoundedRectangle(cornerRadius: 2).path(in: rect),
            with: .linearGradient(
                Gradient(colors: [tint.opacity(0.85), tint.opacity(0.55)]),
                startPoint: CGPoint(x: rect.minX, y: 0),
                endPoint: CGPoint(x: rect.maxX, y: 0)
            )
        )
        context.stroke(RoundedRectangle(cornerRadius: 2).path(in: rect), with: .color(tint), lineWidth: 1.5)
        var ticks = Path()
        for i in 1..<8 {
            let y = rect.minY + rect.height * CGFloat(i) / 8
            ticks.move(to: CGPoint(x: rect.minX, y: y))
            ticks.addLine(to: CGPoint(x: rect.minX + rect.width * 0.4, y: y))
        }
        context.stroke(ticks, with: .color(.white.opacity(0.7)), lineWidth: 1)
    }

    private func drawStopwatch(context: inout GraphicsContext, size: CGSize) {
        let r = size.width * 0.35
        let center = CGPoint(x: size.width / 2, y: size.height * 0.58)
        let circleRect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
        context.fill(
            Path(ellipseIn: circleRect),
            with: .radialGradient(Gradient(colors: [tint.opacity(0.22), tint.opacity(0.02)]), center: center, startRadius: 0, endRadius: r)
        )
        context.stroke(Path(ellipseIn: circleRect), with: .color(tint), lineWidth: 2.5)
        var crown = Path()
        crown.move(to: CGPoint(x: center.x, y: center.y - r))
        crown.addLine(to: CGPoint(x: center.x, y: center.y - r - size.height * 0.12))
        context.stroke(crown, with: .color(tint), lineWidth: 2.5)
        var hand = Path()
        hand.move(to: center)
        hand.addLine(to: CGPoint(x: center.x + r * 0.5, y: center.y - r * 0.5))
        context.stroke(hand, with: .color(tint), lineWidth: 1.5)

        // Glass-face shine, a short arc near the top edge.
        var shine = Path()
        shine.addArc(center: center, radius: r * 0.75, startAngle: .degrees(-150), endAngle: .degrees(-80), clockwise: false)
        context.stroke(shine, with: .color(.white.opacity(0.35)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
    }

    private func drawFallback(context: inout GraphicsContext, size: CGSize) {
        context.draw(
            Text(Image(systemName: item.systemImage)).font(.title2).foregroundColor(tint),
            at: CGPoint(x: size.width / 2, y: size.height / 2)
        )
    }
}

// MARK: - Stage 1: Introduction

private struct IntroductionStageView: View {
    let viewModel: VirtualLabWorkflowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 12) {
                LabCoachAvatar()
                Text(viewModel.experiment.title)
                    .font(.largeTitle.bold())
            }

            WhiteboardCard(eyebrow: "Today's Aim", text: viewModel.experiment.aim)

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

/// A single shared bench that accepts a drop anywhere on it — each
/// apparatus item still has its own labelled slot, but the student doesn't
/// need to aim for it. Dropping a piece of apparatus onto the bench always
/// places it in its own correct spot.
private struct CollectApparatusStageView: View {
    let viewModel: VirtualLabWorkflowViewModel
    @State private var benchFrame: CGRect = .zero
    @State private var isChecking = false
    @State private var checkPassed = false
    @State private var isDraggingCard = false

    private var slots: [BenchSlot] { BenchSlot.layout(for: viewModel.experiment.apparatusItems) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Collect Apparatus").font(.headline)
                Spacer()
                Text("\(viewModel.experiment.apparatusStageMarks) marks").font(.caption).foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 12) {
                LabCoachAvatar(size: 44)
                WhiteboardCard(
                    eyebrow: "Step \(LabExperimentStage.collectApparatus.rawValue + 1)",
                    text: "Pick up apparatus from the shelf and carry it to its spot on the workbench."
                )
            }

            if let hint = viewModel.apparatusHint {
                Label(hint, systemImage: "lightbulb.fill")
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .transition(.opacity)
            }

            equipmentShelf

            workbench

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
        .animation(Animation.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.allApparatusPlaced)
        .animation(Animation.spring(response: 0.35, dampingFraction: 0.7), value: isChecking)
        .onChange(of: viewModel.allApparatusPlaced) { _, allPlaced in
            guard allPlaced else { return }
            isChecking = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                isChecking = false
                checkPassed = true
            }
        }
        .sensoryFeedback(.success, trigger: viewModel.placedApparatus.count)
        .sensoryFeedback(.warning, trigger: viewModel.apparatusHint) { _, new in new != nil }
    }

    /// Laboratory equipment shelf: a horizontal strip the student picks
    /// apparatus up from, echoing a real prep-room shelf rather than a
    /// generic grid of cards.
    private var equipmentShelf: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("EQUIPMENT SHELF")
                .font(.caption2.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(viewModel.experiment.apparatusItems) { item in
                        ShelfApparatusCard(
                            item: item,
                            isPlaced: viewModel.placedApparatus.contains(item.id),
                            onDragStateChange: { dragging in isDraggingCard = dragging },
                            onDrop: { dropPoint in handleDrop(of: item, at: dropPoint) }
                        )
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
            }
            .scrollClipDisabled()
            .scrollDisabled(isDraggingCard)
            .zIndex(isDraggingCard ? 1 : 0)
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    /// The wooden workbench — the only valid drop destination. Each
    /// apparatus item has a fixed, non-overlapping labelled slot, but a drop
    /// anywhere on the bench places the item — no need to aim for the
    /// slot itself; it always snaps into its own correct spot.
    private var workbench: some View {
        GeometryReader { geo in
            ZStack {
                woodBenchBackground

                ForEach(slots) { slot in
                    let isPlaced = viewModel.placedApparatus.contains(slot.item.id)
                    BenchSlotView(item: slot.item, isPlaced: isPlaced)
                        .position(x: geo.size.width * slot.point.x, y: geo.size.height * slot.point.y)
                }

                if viewModel.placedApparatus.isEmpty {
                    Text("Drag apparatus from the shelf onto the workbench.")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .padding(.horizontal, 24)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(
                Color.clear
                    .onAppear { benchFrame = geo.frame(in: .global) }
                    .onChange(of: geo.size) { _, _ in benchFrame = geo.frame(in: .global) }
            )
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(WorkbenchGlow(isActive: viewModel.placedApparatus.isEmpty))
        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 6)
    }

    /// Any drop that lands anywhere on the workbench places the apparatus —
    /// no need to aim for a specific slot or circle. The item always snaps
    /// into its own correct, pre-assigned position on the bench (rendered by
    /// `BenchSlot.layout`), so "drop it on the bench" is the only skill the
    /// student needs; the app figures out exactly where it belongs.
    private func handleDrop(of item: LabApparatusItem, at point: CGPoint) {
        guard benchFrame != .zero, benchFrame.insetBy(dx: -40, dy: -40).contains(point) else { return }
        viewModel.placeApparatus(item, isCorrectDrop: true)
    }

    /// Wooden bench: warm gradient, "wood grain" strokes, a faint alignment
    /// grid, and a soft shadow to lift it off the page.
    private var woodBenchBackground: some View {
        Canvas { context, size in
            let woodBase = Color(red: 0.55, green: 0.38, blue: 0.24)
            let woodEdge = Color(red: 0.42, green: 0.28, blue: 0.17)
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    Gradient(colors: [woodBase, woodEdge]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: size.height)
                )
            )

            // Wood-grain strokes: irregular-ish horizontal lines.
            var grain = Path()
            var y: CGFloat = 6
            while y < size.height {
                grain.move(to: CGPoint(x: 0, y: y))
                grain.addLine(to: CGPoint(x: size.width, y: y))
                y += 9
            }
            context.stroke(grain, with: .color(.black.opacity(0.08)), lineWidth: 1)

            // Faint alignment grid, like graph paper resting on the bench.
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

/// One labelled position on the workbench that an apparatus item snaps
/// into. Laid out automatically from the experiment's apparatus list so
/// every experiment (Pendulum, Spring, Ohm's Law, ...) gets a sensible,
/// non-overlapping bench arrangement without hand-tuned coordinates.
private struct BenchSlot: Identifiable {
    let item: LabApparatusItem
    /// Fractional position within the bench, 0...1 on each axis.
    let point: CGPoint
    var id: String { item.id }

    static func layout(for items: [LabApparatusItem]) -> [BenchSlot] {
        guard !items.isEmpty else { return [] }
        let columns = items.count <= 2 ? items.count : (items.count <= 4 ? 2 : 3)
        let rows = Int(ceil(Double(items.count) / Double(columns)))
        let marginX: CGFloat = 0.16
        let marginY: CGFloat = 0.22
        let usableWidth = 1 - marginX * 2
        let usableHeight = 1 - marginY * 2

        return items.enumerated().map { index, item in
            let col = index % columns
            let row = index / columns
            let x = marginX + usableWidth * (CGFloat(col) + 0.5) / CGFloat(columns)
            let y = marginY + usableHeight * (CGFloat(row) + 0.5) / CGFloat(max(rows, 1))
            return BenchSlot(item: item, point: CGPoint(x: x, y: y))
        }
    }
}

/// A single slot's visual state: a dashed placeholder while empty, and the
/// apparatus's own icon settling in with a spring "bounce" once placed.
private struct BenchSlotView: View {
    let item: LabApparatusItem
    let isPlaced: Bool

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Circle()
                    .strokeBorder(
                        Color.white.opacity(isPlaced ? 0 : 0.4),
                        style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
                    )
                    .background(Circle().fill(isPlaced ? Color.white.opacity(0.12) : .clear))
                    .frame(width: 56, height: 56)

                if isPlaced {
                    ApparatusIconCanvas(item: item, tint: .white)
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                }
            }
            .shadow(color: .black.opacity(isPlaced ? 0.35 : 0), radius: 5, x: 0, y: 3)

            Text(item.name)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(isPlaced ? 0.95 : 0.55))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if isPlaced {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
        }
        .frame(width: 76)
        .animation(.interpolatingSpring(stiffness: 170, damping: 12), value: isPlaced)
    }
}

/// A subtle pulsing highlight around the bench, guiding a student to it
/// until the first piece of apparatus is placed — self-contained so its
/// looping animation never entangles with the rest of the stage's state.
private struct WorkbenchGlow: View {
    let isActive: Bool
    @State private var pulse = false

    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(Color.accentColor, lineWidth: 3)
            .opacity(isActive ? (pulse ? 0.85 : 0.35) : 0)
            .shadow(color: Color.accentColor.opacity(isActive ? (pulse ? 0.55 : 0.15) : 0), radius: 8)
            .animation(isActive ? .easeInOut(duration: 1.1).repeatForever(autoreverses: true) : .default, value: pulse)
            .allowsHitTesting(false)
            .onAppear { pulse = true }
    }
}

/// A piece of apparatus on the shelf, ready to be picked up. Dragging lifts
/// it off the shelf with a scale-up, a deeper shadow and a gentle tilt so
/// it feels like a physical object being carried to the bench, then either
/// snaps onto the workbench (handled by the parent via `onDrop`) or springs
/// back to the shelf if released anywhere else.
private struct ShelfApparatusCard: View {
    let item: LabApparatusItem
    let isPlaced: Bool
    let onDragStateChange: (Bool) -> Void
    let onDrop: (CGPoint) -> Void

    @State private var dragTranslation: CGSize = .zero
    @State private var isDragging = false
    @State private var cardFrame: CGRect = .zero
    @State private var showingInfo = false

    private var rotation: Angle {
        .degrees(max(-8, min(8, dragTranslation.width / 12)))
    }

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
                .lineLimit(2)
        }
        .frame(width: 92)
        .padding(10)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .opacity(isPlaced ? 0.35 : 1)
        .scaleEffect(isDragging ? 1.1 : 1)
        .rotationEffect(rotation)
        .offset(x: dragTranslation.width, y: dragTranslation.height - (isDragging ? 14 : 0))
        .shadow(color: .black.opacity(isDragging ? 0.28 : 0.1), radius: isDragging ? 14 : 4, x: 0, y: isDragging ? 10 : 2)
        .zIndex(isDragging ? 1 : 0)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { cardFrame = geo.frame(in: .global) }
                    .onChange(of: geo.frame(in: .global)) { _, newFrame in
                        if !isDragging { cardFrame = newFrame }
                    }
            }
        )
        .highPriorityGesture(
            DragGesture(minimumDistance: 4, coordinateSpace: .global)
                .onChanged { value in
                    guard !isPlaced else { return }
                    if !isDragging { onDragStateChange(true) }
                    isDragging = true
                    dragTranslation = value.translation
                }
                .onEnded { value in
                    guard !isPlaced else { return }
                    let dropPoint = CGPoint(
                        x: cardFrame.midX + value.translation.width,
                        y: cardFrame.midY + value.translation.height
                    )
                    onDrop(dropPoint)
                    onDragStateChange(false)
                    withAnimation(Animation.spring(response: 0.32, dampingFraction: 0.7)) {
                        dragTranslation = .zero
                        isDragging = false
                    }
                }
        )
        .allowsHitTesting(!isPlaced)
        .popover(isPresented: $showingInfo) {
            ApparatusInfoView(item: item)
        }
        .presentationCompactAdaptation(.popover)
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
            HStack(alignment: .top, spacing: 12) {
                LabCoachAvatar(size: 44)
                WhiteboardCard(
                    eyebrow: "Step \(LabExperimentStage.setUp.rawValue + 1)",
                    text: "Assemble the apparatus in order. Tap each step once you've done it."
                )
            }

            ForEach(viewModel.experiment.apparatusItems) { item in
                SetUpStepRow(
                    item: item,
                    isConfirmed: confirmedSteps.contains(item.id),
                    onTap: {
                        withAnimation(Animation.spring(response: 0.3, dampingFraction: 0.7)) {
                            _ = confirmedSteps.insert(item.id)
                        }
                    }
                )
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
        .animation(Animation.spring(response: 0.35, dampingFraction: 0.7), value: confirmedSteps)
        .animation(Animation.spring(response: 0.35, dampingFraction: 0.7), value: isChecking)
        .onChange(of: confirmedSteps) { _, updatedSteps in
            guard updatedSteps.count == viewModel.experiment.apparatusItems.count else { return }
            isChecking = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                isChecking = false
                checkPassed = true
            }
        }
    }
}

private struct SetUpStepRow: View {
    let item: LabApparatusItem
    let isConfirmed: Bool
    let onTap: () -> Void

    private var iconName: String {
        if isConfirmed {
            return "checkmark.circle.fill"
        } else {
            return "circle"
        }
    }

    private var iconColor: Color {
        if isConfirmed {
            return Color.green
        } else {
            return Color.secondary
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: iconName).foregroundStyle(iconColor)
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
                PracticalQuestionRow(
                    question: question,
                    answer: answers[question.id] ?? "",
                    onAnswerChanged: { newValue in
                        answers[question.id] = newValue
                        viewModel.recordAnswer(for: question, text: newValue)
                    }
                )
            }

            Button("Continue to Conclusion") { viewModel.proceedToConclusion() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        }
    }
}

private struct PracticalQuestionRow: View {
    let question: ExperimentQuestion
    let answer: String
    let onAnswerChanged: (String) -> Void

    private var marksLabel: String {
        if question.marks == 1 {
            return "1 mark"
        } else {
            return "\(question.marks) marks"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question.prompt).font(.subheadline.weight(.medium))
            TextField("Your answer", text: Binding<String>(
                get: { answer },
                set: { onAnswerChanged($0) }
            ), axis: .vertical)
            .textFieldStyle(.roundedBorder)
            Text(marksLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                ConclusionOptionRow(
                    option: option,
                    isSelected: viewModel.conclusionSelection == index,
                    onTap: { viewModel.selectConclusion(index) }
                )
            }

            Button("Finish Experiment") { viewModel.finishExperiment() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(viewModel.conclusionSelection == nil)
        }
    }
}

// MARK: - Stage 10: Results

private struct ConclusionOptionRow: View {
    let option: String
    let isSelected: Bool
    let onTap: () -> Void

    private var iconName: String {
        if isSelected {
            return "largecircle.fill.circle"
        } else {
            return "circle"
        }
    }

    private var iconColor: Color {
        if isSelected {
            return Color.accentColor
        } else {
            return Color.secondary
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: iconName).foregroundStyle(iconColor)
                Text(option).font(.subheadline)
                Spacer()
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct ResultsStageView: View {
    let viewModel: VirtualLabWorkflowViewModel

    private var totalScore: Int { viewModel.sectionScores.reduce(0) { $0 + $1.score } }
    private var totalMax: Int { viewModel.sectionScores.reduce(0) { $0 + $1.maxScore } }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Examiner Report").font(.title2.bold())

            VStack(spacing: 0) {
                ForEach(viewModel.sectionScores) { section in
                    SectionScoreRow(
                        section: section,
                        isLast: section.id == viewModel.sectionScores.last?.id
                    )
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

private struct SectionScoreRow: View {
    let section: ExperimentSectionScore
    let isLast: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(section.section).font(.subheadline)
                Spacer()
                Text("\(section.score)/\(section.maxScore)").font(.subheadline.weight(.semibold))
            }
            .padding(.vertical, 10)
            if !isLast {
                Divider()
            }
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
