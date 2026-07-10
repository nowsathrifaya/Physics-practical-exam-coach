//
//  PendulumLabView.swift
//  PhysicsPracticalCoach
//
//  *** REFERENCE TEMPLATE — read this file first when building any new lab
//  experiment (Hooke's Law, Moments, Density, Ohm's Law, Lens, Refraction,
//  Reflection, Centre of Gravity, etc). Every future experiment should
//  follow the same two-type split used here: ***
//
//  1. An "apparatus state" type (`PendulumLabState`) — owns ONLY the
//     physical apparatus simulation: what the student sees and drags,
//     driven by real wall-clock time where relevant. It knows nothing about
//     tasks, trials, or grading. This is the part that's genuinely
//     experiment-specific and has no shared framework — a spring's apparatus
//     state looks nothing like a pendulum's, and that's expected.
//
//  2. An "experiment view model" type (`PendulumExperimentViewModel`) — owns
//     the task/session layer on top: what target the student was assigned,
//     the trials they've recorded (`[LabReading]`), and the grading
//     (`LabRunResult`) once they calculate their result. This layer is
//     *structurally* the same shape for every experiment (assign a random
//     target -> record N trials -> calculate -> grade -> record attempt via
//     `LabAttemptRecorder`), even though the physics inside each step
//     differs completely.
//
//  The View itself is thin: it composes `LabScaffoldView` with an
//  experiment-specific apparatus Canvas/DragGesture and experiment-specific
//  control buttons, and lets the shared framework render the data table and
//  feedback card. A new experiment's SwiftUI code should mostly be the
//  Canvas drawing + gesture handling; the surrounding chrome comes free.
//
//  EXAM DESIGN: this mirrors a real SEAB/WAEC/NECO pendulum practical —
//  set up a pendulum to an assigned length, time 20 oscillations (not one —
//  see `AceQuestionBank.pend_ace_01`, the same reasoning: spreads the
//  stopwatch reaction-time error over many swings), repeat for multiple
//  trials, then compare the average measured period against theory. The
//  student's own reaction time IS the experimental error here, exactly like
//  a real practical — nothing about the timing is simulated or faked.
//

import SwiftUI

// MARK: - 1. Apparatus state (physical simulation only)

@Observable
final class PendulumLabState {
    enum Phase { case settingLength, pulling, swinging }

    private static let g = 9.81

    private(set) var phase: Phase = .settingLength

    private(set) var lengthM: Double = 1.0 {
        didSet { lengthM = min(max(lengthM, 0.3), 1.5) }
    }

    /// Angle captured at the instant of release (degrees). 0 while not yet released.
    private(set) var releaseAngleDeg: Double = 0.0

    /// Wall-clock timestamp the bob was released — the physically true start
    /// of oscillation, independent of when the student reacts and starts
    /// counting.
    private(set) var swingStartTime: Date?

    var currentDragAngleDeg: Double = 0.0

    /// True period at small-angle approximation for the current length —
    /// this is the theoretical value exam marking compares against
    /// (T = 2\u{03C0}\u{221A}(L/g)), independent of whatever angle the student happened
    /// to release from.
    var theoreticalPeriodS: Double {
        2 * .pi * (lengthM / Self.g).squareRoot()
    }

    /// True period including the large-angle correction for the actual
    /// release angle used — drives the ANIMATION so a bigger release angle
    /// visibly swings slower, same physical realism as the Android version,
    /// even though grading uses the small-angle `theoreticalPeriodS` above
    /// (matching what a real exam mark scheme expects).
    private var animatedPeriodS: Double {
        let thetaRad = releaseAngleDeg * .pi / 180
        return theoreticalPeriodS * (1 + (thetaRad * thetaRad) / 16.0)
    }

    func setLength(_ value: Double) {
        lengthM = value
    }

    func beginPulling() {
        phase = .pulling
    }

    func release() {
        releaseAngleDeg = currentDragAngleDeg
        phase = .swinging
        swingStartTime = Date()
    }

    /// Wall-clock seconds elapsed since release — the raw value a student's
    /// "stop" tap captures, exactly like reading a real stopwatch.
    func elapsedSinceRelease(at now: Date) -> TimeInterval {
        guard let swingStartTime else { return 0 }
        return now.timeIntervalSince(swingStartTime)
    }

    /// Re-arms for another timing trial at the SAME length (matches a real
    /// practical: you set up the apparatus once, then repeat the timing
    /// measurement several times) — distinct from `reset()`, which returns
    /// all the way to length-setting for a brand new task.
    func rearmForNextTrial() {
        phase = .pulling
        releaseAngleDeg = 0
        swingStartTime = nil
        currentDragAngleDeg = 0
    }

    func reset() {
        phase = .settingLength
        releaseAngleDeg = 0
        swingStartTime = nil
        currentDragAngleDeg = 0
    }

    /// Current bob angle at wall-clock `now`, used purely for drawing.
    func angleDeg(at now: Date) -> Double {
        switch phase {
        case .settingLength: return 0
        case .pulling: return currentDragAngleDeg
        case .swinging:
            guard let swingStartTime else { return 0 }
            let elapsedS = now.timeIntervalSince(swingStartTime)
            return releaseAngleDeg * cos(2 * .pi * elapsedS / animatedPeriodS)
        }
    }
}

// MARK: - 2. Experiment view model (task, trials, grading)

@MainActor
@Observable
final class PendulumExperimentViewModel {
    let apparatus = PendulumLabState()
    private let recorder: LabAttemptRecorder

    private static let oscillationCount = 20
    private static let lengthToleranceM = 0.02
    private static let periodToleranceFraction = 0.08 // +/-8%, generous enough for real reaction-time error

    private(set) var targetLengthM: Double
    private(set) var readings: [LabReading] = []
    private(set) var result: LabRunResult?

    init(recorder: LabAttemptRecorder) {
        self.recorder = recorder
        var rng = SeededRandomNumberGenerator(seed: Int.random(in: 0...Int(Int32.max)))
        self.targetLengthM = (rng.nextDouble(0.4, 1.2) * 100).rounded() / 100
    }

    var lengthWithinTolerance: Bool {
        abs(apparatus.lengthM - targetLengthM) <= Self.lengthToleranceM
    }

    var instructionText: String {
        switch apparatus.phase {
        case .settingLength:
            return "Set up a pendulum of length \(String(format: "%.2f", targetLengthM)) m (\u{00B1}\(String(format: "%.2f", Self.lengthToleranceM)) m). Drag the bob up or down."
        case .pulling:
            return "Pull the bob to one side (small angle, under 10\u{00B0} for best results), then release."
        case .swinging:
            return "Count \(Self.oscillationCount) complete oscillations yourself, then tap Stop the instant the \(Self.oscillationCount)th one finishes."
        }
    }

    func confirmLength() {
        apparatus.beginPulling()
    }

    /// Student taps this the instant they've counted the assigned number of
    /// oscillations — their own timing/counting is the measurement, exactly
    /// like using a real stopwatch in the exam hall.
    func stopTiming() {
        let elapsed = apparatus.elapsedSinceRelease(at: Date())
        let period = elapsed / Double(Self.oscillationCount)
        let reading = LabReading(
            trialNumber: readings.count + 1,
            label: "t (\(Self.oscillationCount) osc)",
            value: (elapsed * 100).rounded() / 100,
            unit: "s",
            derivedLabel: "Period T",
            derivedValue: (period * 1000).rounded() / 1000,
            derivedUnit: "s"
        )
        readings.append(reading)
        apparatus.rearmForNextTrial()
    }

    func addAnotherTrial() {
        apparatus.rearmForNextTrial()
    }

    var canCalculate: Bool { !readings.isEmpty }

    func calculateResult() {
        let periods = readings.compactMap(\.derivedValue)
        guard !periods.isEmpty else { return }
        let averagePeriod = periods.reduce(0, +) / Double(periods.count)
        let theoretical = apparatus.theoreticalPeriodS
        let tolerance = theoretical * Self.periodToleranceFraction
        let periodCorrect = abs(averagePeriod - theoretical) <= tolerance

        var feedback: [String] = []
        feedback.append("Average measured period: \(format(averagePeriod)) s over \(readings.count) trial\(readings.count == 1 ? "" : "s").")
        feedback.append("Theoretical period for L = \(format(apparatus.lengthM)) m: \(format(theoretical)) s.")

        if !lengthWithinTolerance {
            feedback.append("Note: your set length (\(format(apparatus.lengthM)) m) was outside the \u{00B1}\(String(format: "%.2f", Self.lengthToleranceM)) m target tolerance \u{2014} apparatus setup accuracy is also marked in a real practical.")
        }
        if readings.count < 3 {
            feedback.append("Real exams expect at least 3 trials to average out reaction-time error \u{2014} try adding more trials next time.")
        }

        let correct = periodCorrect && lengthWithinTolerance
        let score: Int
        if correct {
            score = 100
        } else if periodCorrect {
            score = 70 // timing was accurate, setup wasn't
        } else {
            score = 40
        }

        let outcome = LabRunResult(
            correct: correct,
            score: score,
            feedback: feedback,
            examTip: "Time \(Self.oscillationCount) oscillations, not one \u{2014} it spreads your reaction-time error over many swings instead of one, which is exactly what the marking scheme rewards."
        )
        result = outcome
        recorder.record(experimentTitle: SimulationType.pendulum.label, result: outcome)
    }

    func newTask() {
        var rng = SeededRandomNumberGenerator(seed: Int.random(in: 0...Int(Int32.max)))
        targetLengthM = (rng.nextDouble(0.4, 1.2) * 100).rounded() / 100
        readings = []
        result = nil
        apparatus.reset()
    }

    private func format(_ value: Double) -> String { String(format: "%.3f", value) }
}

// MARK: - View

struct PendulumLabView: View {
    let curriculum: Curriculum
    @State private var viewModel: PendulumExperimentViewModel

    init(curriculum: Curriculum, repository: AttemptRepository) {
        self.curriculum = curriculum
        _viewModel = State(initialValue: PendulumExperimentViewModel(
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum)
        ))
    }

    var body: some View {
        LabScaffoldView(
            title: "Pendulum Lab",
            instructionText: viewModel.instructionText,
            readings: viewModel.readings,
            result: viewModel.result,
            apparatus: { apparatusCanvas },
            controls: { controls }
        )
    }

    private var apparatusCanvas: some View {
        TimelineView(.animation(paused: viewModel.apparatus.phase != .swinging)) { timeline in
            GeometryReader { geo in
                let pivot = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.08)
                let maxPendulumPx = geo.size.height * 0.74
                let lab = viewModel.apparatus
                let ropePx = (lab.lengthM / 1.5) * maxPendulumPx
                let angleDeg = lab.angleDeg(at: timeline.date)
                let angleRad = angleDeg * .pi / 180
                let bob = CGPoint(x: pivot.x + ropePx * sin(angleRad), y: pivot.y + ropePx * cos(angleRad))
                let overAngleLimit = lab.phase == .pulling && abs(lab.currentDragAngleDeg) > 10

                Canvas { context, _ in
                    if lab.phase == .settingLength {
                        LabCanvasHelpers.drawVerticalRuler(
                            context: context, originX: pivot.x - 70, topY: pivot.y,
                            heightPx: maxPendulumPx, maxValue: 1.5, minorStep: 0.1
                        )
                    }

                    var string = Path()
                    string.move(to: pivot)
                    string.addLine(to: bob)
                    context.stroke(string, with: .color(Color(hex: "#0F3D38")), lineWidth: 3)

                    LabCanvasHelpers.drawWeight(context: context, center: pivot, radiusPx: 5, color: Color(hex: "#0F5A4F"))
                    LabCanvasHelpers.drawWeight(
                        context: context, center: bob, radiusPx: 22,
                        color: overAngleLimit ? Color(hex: "#C0392B") : Color(hex: "#D98B36")
                    )

                    LabCanvasHelpers.drawLabel(
                        context: context, text: String(format: "L = %.2f m", lab.lengthM),
                        at: CGPoint(x: pivot.x, y: pivot.y + ropePx + 30)
                    )

                    if lab.phase == .pulling {
                        let angleText = overAngleLimit
                            ? String(format: "%.0f\u{00B0} \u{2014} large angle, aim under 10\u{00B0}", abs(lab.currentDragAngleDeg))
                            : String(format: "%.0f\u{00B0}", abs(lab.currentDragAngleDeg))
                        LabCanvasHelpers.drawLabel(
                            context: context, text: angleText, at: CGPoint(x: pivot.x, y: pivot.y + 24),
                            size: 13, weight: overAngleLimit ? .bold : .regular,
                            color: overAngleLimit ? Color(hex: "#C0392B") : .primary
                        )
                    }

                    if lab.phase == .swinging {
                        let elapsed = lab.elapsedSinceRelease(at: timeline.date)
                        LabCanvasHelpers.drawLabel(
                            context: context, text: String(format: "%.1f s", elapsed),
                            at: CGPoint(x: pivot.x, y: pivot.y + 24), size: 13, weight: .semibold
                        )
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            switch lab.phase {
                            case .settingLength:
                                let dy = max(value.location.y - pivot.y, 1)
                                lab.setLength((dy / maxPendulumPx) * 1.5)
                            case .pulling:
                                let dx = value.location.x - pivot.x
                                let dy = max(value.location.y - pivot.y, 1)
                                let angle = atan2(dx, dy) * 180 / .pi
                                lab.currentDragAngleDeg = min(max(angle, -45), 45)
                            case .swinging:
                                break
                            }
                        }
                        .onEnded { _ in
                            if lab.phase == .pulling {
                                lab.release()
                            }
                        }
                )
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        switch viewModel.apparatus.phase {
        case .settingLength:
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.lengthWithinTolerance ? "\u{2713} Length within target tolerance." : "Keep adjusting \u{2014} not yet within \u{00B1}0.02 m of the target.")
                    .font(.caption)
                    .foregroundStyle(viewModel.lengthWithinTolerance ? .green : .secondary)
                Button("Confirm length \u{2014} start pulling") { viewModel.confirmLength() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            }
        case .pulling:
            Text("Release by lifting your finger.")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .swinging:
            VStack(spacing: 12) {
                Button("Stop \u{2014} recorded 20th oscillation") { viewModel.stopTiming() }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .frame(maxWidth: .infinity)
            }
        }

        if viewModel.apparatus.phase != .swinging && !viewModel.readings.isEmpty && viewModel.result == nil {
            HStack(spacing: 12) {
                Button("Add another trial") { viewModel.addAnotherTrial() }
                    .buttonStyle(.bordered)
                Button("Calculate result") { viewModel.calculateResult() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canCalculate)
            }
        }

        if viewModel.result != nil {
            Button("New task") { viewModel.newTask() }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
        }
    }
}
