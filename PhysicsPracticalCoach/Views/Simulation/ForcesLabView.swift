//
//  ForcesLabView.swift
//  PhysicsPracticalCoach
//
//  Balanced & Unbalanced Forces lab experiment, built on the Lab framework
//  (see `PendulumLabView.swift` for the reference template and
//  `LAB_FRAMEWORK.md` for the architecture). A trolley is pulled by a known
//  force (a hanging mass over a pulley) over a fixed, given distance; the
//  student times the run, works out the acceleration from their own timing,
//  and checks it against F = ma \u{2014} filling the syllabus gap for
//  "investigation of the effects of balanced and unbalanced forces".
//

import SwiftUI

// MARK: - 1. Apparatus state

@Observable
final class ForcesLabState {
    /// Hidden true pulling force for this session (N) \u{2014} e.g. from a
    /// hanging mass over a pulley.
    let trueForceN: Double
    /// Given total mass of the trolley system (kg) \u{2014} handed to the
    /// student, matching how real exams give a pre-measured mass rather than
    /// re-testing an already-covered balance-reading skill.
    let givenMassKg: Double
    /// Fixed distance the trolley travels before crossing the light gate /
    /// marked line (m), given in the question.
    let givenDistanceM: Double = 1.0

    private(set) var released = false

    /// True acceleration from Newton's second law, F = ma \u{2192} a = F/m.
    var trueAccelerationMS2: Double { trueForceN / givenMassKg }
    /// True time to cross the distance, starting from rest: d = \u{00BD} a t\u{00B2}.
    var trueTimeS: Double { sqrt(2 * givenDistanceM / trueAccelerationMS2) }

    init(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        trueForceN = ((rng.nextDouble(0.5, 1.5)) * 10).rounded() / 10
        givenMassKg = ((rng.nextDouble(0.4, 1.0)) * 20).rounded() / 20 // nearest 0.05 kg
    }

    func release() {
        released = true
    }

    func reset() {
        released = false
    }
}

// MARK: - 2. Experiment view model

@MainActor
@Observable
final class ForcesExperimentViewModel {
    private(set) var apparatus: ForcesLabState
    private let recorder: LabAttemptRecorder

    var timeInput: String = ""
    var accelerationInput: String = ""
    private(set) var timeConfirmed: Double?
    private(set) var readings: [LabReading] = []
    private(set) var result: LabRunResult?

    private static let timeToleranceS = 0.3 // reaction-time-style tolerance
    private static let accelerationToleranceFraction = 0.12

    init(recorder: LabAttemptRecorder, seed: Int) {
        self.recorder = recorder
        self.apparatus = ForcesLabState(seed: seed)
    }

    var instructionText: String {
        if !apparatus.released {
            return "Tap 'Release trolley' and time how long it takes to cross the \(format(apparatus.givenDistanceM)) m mark."
        }
        if timeConfirmed == nil {
            return "Enter the time you measured on the stopwatch."
        }
        return "Given F = \(format(apparatus.trueForceN)) N and mass = \(format(apparatus.givenMassKg)) kg, calculate the acceleration a, using d = \u{00BD} a t\u{00B2}."
    }

    func release() {
        apparatus.release()
    }

    func confirmTime() {
        guard let value = Double(timeInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")) else { return }
        timeConfirmed = value
        readings.append(LabReading(trialNumber: 1, label: "t (crossing time)", value: value, unit: "s"))
        timeInput = ""
    }

    var canCalculate: Bool { timeConfirmed != nil }

    func calculateResult() {
        guard
            let t = timeConfirmed,
            let studentAcceleration = Double(accelerationInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
        else { return }

        let timeError = abs(t - apparatus.trueTimeS)
        let timeCorrect = timeError <= Self.timeToleranceS

        let accelerationTolerance = apparatus.trueAccelerationMS2 * Self.accelerationToleranceFraction
        let accelerationCorrect = abs(studentAcceleration - apparatus.trueAccelerationMS2) <= accelerationTolerance

        var feedback: [String] = []
        feedback.append("Your time: \(format(t)) s.")
        if !timeCorrect {
            feedback.append("Expected time: around \(format(apparatus.trueTimeS)) s \u{2014} check your stopwatch technique.")
        }
        feedback.append("Your acceleration: \(format(studentAcceleration)) m/s\u{00B2}.")
        feedback.append("Accepted range: \(format(apparatus.trueAccelerationMS2 - accelerationTolerance))\u{2013}\(format(apparatus.trueAccelerationMS2 + accelerationTolerance)) m/s\u{00B2}, from a = F/m = \(format(apparatus.trueForceN))/\(format(apparatus.givenMassKg)).")

        let correct = timeCorrect && accelerationCorrect
        let outcome = LabRunResult(
            correct: correct,
            score: correct ? 100 : (accelerationCorrect ? 70 : 40),
            feedback: feedback,
            examTip: "F = ma, so a = F/m. Since the trolley starts from rest, d = \u{00BD} a t\u{00B2} \u{2192} a = 2d/t\u{00B2}. Always state that the runway was tilted slightly beforehand to compensate for friction \u{2014} otherwise some of F is 'used up' overcoming friction instead of accelerating the trolley."
        )
        result = outcome
        recorder.record(experimentTitle: SimulationType.balancedForces.label, result: outcome)
    }

    func newTask() {
        var rng = SeededRandomNumberGenerator(seed: Int.random(in: 0...Int(Int32.max)))
        apparatus = ForcesLabState(seed: rng.nextInt(0, Int(Int32.max)))
        readings = []
        result = nil
        timeInput = ""
        accelerationInput = ""
        timeConfirmed = nil
    }

    private func format(_ value: Double) -> String { String(format: "%.2f", value) }
}

// MARK: - View

struct ForcesLabView: View {
    let curriculum: Curriculum
    @State private var viewModel: ForcesExperimentViewModel
    @State private var trolleyProgress: Double = 0
    @FocusState private var focusedField: Field?

    private enum Field { case time, acceleration }

    init(curriculum: Curriculum, repository: AttemptRepository) {
        self.curriculum = curriculum
        _viewModel = State(initialValue: ForcesExperimentViewModel(
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum),
            seed: Int.random(in: 0...Int(Int32.max))
        ))
    }

    var body: some View {
        LabScaffoldView(
            title: "Forces Lab",
            instructionText: viewModel.instructionText,
            apparatusHeight: 260,
            readings: viewModel.readings,
            result: viewModel.result,
            apparatus: { apparatusArea },
            controls: { controls }
        )
    }

    private var apparatusArea: some View {
        GeometryReader { geo in
            let trackY = geo.size.height * 0.55
            let trackLeft: CGFloat = 24
            let trackRight = geo.size.width - 60
            let trolleyX = trackLeft + CGFloat(trolleyProgress) * (trackRight - trackLeft)

            ZStack {
                Canvas { context, _ in
                    var track = Path()
                    track.move(to: CGPoint(x: trackLeft, y: trackY))
                    track.addLine(to: CGPoint(x: trackRight, y: trackY))
                    context.stroke(track, with: .color(.primary.opacity(0.4)), lineWidth: 2)

                    // Pulley at the right edge, with the hanging force below it.
                    let pulleyCenter = CGPoint(x: trackRight + 20, y: trackY - 20)
                    context.stroke(Path(ellipseIn: CGRect(x: pulleyCenter.x - 10, y: pulleyCenter.y - 10, width: 20, height: 20)), with: .color(.primary.opacity(0.5)), lineWidth: 2)
                    var thread = Path()
                    thread.move(to: CGPoint(x: pulleyCenter.x, y: pulleyCenter.y + 10))
                    thread.addLine(to: CGPoint(x: pulleyCenter.x, y: pulleyCenter.y + 44))
                    context.stroke(thread, with: .color(.primary.opacity(0.5)), lineWidth: 1.5)
                    LabCanvasHelpers.drawWeight(context: context, center: CGPoint(x: pulleyCenter.x, y: pulleyCenter.y + 54), radiusPx: 12, color: Color(hex: "#D98B36"))
                    LabCanvasHelpers.drawLabel(
                        context: context, text: "F = \(String(format: "%.1f", viewModel.apparatus.trueForceN)) N",
                        at: CGPoint(x: pulleyCenter.x, y: pulleyCenter.y + 76), size: 11
                    )

                    // Marked crossing line.
                    var mark = Path()
                    mark.move(to: CGPoint(x: trackRight, y: trackY - 16))
                    mark.addLine(to: CGPoint(x: trackRight, y: trackY + 6))
                    context.stroke(mark, with: .color(.red.opacity(0.7)), lineWidth: 2)
                    LabCanvasHelpers.drawLabel(
                        context: context, text: "\(String(format: "%.1f", viewModel.apparatus.givenDistanceM)) m mark",
                        at: CGPoint(x: trackRight, y: trackY - 26), size: 11
                    )

                    LabCanvasHelpers.drawLabel(
                        context: context, text: "mass = \(String(format: "%.2f", viewModel.apparatus.givenMassKg)) kg",
                        at: CGPoint(x: trackLeft + 50, y: trackY + 26), size: 11
                    )
                }

                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(hex: "#2980B9"))
                    .frame(width: 30, height: 20)
                    .position(x: trolleyX, y: trackY - 12)
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        if !viewModel.apparatus.released {
            Button("Release trolley") {
                viewModel.release()
                withAnimation(.linear(duration: viewModel.apparatus.trueTimeS)) {
                    trolleyProgress = 1
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        } else if viewModel.timeConfirmed == nil {
            HStack {
                TextField("Time measured", text: $viewModel.timeInput)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .time)
                Text("s").foregroundStyle(.secondary)
            }
            Button("Confirm time") {
                focusedField = nil
                viewModel.confirmTime()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        } else if viewModel.canCalculate && viewModel.result == nil {
            HStack {
                TextField("Your acceleration answer", text: $viewModel.accelerationInput)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .acceleration)
                Text("m/s\u{00B2}").foregroundStyle(.secondary)
            }
            Button("Calculate result") {
                focusedField = nil
                viewModel.calculateResult()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }

        if viewModel.result != nil {
            Button("New task") {
                viewModel.newTask()
                trolleyProgress = 0
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
        }
    }
}
