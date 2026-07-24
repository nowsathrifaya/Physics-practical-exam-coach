//
//  CentreOfGravityLabView.swift
//  PhysicsPracticalCoach
//
//  Centre of Gravity lab experiment, built on the Lab framework (see
//  `PendulumLabView.swift` for the reference template and `LAB_FRAMEWORK.md`
//  for the architecture). Fills the syllabus gap for "determination of the
//  position of the centre of gravity of a plane lamina". The student hangs
//  an irregular lamina from three fixed holes in turn, traces the plumb
//  line each time, then taps where the three lines cross \u{2014} a genuinely
//  different interaction from every other lab (point-estimation rather than
//  typed numeric reading), but graded the same tolerance-based way.
//
//  Physics note: a plumb line from ANY suspension point always passes
//  through the centre of gravity, so each traced line is simply drawn as
//  the straight line from that hole through the (hidden) true centre of
//  gravity, extended across the lamina \u{2014} exactly what happens physically.
//

import SwiftUI

// MARK: - 1. Apparatus state

/// All points are normalised fractions of the lamina's bounding box
/// (0...1 in both axes), converted to real centimetres via
/// `laminaWidthCm`/`laminaHeightCm` for tolerance grading \u{2014} this keeps the
/// physics independent of whatever pixel size the device renders at.
@Observable
final class CentreOfGravityLabState {
    static let laminaWidthCm = 20.0
    static let laminaHeightCm = 20.0

    /// Fixed irregular lamina outline, normalised (0...1) coordinates.
    static let laminaShapeNorm: [CGPoint] = [
        CGPoint(x: 0.15, y: 0.10), CGPoint(x: 0.55, y: 0.05), CGPoint(x: 0.90, y: 0.30),
        CGPoint(x: 0.80, y: 0.55), CGPoint(x: 0.95, y: 0.85), CGPoint(x: 0.50, y: 0.95),
        CGPoint(x: 0.20, y: 0.75), CGPoint(x: 0.05, y: 0.40)
    ]

    /// Three fixed suspension holes near the lamina's edge, normalised.
    static let holesNorm: [CGPoint] = [
        CGPoint(x: 0.18, y: 0.14), CGPoint(x: 0.85, y: 0.32), CGPoint(x: 0.30, y: 0.90)
    ]

    /// Hidden true centre of gravity, randomised within a safe interior box
    /// that stays well inside `laminaShapeNorm` for every seed.
    let trueCoGNorm: CGPoint

    private(set) var activatedHoles: Set<Int> = []
    private(set) var tappedPointNorm: CGPoint?

    init(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        let x = rng.nextDouble(0.42, 0.58)
        let y = rng.nextDouble(0.42, 0.58)
        trueCoGNorm = CGPoint(x: x, y: y)
    }

    func hangFrom(_ holeIndex: Int) {
        activatedHoles.insert(holeIndex)
    }

    func setTappedPoint(_ point: CGPoint) {
        tappedPointNorm = point
    }
}

// MARK: - 2. Experiment view model

@MainActor
@Observable
final class CentreOfGravityExperimentViewModel {
    private(set) var apparatus: CentreOfGravityLabState
    private let recorder: LabAttemptRecorder
    private(set) var result: LabRunResult?

    /// Tolerance for the tapped estimate, in real-world centimetres.
    private static let toleranceCm = 1.5

    init(recorder: LabAttemptRecorder, seed: Int) {
        self.recorder = recorder
        self.apparatus = CentreOfGravityLabState(seed: seed)
    }

    var instructionText: String {
        if apparatus.activatedHoles.count < 3 {
            return "Tap each hole (H1, H2, H3) to hang the lamina and trace the plumb line each time."
        }
        if apparatus.tappedPointNorm == nil {
            return "Now tap the point where all three plumb lines cross \u{2014} that's the centre of gravity."
        }
        return "Tap 'Confirm centre of gravity' to check your estimate."
    }

    func hangFrom(_ holeIndex: Int) {
        apparatus.hangFrom(holeIndex)
    }

    func recordTap(_ point: CGPoint) {
        guard apparatus.activatedHoles.count >= 3, result == nil else { return }
        apparatus.setTappedPoint(point)
    }

    var canConfirm: Bool { apparatus.tappedPointNorm != nil }

    func confirmEstimate() {
        guard let tapped = apparatus.tappedPointNorm else { return }
        let dxCm = Double(tapped.x - apparatus.trueCoGNorm.x) * CentreOfGravityLabState.laminaWidthCm
        let dyCm = Double(tapped.y - apparatus.trueCoGNorm.y) * CentreOfGravityLabState.laminaHeightCm
        let errorCm = (dxCm * dxCm + dyCm * dyCm).squareRoot()
        let correct = errorCm <= Self.toleranceCm

        let feedback = [
            "Your estimate was \(String(format: "%.1f", errorCm)) cm from the true centre of gravity.",
            "Accepted tolerance: within \(String(format: "%.1f", Self.toleranceCm)) cm.",
            correct
                ? "All three plumb lines should cross at (almost) exactly the same point \u{2014} yours did."
                : "If your estimate is off, re-check that each plumb line was traced only after the lamina had stopped swinging."
        ]

        let outcome = LabRunResult(
            correct: correct,
            score: correct ? 100 : max(30, Int(100 - errorCm * 20)),
            feedback: feedback,
            examTip: "A plumb line from any suspension point always passes through the centre of gravity \u{2014} that's why three lines from three different holes all cross at the same spot. Two lines are enough in principle, but a third is used as a check."
        )
        result = outcome
        recorder.record(experimentTitle: SimulationType.centreOfGravity.label, result: outcome)
    }

    func newTask() {
        var rng = SeededRandomNumberGenerator(seed: Int.random(in: 0...Int(Int32.max)))
        apparatus = CentreOfGravityLabState(seed: rng.nextInt(0, Int(Int32.max)))
        result = nil
    }
}

// MARK: - View

struct CentreOfGravityLabView: View {
    let curriculum: Curriculum
    @State private var viewModel: CentreOfGravityExperimentViewModel

    init(curriculum: Curriculum, repository: AttemptRepository) {
        self.curriculum = curriculum
        _viewModel = State(initialValue: CentreOfGravityExperimentViewModel(
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum),
            seed: Int.random(in: 0...Int(Int32.max))
        ))
    }

    var body: some View {
        LabScaffoldView(
            title: "Centre of Gravity Lab",
            instructionText: viewModel.instructionText,
            apparatusHeight: 340,
            result: viewModel.result,
            apparatus: { apparatusArea },
            controls: { controls }
        )
    }

    private var apparatusArea: some View {
        GeometryReader { geo in
            let size = geo.size
            let inset: CGFloat = 20
            let drawableWidth = size.width - inset * 2
            let drawableHeight = size.height - inset * 2

            func point(_ norm: CGPoint) -> CGPoint {
                CGPoint(x: inset + norm.x * drawableWidth, y: inset + norm.y * drawableHeight)
            }

            ZStack {
                Canvas { context, _ in
                    var lamina = Path()
                    let shapePoints = CentreOfGravityLabState.laminaShapeNorm.map(point)
                    lamina.move(to: shapePoints[0])
                    for p in shapePoints.dropFirst() { lamina.addLine(to: p) }
                    lamina.closeSubpath()
                    context.fill(lamina, with: .color(Color(hex: "#C99A63").opacity(0.35)))
                    context.stroke(lamina, with: .color(Color(hex: "#8B6B3E")), lineWidth: 2)

                    // Plumb lines through the true centre of gravity, extended
                    // across the whole lamina, for every activated hole.
                    let cog = point(viewModel.apparatus.trueCoGNorm)
                    for index in viewModel.apparatus.activatedHoles {
                        let hole = point(CentreOfGravityLabState.holesNorm[index])
                        let direction = CGPoint(x: cog.x - hole.x, y: cog.y - hole.y)
                        let extended = CGPoint(x: cog.x + direction.x * 3, y: cog.y + direction.y * 3)
                        var line = Path()
                        line.move(to: hole)
                        line.addLine(to: extended)
                        context.stroke(line, with: .color(.red.opacity(0.6)), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    }

                    for (index, holeNorm) in CentreOfGravityLabState.holesNorm.enumerated() {
                        let holePoint = point(holeNorm)
                        let isActive = viewModel.apparatus.activatedHoles.contains(index)
                        context.fill(
                            Path(ellipseIn: CGRect(x: holePoint.x - 6, y: holePoint.y - 6, width: 12, height: 12)),
                            with: .color(isActive ? Color(hex: "#2980B9") : Color(.systemGray3))
                        )
                        LabCanvasHelpers.drawLabel(context: context, text: "H\(index + 1)", at: CGPoint(x: holePoint.x, y: holePoint.y - 14), size: 11)
                    }

                    if let tapped = viewModel.apparatus.tappedPointNorm {
                        let tappedPoint = point(tapped)
                        LabCanvasHelpers.drawLabel(context: context, text: "\u{2716}", at: tappedPoint, size: 18, weight: .bold, color: .green)
                    }

                    if viewModel.result != nil {
                        let truePoint = point(viewModel.apparatus.trueCoGNorm)
                        LabCanvasHelpers.drawLabel(context: context, text: "\u{25CF}", at: truePoint, size: 14, color: .blue)
                    }
                }

                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                let normX = (value.location.x - inset) / drawableWidth
                                let normY = (value.location.y - inset) / drawableHeight
                                viewModel.recordTap(CGPoint(x: normX, y: normY))
                            }
                    )
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        if viewModel.result == nil {
            Text("Suspension holes").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { index in
                    Button("Hang H\(index + 1)") { viewModel.hangFrom(index) }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.apparatus.activatedHoles.contains(index))
                }
            }

            if viewModel.canConfirm {
                Button("Confirm centre of gravity") { viewModel.confirmEstimate() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            }
        }

        if viewModel.result != nil {
            Button("New task") { viewModel.newTask() }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
        }
    }
}
