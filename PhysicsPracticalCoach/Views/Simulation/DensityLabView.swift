//
//  DensityLabView.swift
//  PhysicsPracticalCoach
//
//  Density-by-displacement lab experiment, built on the Lab framework (see
//  `PendulumLabView.swift` for the reference template and
//  `LAB_FRAMEWORK.md` for the architecture). The student drags a solid
//  object down into the measuring cylinder — a third distinct drag
//  mechanic alongside Pendulum's angle-drag and Spring's drag-upward —
//  reads the water level before and after (typed reading + tolerance
//  grading, matching the Apparatus Practice measuring-cylinder convention),
//  and calculates density from their own two readings plus the given mass.
//

import SwiftUI

// MARK: - 1. Apparatus state

@Observable
final class DensityLabState {
    /// Hidden true density for this session (g/cm3).
    let trueDensityGPerCm3: Double
    /// Given mass, as if pre-measured on a balance (g) — matches real exams,
    /// which typically hand the student the mass rather than making them
    /// re-derive an already-covered balance-reading skill.
    let givenMassG: Double
    /// Initial water level in the cylinder (cm3).
    let initialLevelCm3: Double

    private(set) var objectDropped = false

    /// True volume of the object, derived from the given mass and hidden
    /// density (cm3).
    var trueVolumeCm3: Double { givenMassG / trueDensityGPerCm3 }

    /// True final water level once the object is submerged (cm3).
    var trueFinalLevelCm3: Double { initialLevelCm3 + trueVolumeCm3 }

    init(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        trueDensityGPerCm3 = ((rng.nextDouble(1.5, 9.5)) * 100).rounded() / 100
        givenMassG = (rng.nextDouble(20, 80)).rounded()
        initialLevelCm3 = (rng.nextDouble(30, 60) * 2).rounded() / 2 // nearest 0.5, matches cylinder's minor division
    }

    func dropObject() {
        objectDropped = true
    }

    func reset() {
        objectDropped = false
    }
}

// MARK: - 2. Experiment view model

@MainActor
@Observable
final class DensityExperimentViewModel {
    private(set) var apparatus: DensityLabState
    private let recorder: LabAttemptRecorder

    var initialReadingInput: String = ""
    var finalReadingInput: String = ""
    var densityAnswerInput: String = ""
    private(set) var initialReadingConfirmed: Double?
    private(set) var readings: [LabReading] = []
    private(set) var result: LabRunResult?

    private static let volumeTolerance = 0.5 // cm3, matches ApparatusTrainer's measuring cylinder convention
    private static let densityToleranceFraction = 0.12

    init(recorder: LabAttemptRecorder, seed: Int) {
        self.recorder = recorder
        self.apparatus = DensityLabState(seed: seed)
    }

    var instructionText: String {
        if initialReadingConfirmed == nil {
            return "Read the initial water level and enter it below."
        }
        if !apparatus.objectDropped {
            return "Drag the solid object down into the cylinder."
        }
        if readings.count < 2 {
            return "Read the new water level and enter it below."
        }
        return "Given the mass (\(Int(apparatus.givenMassG)) g) and your two readings, calculate the density."
    }

    func confirmInitialReading() {
        guard let value = Double(initialReadingInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")) else { return }
        initialReadingConfirmed = value
        readings.append(LabReading(trialNumber: 1, label: "V\u{2081} (before)", value: value, unit: "cm\u{00B3}"))
        initialReadingInput = ""
    }

    func dropObject() {
        apparatus.dropObject()
    }

    func confirmFinalReading() {
        guard let value = Double(finalReadingInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")) else { return }
        readings.append(LabReading(trialNumber: 2, label: "V\u{2082} (after)", value: value, unit: "cm\u{00B3}"))
        finalReadingInput = ""
    }

    var canCalculate: Bool { readings.count >= 2 }

    func calculateResult() {
        guard
            canCalculate,
            let v1 = readings.first(where: { $0.trialNumber == 1 })?.value,
            let v2 = readings.first(where: { $0.trialNumber == 2 })?.value,
            let studentDensity = Double(densityAnswerInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
        else { return }

        let studentVolume = v2 - v1
        let volumeError = abs(studentVolume - apparatus.trueVolumeCm3)
        let volumeCorrect = volumeError <= Self.volumeTolerance

        let densityTolerance = apparatus.trueDensityGPerCm3 * Self.densityToleranceFraction
        let densityCorrect = abs(studentDensity - apparatus.trueDensityGPerCm3) <= densityTolerance

        var feedback: [String] = []
        feedback.append("Your displaced volume: \(format(studentVolume)) cm\u{00B3} (V\u{2082} \u{2212} V\u{2081}).")
        if !volumeCorrect {
            feedback.append("Expected displaced volume: \(format(apparatus.trueVolumeCm3)) cm\u{00B3} \u{2014} check your cylinder readings.")
        }
        feedback.append("Your density: \(format(studentDensity)) g/cm\u{00B3}.")
        feedback.append("Accepted range: \(format(apparatus.trueDensityGPerCm3 - densityTolerance))\u{2013}\(format(apparatus.trueDensityGPerCm3 + densityTolerance)) g/cm\u{00B3}.")

        let correct = volumeCorrect && densityCorrect
        let outcome = LabRunResult(
            correct: correct,
            score: correct ? 100 : (densityCorrect ? 70 : 40),
            feedback: feedback,
            examTip: "Density = mass / (V\u{2082} \u{2212} V\u{2081}). Always read the bottom of the meniscus at eye level for both volume readings \u{2014} that's where most marks are lost."
        )
        result = outcome
        recorder.record(experimentTitle: SimulationType.densityDisplacement.label, result: outcome)
    }

    func newTask() {
        var rng = SeededRandomNumberGenerator(seed: Int.random(in: 0...Int(Int32.max)))
        apparatus = DensityLabState(seed: rng.nextInt(0, Int(Int32.max)))
        readings = []
        result = nil
        initialReadingInput = ""
        finalReadingInput = ""
        densityAnswerInput = ""
        initialReadingConfirmed = nil
    }

    private func format(_ value: Double) -> String { String(format: "%.2f", value) }
}

// MARK: - View

struct DensityLabView: View {
    let curriculum: Curriculum
    @State private var viewModel: DensityExperimentViewModel
    @FocusState private var focusedField: Field?

    private enum Field { case initial, final, density }

    init(curriculum: Curriculum, repository: AttemptRepository) {
        self.curriculum = curriculum
        _viewModel = State(initialValue: DensityExperimentViewModel(
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum),
            seed: Int.random(in: 0...Int(Int32.max))
        ))
    }

    var body: some View {
        LabScaffoldView(
            title: "Density Lab",
            instructionText: viewModel.instructionText,
            apparatusHeight: 340,
            readings: viewModel.readings,
            result: viewModel.result,
            apparatus: { apparatusArea },
            controls: { controls }
        )
    }

    private var apparatusArea: some View {
        GeometryReader { geo in
            let cylinderWidth: CGFloat = 90
            let cylinderRect = CGRect(
                x: geo.size.width / 2 - cylinderWidth / 2, y: 16,
                width: cylinderWidth, height: geo.size.height - 90
            )
            let maxCm3: Double = 100
            let levelCm3 = viewModel.apparatus.objectDropped ? viewModel.apparatus.trueFinalLevelCm3 : viewModel.apparatus.initialLevelCm3
            let waterFraction = min(max(levelCm3 / maxCm3, 0), 1)
            let waterHeight = CGFloat(waterFraction) * cylinderRect.height
            let waterTop = cylinderRect.maxY - waterHeight

            ZStack {
                Canvas { context, _ in
                    context.stroke(RoundedRectangle(cornerRadius: 6).path(in: cylinderRect), with: .color(.primary.opacity(0.4)), lineWidth: 2)
                    let waterRect = CGRect(x: cylinderRect.minX, y: waterTop, width: cylinderRect.width, height: cylinderRect.maxY - waterTop)
                    context.fill(RoundedRectangle(cornerRadius: 4).path(in: waterRect), with: .color(.blue.opacity(0.4)))

                    LabCanvasHelpers.drawVerticalRuler(
                        context: context, originX: cylinderRect.minX - 8, topY: cylinderRect.minY,
                        heightPx: cylinderRect.height, maxValue: maxCm3, minorStep: 5
                    )

                    LabCanvasHelpers.drawLabel(
                        context: context, text: "\(Int(viewModel.apparatus.givenMassG)) g given",
                        at: CGPoint(x: cylinderRect.midX, y: cylinderRect.minY - 12), size: 12
                    )
                }

                if !viewModel.apparatus.objectDropped {
                    DraggableObjectChip {
                        viewModel.dropObject()
                    }
                    .position(x: cylinderRect.maxX + 40, y: cylinderRect.midY)
                }
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        if viewModel.initialReadingConfirmed == nil {
            HStack {
                TextField("Initial level", text: $viewModel.initialReadingInput)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .initial)
                Text("cm\u{00B3}").foregroundStyle(.secondary)
            }
            Button("Confirm initial reading") {
                focusedField = nil
                viewModel.confirmInitialReading()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        } else if viewModel.apparatus.objectDropped && viewModel.readings.count < 2 {
            HStack {
                TextField("Final level", text: $viewModel.finalReadingInput)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .final)
                Text("cm\u{00B3}").foregroundStyle(.secondary)
            }
            Button("Confirm final reading") {
                focusedField = nil
                viewModel.confirmFinalReading()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        } else if viewModel.canCalculate && viewModel.result == nil {
            HStack {
                TextField("Your density answer", text: $viewModel.densityAnswerInput)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .density)
                Text("g/cm\u{00B3}").foregroundStyle(.secondary)
            }
            Button("Calculate result") {
                focusedField = nil
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

/// The solid object the student drags into the cylinder — a simple drag-down
/// gesture judged by distance, same robust "threshold, not pixel-perfect
/// hit-test" approach as Spring's `DraggableMassChip`.
private struct DraggableObjectChip: View {
    let onDropped: () -> Void
    @State private var dragOffset: CGSize = .zero

    private static let dropThreshold: CGFloat = -60 // dragged left, toward the cylinder

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color(hex: "#8B5E3C"))
            .frame(width: 34, height: 34)
            .offset(dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in dragOffset = value.translation }
                    .onEnded { value in
                        if value.translation.width <= Self.dropThreshold {
                            onDropped()
                        }
                        withAnimation(.spring(response: 0.3)) {
                            dragOffset = .zero
                        }
                    }
            )
    }
}
