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
        apparatus.closeJaws()
    }

    func confirmReading() {
        guard let value = Double(readingInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")) else { return }
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
        let meanCorrect = abs(studentMean - trueMean) <= Self.meanToleranceCm

        var feedback: [String] = []
        feedback.append("Zero error given: \(formatSigned(apparatus.zeroErrorCm)) cm \u{2014} \(apparatus.zeroErrorCm > 0 ? "subtract" : (apparatus.zeroErrorCm < 0 ? "add (subtracting a negative)" : "no correction needed")) from each raw scale reading.")
        feedback.append("\(perTrialCorrectCount) of \(VernierLabState.trialCount) individual readings were within tolerance.")
        feedback.append("Your mean diameter: \(format(studentMean)) cm.")
        feedback.append("Accepted range: \(format(trueMean - Self.meanToleranceCm))\u{2013}\(format(trueMean + Self.meanToleranceCm)) cm.")

        let correct = meanCorrect && perTrialCorrectCount >= 2
        let outcome = LabRunResult(
            correct: correct,
            score: correct ? 100 : (meanCorrect ? 70 : 40),
            feedback: feedback,
            examTip: "Least count = 0.01 cm: main scale mark just before the vernier zero, plus the ONE vernier line that lines up exactly with a main-scale line \u{00D7} 0.01 cm. Always apply the given zero error \u{2014} subtract if positive, add if negative \u{2014} before averaging, and take at least 3 readings along the rod since it may not be perfectly uniform."
        )
        result = outcome
        recorder.record(experimentTitle: SimulationType.vernierCaliper.label, result: outcome)
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

    init(curriculum: Curriculum, repository: AttemptRepository) {
        self.curriculum = curriculum
        _viewModel = State(initialValue: VernierExperimentViewModel(
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum),
            seed: Int.random(in: 0...Int(Int32.max))
        ))
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
            if viewModel.apparatus.jawsClosed {
                let components = viewModel.apparatus.currentObservedComponents
                VernierCaliperCanvasView(
                    mainScaleCm: components.mainScaleCm,
                    vernierCoincidence: components.vernierCoincidence,
                    zeroErrorCm: viewModel.apparatus.zeroErrorCm
                )
                .frame(height: 150)
            } else {
                VernierCaliperCanvasView(mainScaleCm: 8.0, vernierCoincidence: 0, zeroErrorCm: viewModel.apparatus.zeroErrorCm)
                    .frame(height: 150)
                    .opacity(0.55)
                    .overlay(alignment: .top) {
                        Text("Jaws open \u{2014} rod not yet gripped")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
            }

            if !viewModel.apparatus.jawsClosed && viewModel.readings.count < VernierLabState.trialCount {
                DraggableJawSqueezeChip {
                    viewModel.closeJaws()
                }
            }
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var controls: some View {
        if viewModel.apparatus.jawsClosed && viewModel.readings.count < VernierLabState.trialCount {
            HStack {
                TextField("Corrected diameter", text: $viewModel.readingInput)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($fieldFocused)
                Text("cm").foregroundStyle(.secondary)
            }
            Button("Confirm reading") {
                fieldFocused = false
                viewModel.confirmReading()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        } else if viewModel.canCalculate && viewModel.result == nil {
            HStack {
                TextField("Mean diameter", text: $viewModel.meanAnswerInput)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($fieldFocused)
                Text("cm").foregroundStyle(.secondary)
            }
            Button("Calculate result") {
                fieldFocused = false
                viewModel.calculateResult()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }

        if viewModel.result != nil {
            Button("New task") { viewModel.newTask() }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
        }
    }
}

/// A squeeze-shut gesture rather than a positioned drag: dragging past the
/// threshold closes the jaws on the rod, exactly like Density's
/// `DraggableObjectChip` snap-drop — the closing motion itself carries no
/// measurement error in a real caliper (the jaws stop dead against the
/// object), so it's deliberately not a precision drag.
private struct DraggableJawSqueezeChip: View {
    let onClosed: () -> Void
    @State private var dragOffset: CGFloat = 0

    private static let closeThreshold: CGFloat = -70

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.left.and.right")
            Text("Drag to squeeze jaws shut")
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Capsule().fill(Color.accentColor.opacity(0.15)))
        .foregroundStyle(Color.accentColor)
        .offset(x: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in dragOffset = min(0, value.translation.width) }
                .onEnded { value in
                    if value.translation.width <= Self.closeThreshold {
                        onClosed()
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dragOffset = 0
                    }
                }
        )
    }
}
