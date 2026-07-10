//
//  MomentsLabView.swift
//  PhysicsPracticalCoach
//
//  Principle of Moments lab experiment, built on the Lab framework (see
//  `PendulumLabView.swift` for the reference template and
//  `LAB_FRAMEWORK.md` for the architecture). A fourth distinct drag
//  mechanic: unlike Pendulum/Spring/Density's discrete phases, this one is
//  continuous — the beam tilts live as the student drags a weight along it,
//  exactly like a real seesaw, and the student must find the balance point
//  by eye before reading its position off the ruler themselves.
//

import SwiftUI

// MARK: - 1. Apparatus state

@Observable
final class MomentsLabState {
    /// Fixed known weight on the left side for the current trial (N).
    private(set) var leftForceN: Double
    /// Fixed known distance of the left weight from the pivot (m).
    private(set) var leftDistanceM: Double
    /// Half-length of the beam either side of the pivot (m) — the right
    /// weight can be dragged anywhere from the pivot out to this distance.
    static let halfBeamLengthM = 0.45

    /// The right-side weight's force, chosen by the student (N).
    var rightForceN: Double = 1.0
    /// The right-side weight's current distance from the pivot as the
    /// student drags it (m) — live, updates continuously during the drag.
    var rightDistanceM: Double = 0.25

    init(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        leftForceN = Double(rng.nextInt(1, 4)) // 1, 2, or 3 N
        leftDistanceM = ((rng.nextDouble(0.10, 0.40)) * 100).rounded() / 100
    }

    private var leftMomentNm: Double { leftForceN * leftDistanceM }
    private var rightMomentNm: Double { rightForceN * rightDistanceM }

    /// Net moment (left \u2212 right) driving the live tilt — positive tips left down.
    var netMomentNm: Double { leftMomentNm - rightMomentNm }

    /// Live beam tilt in degrees, purely visual, clamped so the drawing
    /// never goes fully vertical even at extreme imbalance.
    var tiltDeg: Double {
        max(min(netMomentNm * 15.0, 22), -22)
    }
}

// MARK: - 2. Experiment view model

@MainActor
@Observable
final class MomentsExperimentViewModel {
    private(set) var apparatus: MomentsLabState
    private let recorder: LabAttemptRecorder

    let availableRightForcesN: [Double] = [1, 2, 3]
    private(set) var readings: [LabReading] = []
    private(set) var result: LabRunResult?
    var pendingReadingInput: String = ""
    private(set) var awaitingReading = false
    private var dropDistancesM: [Double] = []

    private static let distanceReadingTolerance = 0.01 // m, matches a cm-scale ruler read to nearest small division
    private static let momentDifferenceTolerance = 0.15 // fraction, generous for a by-eye balance judgement

    init(recorder: LabAttemptRecorder, seed: Int) {
        self.recorder = recorder
        self.apparatus = MomentsLabState(seed: seed)
    }

    var instructionText: String {
        if awaitingReading {
            return "Read the distance d\u{2082} off the ruler where you released the weight, and enter it below."
        }
        return "Choose a weight, then drag it along the right side until the beam looks level."
    }

    func selectRightForce(_ forceN: Double) {
        apparatus.rightForceN = forceN
    }

    private var pendingDropDistanceM: Double = 0

    func endDrag() {
        pendingDropDistanceM = apparatus.rightDistanceM
        awaitingReading = true
    }

    func submitReading() {
        guard let value = Double(pendingReadingInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")) else { return }
        dropDistancesM.append(pendingDropDistanceM)
        readings.append(LabReading(
            trialNumber: readings.count + 1,
            label: "F\u{2082} at d\u{2082}", value: apparatus.rightForceN, unit: "N",
            derivedLabel: "d\u{2082} (read)", derivedValue: value, derivedUnit: "m"
        ))
        pendingReadingInput = ""
        awaitingReading = false
    }

    var canCalculate: Bool { readings.count >= 2 }

    func calculateResult() {
        guard canCalculate else { return }
        // All `readings` in one session share the same left-side setup
        // (left force/distance only change on `newTask()`), so a single
        // left moment applies across every trial being graded here — the
        // intended flow is one left setup, several balance attempts.
        let leftMomentNm = leftMomentAtRecordingTime
        var withinBalanceTolerance = 0
        var withinReadingTolerance = 0
        var lines: [String] = []

        for (index, reading) in readings.enumerated() {
            guard let d2 = reading.derivedValue else { continue }
            let rightMoment = reading.value * d2
            let percentDiff = abs(rightMoment - leftMomentNm) / max(leftMomentNm, 0.01)
            let balanced = percentDiff <= Self.momentDifferenceTolerance
            if balanced { withinBalanceTolerance += 1 }

            var line = "Trial \(reading.trialNumber): F\u{2082}d\u{2082} = \(format(rightMoment)) Nm vs F\u{2081}d\u{2081} = \(format(leftMomentNm)) Nm (\(balanced ? "balanced" : "not balanced"))."
            if index < dropDistancesM.count {
                let actualDrop = dropDistancesM[index]
                let readAccurately = abs(d2 - actualDrop) <= Self.distanceReadingTolerance
                if readAccurately { withinReadingTolerance += 1 }
                if !readAccurately {
                    line += " Your reading (\(format(d2)) m) was off from where you actually placed it (\(format(actualDrop)) m) \u{2014} check your ruler alignment."
                }
            }
            lines.append(line)
        }

        let correct = withinBalanceTolerance == readings.count
        var feedback = lines
        feedback.append("\(withinBalanceTolerance)/\(readings.count) trials were within tolerance of a true balance.")
        feedback.append("\(withinReadingTolerance)/\(readings.count) readings matched where you actually placed the weight.")
        if readings.count < 3 {
            feedback.append("Real exams expect at least 3 balance attempts \u{2014} try another trial next time.")
        }

        let outcome = LabRunResult(
            correct: correct,
            score: correct ? 100 : (withinBalanceTolerance > 0 ? 60 : 30),
            feedback: feedback,
            examTip: "A beam that won't balance even with no weights added isn't uniform \u2014 its centre of gravity isn't at the pivot. Always find a bare beam's natural balance point first, or account for its own weight as an extra moment."
        )
        result = outcome
        recorder.record(experimentTitle: SimulationType.moments.label, result: outcome)
    }

    /// The left-side moment in effect for the trials recorded so far —
    /// captured from the apparatus's current left setup, valid for the
    /// single-setup-per-session flow described above (left force/distance
    /// only change via `newTask()`, not between readings).
    private var leftMomentAtRecordingTime: Double {
        apparatus.leftForceN * apparatus.leftDistanceM
    }

    var givenLeftDescription: String {
        "Given: F\u{2081} = \(format(apparatus.leftForceN)) N at d\u{2081} = \(format(apparatus.leftDistanceM)) m from the pivot."
    }

    func newTask() {
        var rng = SeededRandomNumberGenerator(seed: Int.random(in: 0...Int(Int32.max)))
        apparatus = MomentsLabState(seed: rng.nextInt(0, Int(Int32.max)))
        readings = []
        dropDistancesM = []
        pendingDropDistanceM = 0
        result = nil
        pendingReadingInput = ""
        awaitingReading = false
    }

    private func format(_ value: Double) -> String { String(format: "%.3f", value) }
}

// MARK: - View

struct MomentsLabView: View {
    let curriculum: Curriculum
    @State private var viewModel: MomentsExperimentViewModel
    @FocusState private var readingFieldFocused: Bool

    init(curriculum: Curriculum, repository: AttemptRepository) {
        self.curriculum = curriculum
        _viewModel = State(initialValue: MomentsExperimentViewModel(
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum),
            seed: Int.random(in: 0...Int(Int32.max))
        ))
    }

    var body: some View {
        LabScaffoldView(
            title: "Moments Lab",
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
            let pivot = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.45)
            let beamHalfLengthPx = geo.size.width * 0.42
            let pxPerMetre = beamHalfLengthPx / MomentsLabState.halfBeamLengthM

            ZStack {
                Canvas { context, _ in
                    // Pivot triangle.
                    var pivotShape = Path()
                    pivotShape.move(to: CGPoint(x: pivot.x, y: pivot.y))
                    pivotShape.addLine(to: CGPoint(x: pivot.x - 14, y: pivot.y + 24))
                    pivotShape.addLine(to: CGPoint(x: pivot.x + 14, y: pivot.y + 24))
                    pivotShape.closeSubpath()
                    context.fill(pivotShape, with: .color(Color(hex: "#0F5A4F")))

                    // Beam, rotated by the live tilt around the pivot.
                    let angleRad = viewModel.apparatus.tiltDeg * .pi / 180
                    let leftEnd = CGPoint(
                        x: pivot.x - beamHalfLengthPx * cos(angleRad),
                        y: pivot.y - beamHalfLengthPx * sin(angleRad)
                    )
                    let rightEnd = CGPoint(
                        x: pivot.x + beamHalfLengthPx * cos(angleRad),
                        y: pivot.y + beamHalfLengthPx * sin(angleRad)
                    )
                    var beam = Path()
                    beam.move(to: leftEnd)
                    beam.addLine(to: rightEnd)
                    context.stroke(beam, with: .color(Color(hex: "#8B5E3C")), lineWidth: 8)

                    // Left (fixed, given) weight.
                    let leftWeightT = viewModel.apparatus.leftDistanceM / MomentsLabState.halfBeamLengthM
                    let leftWeightPos = CGPoint(
                        x: pivot.x - beamHalfLengthPx * leftWeightT * cos(angleRad),
                        y: pivot.y - beamHalfLengthPx * leftWeightT * sin(angleRad) + 16
                    )
                    LabCanvasHelpers.drawWeight(context: context, center: leftWeightPos, radiusPx: 14, color: Color(hex: "#2980B9"))

                    // Right (draggable) weight.
                    let rightWeightT = viewModel.apparatus.rightDistanceM / MomentsLabState.halfBeamLengthM
                    let rightWeightPos = CGPoint(
                        x: pivot.x + beamHalfLengthPx * rightWeightT * cos(angleRad),
                        y: pivot.y + beamHalfLengthPx * rightWeightT * sin(angleRad) + 16
                    )
                    LabCanvasHelpers.drawWeight(context: context, center: rightWeightPos, radiusPx: 14, color: Color(hex: "#D98B36"))

                    LabCanvasHelpers.drawLabel(context: context, text: viewModel.givenLeftDescription, at: CGPoint(x: pivot.x, y: 16), size: 11)
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            guard !viewModel.awaitingReading else { return }
                            let dxFromPivot = value.location.x - pivot.x
                            let distanceM = max(0, min(Double(dxFromPivot / pxPerMetre), MomentsLabState.halfBeamLengthM))
                            viewModel.apparatus.rightDistanceM = distanceM
                        }
                        .onEnded { _ in
                            guard !viewModel.awaitingReading else { return }
                            viewModel.endDrag()
                        }
                )
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        if !viewModel.awaitingReading && viewModel.result == nil {
            Text("Weight to balance with").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            HStack(spacing: 10) {
                ForEach(viewModel.availableRightForcesN, id: \.self) { forceN in
                    Button("\(Int(forceN)) N") { viewModel.selectRightForce(forceN) }
                        .buttonStyle(.bordered)
                }
            }
            Text("Drag the orange weight along the beam.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        if viewModel.awaitingReading {
            HStack {
                TextField("Distance d\u{2082}", text: $viewModel.pendingReadingInput)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($readingFieldFocused)
                Text("m").foregroundStyle(.secondary)
            }
            Button("Record reading") {
                readingFieldFocused = false
                viewModel.submitReading()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }

        if !viewModel.awaitingReading && viewModel.result == nil && viewModel.canCalculate {
            Button("Calculate result") { viewModel.calculateResult() }
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
