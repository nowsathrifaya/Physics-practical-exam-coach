//
//  VernierCaliperLabView.swift
//  PhysicsPracticalCoach
//
//  Vernier caliper lab experiment, built on the Lab framework (see
//  `PendulumLabView.swift` for the reference template and
//  `LAB_FRAMEWORK.md` for the architecture). Converted next among the
//  remaining `GenericSimulationView` placeholders per the curriculum
//  priority order noted there.
//
//  Ninth drag mechanic, and the first that isn't really about the drag at
//  all: closing the jaws is a simple squeeze-shut gesture (reusing the
//  Density/Spring "drag past a threshold to snap" pattern) because in a
//  real caliper measurement the physical act of closing the jaws is not a
//  meaningful source of error — the jaws stop dead against the object
//  regardless of how carefully the student drags. The actual skill under
//  test, exactly like `AnsweringTechniquesView.ans_vernier`, is reading the
//  main scale + the one coinciding vernier line afterwards and correctly
//  applying a *given* zero error — the same convention `ApparatusTrainer`
//  already uses (zero error is shown on the instrument, not something the
//  student has to independently discover).
//
//  Reuses `VernierCaliperCanvasView` from `ApparatusVisuals.swift` wholesale
//  for the reading diagram — first Lab experiment to reuse another
//  feature's apparatus rendering rather than drawing its own, the same
//  "don't rebuild what already exists" principle Potentiometer/Ohm's Law
//  applied to `ScatterPlotCanvasView`.
//
//  The rod is measured at three points along its length and averaged — the
//  standard exam technique for a possibly-non-uniform rod/wire (each true
//  diameter is close to, but not exactly, the session mean) — giving a
//  genuine reason for >= 3 trials beyond just "the framework expects it."
//

import SwiftUI
import UIKit

// MARK: - 1. Apparatus state

@Observable
final class VernierLabState {
    /// Number of measurement points along the rod.
    static let trialCount = 3
    static let trialLabels = ["Point 1 (near left end)", "Point 2 (middle)", "Point 3 (near right end)"]

    /// Hidden true diameter at each of the three points (cm), stored as
    /// hundredths of a cm (the instrument's own resolution) so every
    /// downstream calculation stays exact integer arithmetic until the
    /// final display conversion — no floating-point drift between the
    /// generated value and what the vernier scale can actually show.
    private(set) var trueDiameterHundredths: [Int] = []
    /// Given zero error (hundredths of a cm) — shown directly on the
    /// instrument, same convention as `ApparatusTrainer.vernierQuestion`.
    let zeroErrorHundredths: Int

    /// Which trial (0-based) is currently being measured.
    private(set) var currentTrialIndex = 0
    /// Whether the jaws are currently closed on the rod at the current
    /// trial's point (reveals the scale) vs. open (nothing to read yet).
    private(set) var jawsClosed = false

    var zeroErrorCm: Double { Double(zeroErrorHundredths) / 100.0 }

    init(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        let meanHundredths = rng.nextInt(100, 550) // 1.00-5.50 cm
        trueDiameterHundredths = (0..<Self.trialCount).map { _ in
            meanHundredths + rng.nextInt(-2, 3) // +/- up to 0.02 cm non-uniformity
        }
        zeroErrorHundredths = rng.nextInt(-2, 3) // matches ApparatusTrainer's vernier range
    }

    /// The raw (uncorrected) reading the scale itself shows for the current
    /// trial — main-scale mark + vernier coincidence, exactly the shape
    /// `ApparatusTrainer` uses, but derived here from the hidden true
    /// diameter plus the given zero error instead of being generated
    /// directly, since the object (not a random scale position) determines
    /// what's shown once the jaws are closed on it.
    var currentObservedComponents: (mainScaleCm: Double, vernierCoincidence: Int) {
        let observedHundredths = trueDiameterHundredths[currentTrialIndex] + zeroErrorHundredths
        let mainScaleTenths = observedHundredths / 10
        let coincidence = observedHundredths % 10
        return (Double(mainScaleTenths) / 10.0, coincidence)
    }

    var trueDiameterCmForCurrentTrial: Double { Double(trueDiameterHundredths[currentTrialIndex]) / 100.0 }

    var trueMeanDiameterCm: Double {
        Double(trueDiameterHundredths.reduce(0, +)) / Double(trueDiameterHundredths.count) / 100.0
    }

    var isLastTrial: Bool { currentTrialIndex == Self.trialCount - 1 }

    func closeJaws() {
        jawsClosed = true
    }

    func openJawsForNextTrial() {
        guard currentTrialIndex < Self.trialCount - 1 else { return }
        currentTrialIndex += 1
        jawsClosed = false
    }
}

// MARK: - 2. Experiment view model

@MainActor
@Observable
final class VernierExperimentViewModel {
    private(set) var apparatus: VernierLabState
    private let recorder: LabAttemptRecorder

    var readingInput: String = ""
    var meanAnswerInput: String = ""
    private(set) var readings: [LabReading] = []
    private(set) var result: LabRunResult?

    private static let perTrialToleranceCm = 0.02
    private static let meanToleranceCm = 0.02

    /// Optional hook for the Virtual Lab Experiment workflow wrapper — fires
    /// once after `calculateResult()` sets `result`. Nil by default, so
    /// existing standalone `VernierCaliperLabView` usage behaves exactly as before;
    /// only the new wrapping workflow sets this.
    var onFinished: ((LabRunResult) -> Void)?

    init(recorder: LabAttemptRecorder, seed: Int) {
        self.recorder = recorder
        self.apparatus = VernierLabState(seed: seed)
    }

    var instructionText: String {
        if result != nil {
            return "Session complete. Start a new task to measure a different rod."
        }
        if readings.count >= VernierLabState.trialCount {
            return "Correct each reading for the given zero error, average your three diameters, and enter the mean below."
        }
        if !apparatus.jawsClosed {
            return "Squeeze the jaws closed on the rod at \(VernierLabState.trialLabels[apparatus.currentTrialIndex])."
        }
        return "Read the main scale, find the coinciding vernier line, and enter your zero-error-corrected diameter."
    }

    func closeJaws() {
        SoundManager.shared.play(.measurement)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        apparatus.closeJaws()
    }

    func confirmReading() {
        guard let value = Double(readingInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")) else { return }
        SoundManager.shared.play(.measurement)
        readings.append(LabReading(
            trialNumber: apparatus.currentTrialIndex + 1,
            label: "d (\(VernierLabState.trialLabels[apparatus.currentTrialIndex]))",
            value: value, unit: "cm"
        ))
        readingInput = ""
        if apparatus.isLastTrial {
            // Stay closed; the data table now shows all 3 and the mean-answer field appears.
        } else {
            apparatus.openJawsForNextTrial()
        }
    }

    var canCalculate: Bool { readings.count >= VernierLabState.trialCount }

    func calculateResult() {
        guard
            canCalculate,
            let studentMean = Double(meanAnswerInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
        else { return }

        let trueDiameters = apparatus.trueDiameterHundredths.map { Double($0) / 100.0 }
        let perTrialCorrectCount = zip(readings, trueDiameters).filter { abs($0.value - $1) <= Self.perTrialToleranceCm }.count

        let trueMean = apparatus.trueMeanDiameterCm
        let meanError = abs(studentMean - trueMean)
        let meanCorrect = meanError <= Self.meanToleranceCm

        // Detailed breakdown instead of a single coarse 100/70/40 score —
        // each dimension is graded and shown separately, so a student can
        // see exactly *why* they lost marks rather than one flat number.
        let measurementAccuracyScore = Int((Double(perTrialCorrectCount) / Double(VernierLabState.trialCount)) * 40)

        let meanAccuracyScore: Int = {
            if meanError <= Self.meanToleranceCm { return 35 }
            if meanError <= Self.meanToleranceCm * 2 { return 18 }
            return 0
        }()

        // Zero error correction can't be graded completely independently
        // of the readings themselves (the app only sees the student's
        // final, already-corrected value) — but a session with no zero
        // error needs no correction at all, and getting 2+ individual
        // readings right is only possible if the correction direction was
        // applied correctly, so it's a reasonable proxy.
        let zeroErrorScore: Int = {
            if apparatus.zeroErrorHundredths == 0 { return 15 }
            if perTrialCorrectCount >= 2 { return 15 }
            if perTrialCorrectCount == 1 { return 7 }
            return 0
        }()

        // Precision: did every reading actually use the vernier's 2 d.p.
        // resolution, e.g. "2.34" not "2.3"?
        let usedTwoDecimalPlaces = readings.allSatisfy { reading in
            abs(reading.value * 100 - (reading.value * 100).rounded()) < 0.001
        }
        let precisionScore = usedTwoDecimalPlaces ? 10 : 0

        let totalScore = measurementAccuracyScore + meanAccuracyScore + zeroErrorScore + precisionScore

        var feedback: [String] = []
        feedback.append("Zero error given: \(formatSigned(apparatus.zeroErrorCm)) cm \u{2014} \(apparatus.zeroErrorCm > 0 ? "subtract" : (apparatus.zeroErrorCm < 0 ? "add (subtracting a negative)" : "no correction needed")) from each raw scale reading.")
        feedback.append("Your mean diameter: \(format(studentMean)) cm.")
        feedback.append("Accepted range: \(format(trueMean - Self.meanToleranceCm))\u{2013}\(format(trueMean + Self.meanToleranceCm)) cm.")
        feedback.append("\u{2014}\u{2014}\u{2014} Score breakdown \u{2014}\u{2014}\u{2014}")
        feedback.append("Measurement accuracy: \(measurementAccuracyScore)/40 (\(perTrialCorrectCount) of \(VernierLabState.trialCount) readings within tolerance)")
        feedback.append("Mean accuracy: \(meanAccuracyScore)/35")
        feedback.append("Zero error correction: \(zeroErrorScore)/15")
        feedback.append("Precision (2 d.p.): \(precisionScore)/10")

        let correct = meanCorrect && perTrialCorrectCount >= 2
        let outcome = LabRunResult(
            correct: correct,
            score: totalScore,
            feedback: feedback,
            examTip: "Least count = 0.01 cm: main scale mark just before the vernier zero, plus the ONE vernier line that lines up exactly with a main-scale line \u{00D7} 0.01 cm. Always apply the given zero error \u{2014} subtract if positive, add if negative \u{2014} before averaging, and take at least 3 readings along the rod since it may not be perfectly uniform."
        )
        result = outcome
        recorder.record(experimentTitle: SimulationType.vernierCaliper.label, result: outcome)
        onFinished?(outcome)
    }

    func newTask() {
        var rng = SeededRandomNumberGenerator(seed: Int.random(in: 0...Int(Int32.max)))
        apparatus = VernierLabState(seed: rng.nextInt(0, Int(Int32.max)))
        readings = []
        result = nil
        readingInput = ""
        meanAnswerInput = ""
    }

    private func format(_ value: Double) -> String { String(format: "%.2f", value) }
    private func formatSigned(_ value: Double) -> String { (value >= 0 ? "+" : "") + String(format: "%.2f", value) }
}

// MARK: - View

struct VernierCaliperLabView: View {
    let curriculum: Curriculum
    @State private var viewModel: VernierExperimentViewModel
    @FocusState private var fieldFocused: Bool

    init(curriculum: Curriculum, repository: AttemptRepository, onFinished: ((LabRunResult) -> Void)? = nil) {
        self.curriculum = curriculum
        let model = VernierExperimentViewModel(
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum),
            seed: Int.random(in: 0...Int(Int32.max))
        )
        model.onFinished = onFinished
        _viewModel = State(initialValue: model)
    }

    var body: some View {
        LabScaffoldView(
            title: "Vernier Caliper Lab",
            instructionText: viewModel.instructionText,
            apparatusHeight: 260,
            readings: viewModel.readings,
            result: viewModel.result,
            apparatus: { apparatusArea },
            controls: { controls }
        )
    }

    private var apparatusArea: some View {
        VStack(spacing: 12) {
            Group {
                if viewModel.apparatus.jawsClosed {
                    let components = viewModel.apparatus.currentObservedComponents
                    VernierCaliperCanvasView(
                        mainScaleCm: components.mainScaleCm,
                        vernierCoincidence: components.vernierCoincidence,
                        zeroErrorCm: viewModel.apparatus.zeroErrorCm
                    )
                    .frame(height: 150)
                    .accessibilityLabel("Vernier caliper, jaws closed on the rod")
                    .accessibilityHint("Read the main scale and the coinciding vernier line to determine the diameter.")
                } else {
                    VernierCaliperCanvasView(mainScaleCm: 8.0, vernierCoincidence: 0, zeroErrorCm: viewModel.apparatus.zeroErrorCm)
                        .frame(height: 150)
                        .opacity(0.55)
                        .overlay(alignment: .top) {
                            Text("Jaws open \u{2014} rod not yet gripped")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("Vernier caliper, jaws open, rod not yet gripped")
                }
            }
            // Real spring motion for the open-to-closed transition, instead
            // of the scale diagram just swapping instantly.
            .transition(.scale(scale: 0.94).combined(with: .opacity))
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.apparatus.jawsClosed)

            if !viewModel.apparatus.jawsClosed && viewModel.readings.count < VernierLabState.trialCount {
                DraggableJawSqueezeChip {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        viewModel.closeJaws()
                    }
                }
                .accessibilityLabel("Squeeze jaws shut")
                .accessibilityHint("Closes the caliper's jaws on the rod so you can read the scale.")
            }

            if !viewModel.readings.isEmpty {
                LiveAverageCard(readings: viewModel.readings)
            }
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var controls: some View {
        TrialProgressView(completed: viewModel.readings.count, target: VernierLabState.trialCount)
            .accessibilityLabel("Trial \(min(viewModel.readings.count + 1, VernierLabState.trialCount)) of \(VernierLabState.trialCount)")

        if viewModel.apparatus.jawsClosed && viewModel.readings.count < VernierLabState.trialCount {
            HStack {
                TextField("Corrected diameter", text: $viewModel.readingInput)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($fieldFocused)
                    .accessibilityLabel("Corrected diameter reading, in centimetres")
                Text("cm").foregroundStyle(.secondary)
            }
            Button("Confirm reading") {
                fieldFocused = false
                viewModel.confirmReading()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Confirm Vernier Reading")
        } else if viewModel.canCalculate && viewModel.result == nil {
            HStack {
                TextField("Mean diameter", text: $viewModel.meanAnswerInput)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($fieldFocused)
                    .accessibilityLabel("Mean diameter, in centimetres")
                Text("cm").foregroundStyle(.secondary)
            }
            Button("Calculate result") {
                fieldFocused = false
                viewModel.calculateResult()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Calculate Result")
        }

        if viewModel.result != nil {
            Button("New task") { viewModel.newTask() }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Start New Task")
        }
    }
}

/// Live running average of the readings entered so far — the student
/// still types the mean themselves, but seeing this updates as they go
/// helps them catch an arithmetic slip before submitting, the same way a
/// careful student would jot a running check on paper.
private struct LiveAverageCard: View {
    let readings: [LabReading]

    private var average: Double { readings.map(\.value).reduce(0, +) / Double(readings.count) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(readings.enumerated()), id: \.offset) { index, reading in
                Text("Reading \(index + 1): \(String(format: "%.2f", reading.value)) cm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Current average: \(String(format: "%.2f", average)) cm")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// A squeeze-shut gesture rather than a positioned drag: dragging past the
/// threshold closes the jaws on the rod, exactly like Density's
/// `DraggableObjectChip` snap-drop — the closing motion itself carries no
/// measurement error in a real caliper (the jaws stop dead against the
/// object), so it's deliberately not a precision drag.
/// A single tap closes the jaws — deliberately not a drag gesture. In a
/// real caliper, the jaws stop dead against the object regardless of how
/// carefully the student squeezes, so the closing motion itself carries no
/// measurement error worth simulating, and a drag-threshold gesture here
/// only added a way for this to feel unresponsive for no pedagogical gain.
private struct DraggableJawSqueezeChip: View {
    let onClosed: () -> Void

    var body: some View {
        Button(action: onClosed) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.left.and.right")
                Text("Tap to squeeze jaws shut")
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.accentColor.opacity(0.15)))
            .foregroundStyle(Color.accentColor)
        }
        .buttonStyle(.plain)
    }
}
