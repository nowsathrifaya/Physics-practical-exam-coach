//
//  ResistanceWireLabView.swift
//  PhysicsPracticalCoach
//
//  Resistance of a Wire lab experiment, built on the Lab framework (see
//  `PendulumLabView.swift` for the reference template and
//  `LAB_FRAMEWORK.md` for the architecture). Ninth lab, combining two
//  existing primitives in a new way rather than inventing a fresh
//  mechanic: the wire-and-sliding-contact drag from `PotentiometerLabView`
//  (here the contact sets the length of wire actually in circuit, not a
//  jockey tap-point), paired with the dual ammeter/voltmeter typed reading
//  from `OhmsLawLabView`.
//
//  EXAM DESIGN: because the sliding contact changes both which length of
//  wire is between the terminals AND the total circuit resistance, current
//  genuinely changes with length with no separate rheostat needed — exactly
//  how the real "Resistance of a Wire" circuit behaves. At each length the
//  student reads the ammeter and voltmeter themselves (their own reading
//  care is the only source of error, same convention as every dial in the
//  app) and R = V/I is computed per trial. The final graph plots R (y)
//  against l (x) — the exact axes `AceQuestionBank.resis_ace_01` asks
//  students to interpret — with resistivity ρ recovered from the given
//  cross-sectional area A and the gradient (ρ = gradient × A), matching
//  that question's model answer precisely rather than approximating it.
//
//  Circuit-realism pass added afterwards: length shown prominently in cm
//  (what the ruler is actually marked in) rather than only metres, a given
//  cross-sectional-area info box and R = V/I reminder shown up front rather
//  than buried in the instruction text, a clearly highlighted "wire in
//  circuit" active segment with a schematic switch and a voltmeter loop
//  drawn genuinely in parallel across the active length, a
//  "Sliding contact" label, a zoom toggle and finer tick marks on the
//  meters (reusing the same `minorTickStepDeg` addition from the Refraction
//  pass), a non-blocking plausibility warning on implausible V/I pairs, a
//  setup-phase nudge toward a wider spread of lengths, trial-progress
//  tracking (now a shared `TrialProgressView`, first built for Refraction),
//  and residual-based outlier detection on the final R-l graph.
//

import SwiftUI

// MARK: - 1. Apparatus state

@Observable
final class ResistanceWireLabState {
    static let wireLengthM: Double = 1.00
    private static let minTestLengthM: Double = 0.10

    /// Hidden true resistivity of the test wire (Ω·m) — typical of a thin
    /// nichrome-like wire used in this experiment.
    let trueResistivityOhmM: Double
    /// Given cross-sectional area (mm²) — as if pre-measured with a
    /// micrometer and quoted on the question paper, matching how a real
    /// exam supplies A so students only need to find ρ from the gradient.
    let crossSectionAreaMm2: Double
    /// Hidden driver EMF (V).
    private let emfV: Double
    /// Hidden fixed resistance from the cell's internal resistance, the
    /// ammeter, and the leads (Ω) — there is no rheostat in this circuit;
    /// changing the test length is what changes the current.
    private let fixedResistanceOhm: Double

    /// Length of wire currently between the two circuit contacts (m) — the
    /// student's own choice, set by dragging the sliding contact.
    private(set) var testLengthM: Double

    init(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        trueResistivityOhmM = rng.nextDouble(0.9e-6, 1.3e-6)
        crossSectionAreaMm2 = ((rng.nextDouble(0.05, 0.15)) * 1000).rounded() / 1000
        emfV = ((rng.nextDouble(1.5, 3.0)) * 10).rounded() / 10
        fixedResistanceOhm = ((rng.nextDouble(1.0, 3.0)) * 10).rounded() / 10
        testLengthM = rng.nextDouble(Self.minTestLengthM, Self.wireLengthM)
    }

    /// True resistance per metre = ρ/A (Ω/m) — what the R-l graph's
    /// gradient should equal. Used internally as a plausibility bound for
    /// the meter-reading warning; never displayed directly.
    var resistancePerMetreOhm: Double {
        trueResistivityOhmM / (crossSectionAreaMm2 * 1e-6)
    }

    private var testResistanceOhm: Double { resistancePerMetreOhm * testLengthM }

    /// True circuit current at the current test length (A) — never shown
    /// as text, only rendered as a needle position. Continuous, so it never
    /// happens to land on a round number — no separate randomisation needed.
    var trueCurrentA: Double {
        emfV / (fixedResistanceOhm + testResistanceOhm)
    }

    /// True voltmeter reading across the test length (V).
    var trueVoltageV: Double {
        trueCurrentA * testResistanceOhm
    }

    func setTestLength(_ value: Double) {
        testLengthM = min(max(value, Self.minTestLengthM), Self.wireLengthM)
    }
}

// MARK: - 2. Experiment view model

@MainActor
@Observable
final class ResistanceWireExperimentViewModel {
    private(set) var apparatus: ResistanceWireLabState
    private let recorder: LabAttemptRecorder

    var testLengthM: Double {
        get { apparatus.testLengthM }
        set { apparatus.setTestLength(newValue) }
    }

    private(set) var readings: [LabReading] = []
    private(set) var result: LabRunResult?
    var ammeterInput: String = ""
    var voltmeterInput: String = ""

    /// Non-blocking plausibility warning — students can still record an
    /// implausible V/I pair (that's the point of letting real mistakes
    /// happen), they just aren't left thinking it was silently accepted.
    private(set) var lastReadingWarning: String?

    static let minRecommendedTrials = 5
    private static let resistivityToleranceFraction = 0.15
    private static let minLengthSpreadM = 0.4
    private static let tooCloseToleranceM = 0.08

    /// Optional hook for the Virtual Lab Experiment workflow wrapper — fires
    /// once after `calculateResult()` sets `result`. Nil by default, so
    /// existing standalone `ResistanceWireLabView` usage behaves exactly as before;
    /// only the new wrapping workflow sets this.
    var onFinished: ((LabRunResult) -> Void)?

    init(recorder: LabAttemptRecorder, seed: Int) {
        self.recorder = recorder
        self.apparatus = ResistanceWireLabState(seed: seed)
    }

    var instructionText: String {
        "Slide the contact to a new length. Read the ammeter and voltmeter, then record them."
    }

    /// Shown only during setup, once there's a previous trial to compare
    /// against — nudges toward a wider spread of lengths before locking
    /// one in, rather than only scolding afterwards in the final feedback.
    var setupSpreadHint: String? {
        guard !readings.isEmpty else { return nil }
        let previousLengths = readings.map(\.value)
        let closest = previousLengths.min { abs($0 - apparatus.testLengthM) < abs($1 - apparatus.testLengthM) } ?? 0
        guard abs(closest - apparatus.testLengthM) < Self.tooCloseToleranceM else { return nil }
        let previousCm = previousLengths.map { "\(Int(($0 * 100).rounded())) cm" }.joined(separator: ", ")
        return "Previous lengths: \(previousCm). Try a much shorter or longer wire for a better spread."
    }

    func recordReading() {
        guard
            let ammeterValue = Double(ammeterInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")),
            let voltmeterValue = Double(voltmeterInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")),
            ammeterValue > 0
        else { return }

        SoundManager.shared.play(.measurement)
        let resistanceOhm = voltmeterValue / ammeterValue
        // Plausibility bound only, never disclosed as a number — catches an
        // implied resistance wildly outside what this length could give.
        let expectedOhm = apparatus.resistancePerMetreOhm * apparatus.testLengthM
        if resistanceOhm <= 0 || resistanceOhm > expectedOhm * 4 || resistanceOhm < expectedOhm / 4 {
            lastReadingWarning = "Check your ammeter/voltmeter reading — the resistance this implies looks unusually far from what's expected for this length of wire."
        } else {
            lastReadingWarning = nil
        }

        readings.append(LabReading(
            trialNumber: readings.count + 1,
            label: "Length l", value: (apparatus.testLengthM * 100).rounded() / 100, unit: "m",
            derivedLabel: "Resistance R (from V/I)", derivedValue: (resistanceOhm * 100).rounded() / 100, derivedUnit: "\u{03A9}"
        ))
        ammeterInput = ""
        voltmeterInput = ""
    }

    var canCalculate: Bool { readings.count >= 2 }

    func calculateResult() {
        guard canCalculate else { return }
        // R (y) vs l (x) -> gradient = resistivity / area, matching
        // AceQuestionBank.resis_ace_01's exact axis convention.
        let points = readings.compactMap { reading -> RegressionPoint? in
            guard let resistance = reading.derivedValue else { return nil }
            return RegressionPoint(x: reading.value, y: resistance)
        }
        guard points.count >= 2 else { return }
        let regression = LinearRegression.fit(points)
        let studentGradient = regression.slope
        let areaM2 = apparatus.crossSectionAreaMm2 * 1e-6
        let studentResistivityOhmM = studentGradient * areaM2

        let tolerance = apparatus.trueResistivityOhmM * Self.resistivityToleranceFraction
        let resistivityCorrect = abs(studentResistivityOhmM - apparatus.trueResistivityOhmM) <= tolerance

        let lengths = readings.map(\.value)
        let spread = (lengths.max() ?? 0) - (lengths.min() ?? 0)
        let spreadCorrect = spread >= Self.minLengthSpreadM

        var feedback: [String] = []
        feedback.append("Your gradient (R against l): \(format(studentGradient, places: 2)) \u{03A9}/m.")
        feedback.append("\u{03C1} = gradient \u{00D7} A = \(formatScientific(studentResistivityOhmM)) \u{03A9}\u{00B7}m.")
        feedback.append("Accepted range: \(formatScientific(apparatus.trueResistivityOhmM - tolerance))\u{2013}\(formatScientific(apparatus.trueResistivityOhmM + tolerance)) \u{03A9}\u{00B7}m.")
        if abs(regression.intercept) > apparatus.resistancePerMetreOhm * 0.4 * 0.05 + 0.05 {
            feedback.append("Your line's y-intercept isn't close to zero — in a real practical this points to contact resistance at the sliding contact or crocodile clips, not an error in your gradient.")
        }

        // Residual-based outlier flag: which single trial sits furthest
        // from the best-fit line relative to the others, computed honestly
        // from the regression rather than guessed.
        let residuals: [(trial: Int, residual: Double)] = readings.compactMap { reading in
            guard let resistance = reading.derivedValue else { return nil }
            let predicted = (regression.slope * reading.value) + regression.intercept
            return (reading.trialNumber, abs(resistance - predicted))
        }
        if residuals.count >= 4 {
            let meanResidual = residuals.map(\.residual).reduce(0, +) / Double(residuals.count)
            if let worst = residuals.max(by: { $0.residual < $1.residual }), meanResidual > 0, worst.residual > max(3 * meanResidual, 0.3) {
                feedback.append("Trial \(worst.trial) looks inconsistent with the trend in your other readings — worth rechecking.")
            }
        }

        if !spreadCorrect {
            feedback.append("Your lengths only span \(format(spread, places: 2)) m — real mark schemes deduct for a cramped range. Spread trials across at least \(Self.minLengthSpreadM) m.")
        }
        if readings.count < Self.minRecommendedTrials {
            feedback.append("Real exams expect at least \(Self.minRecommendedTrials) lengths spread across the wire — try recording more trials next time.")
        }

        let correct = resistivityCorrect && spreadCorrect
        let score: Int
        if correct {
            score = 100
        } else if resistivityCorrect {
            score = 75
        } else {
            score = 45
        }

        let outcome = LabRunResult(
            correct: correct,
            score: score,
            feedback: feedback,
            examTip: "Plot R (y) against l (x) — the gradient gives ρ/A directly, since R = ρl/A. Use a large triangle on the best-fit line to read the gradient, then multiply by the given cross-sectional area A to find ρ. Don't use a single R/l ratio from one point."
        )
        result = outcome
        recorder.record(experimentTitle: SimulationType.resistanceWire.label, result: outcome)
        onFinished?(outcome)
    }

    var studentDataset: GraphDataset {
        let points = readings.compactMap { reading -> GraphPoint? in
            guard let resistance = reading.derivedValue else { return nil }
            return GraphPoint(x: reading.value, y: resistance)
        }
        return GraphDataset(type: .resistanceVsLength, seed: 0, points: points, expectedGradient: apparatus.resistancePerMetreOhm)
    }

    var currentTrueReadings: (currentA: Double, voltageV: Double) {
        (apparatus.trueCurrentA, apparatus.trueVoltageV)
    }

    func newTask() {
        var rng = SeededRandomNumberGenerator(seed: Int.random(in: 0...Int(Int32.max)))
        apparatus = ResistanceWireLabState(seed: rng.nextInt(0, Int(Int32.max)))
        readings = []
        result = nil
        ammeterInput = ""
        voltmeterInput = ""
        lastReadingWarning = nil
    }

    private func format(_ value: Double, places: Int) -> String { String(format: "%.\(places)f", value) }

    private func formatScientific(_ value: Double) -> String {
        String(format: "%.2f \u{00D7} 10\u{207B}\u{2076}", value * 1e6)
    }
}

// MARK: - View

struct ResistanceWireLabView: View {
    let curriculum: Curriculum
    @State private var viewModel: ResistanceWireExperimentViewModel
    @FocusState private var focusedField: Field?
    @State private var isZoomed = false

    private enum Field { case ammeter, voltmeter }

    init(curriculum: Curriculum, repository: AttemptRepository, onFinished: ((LabRunResult) -> Void)? = nil) {
        self.curriculum = curriculum
        let model = ResistanceWireExperimentViewModel(
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum),
            seed: Int.random(in: 0...Int(Int32.max))
        )
        model.onFinished = onFinished
        _viewModel = State(initialValue: model)
    }

    var body: some View {
        LabScaffoldView(
            title: "Resistance Wire Lab",
            instructionText: viewModel.instructionText,
            apparatusHeight: isZoomed ? 420 : 360,
            readings: viewModel.readings,
            result: viewModel.result,
            apparatus: { apparatusArea },
            controls: { controls }
        )
    }

    private var apparatusArea: some View {
        GeometryReader { geo in
            let readings = viewModel.currentTrueReadings
            VStack(spacing: 10) {
                // Given-quantities header — shown up front like a real exam
                // paper would state them, not buried in the instructions.
                HStack {
                    Text("Given: Area A = \(String(format: "%.3f", viewModel.apparatus.crossSectionAreaMm2)) mm\u{00B2}")
                    Spacer()
                    Text("R = V \u{00F7} I")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                .padding(.horizontal, 2)

                Text("Selected length: \(Int((viewModel.testLengthM * 100).rounded())) cm")
                    .font(.subheadline.weight(.semibold))

                HStack(spacing: 12) {
                    DialGaugeView(label: "A", value: readings.currentA, maxValue: 1.0)
                    DialGaugeView(label: "V", value: readings.voltageV, maxValue: 3.0)
                }
                .frame(height: isZoomed ? 150 : 100)

                TestWireView(
                    testLengthM: Binding(
                        get: { viewModel.testLengthM },
                        set: { viewModel.testLengthM = $0 }
                    ),
                    wireLengthM: ResistanceWireLabState.wireLengthM
                )
                .frame(height: 160)
            }
            .padding(16)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    @ViewBuilder
    private var controls: some View {
        if viewModel.result == nil {
            HStack {
                TrialProgressView(completed: viewModel.readings.count, target: ResistanceWireExperimentViewModel.minRecommendedTrials)
                Spacer()
                Button(isZoomed ? "\u{1F50D} Zoom out" : "\u{1F50D} Zoom meters") {
                    withAnimation { isZoomed.toggle() }
                }
                .font(.caption)
            }

            if let hint = viewModel.setupSpreadHint {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            HStack {
                TextField("Ammeter reading", text: $viewModel.ammeterInput)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .ammeter)
                Text("A").foregroundStyle(.secondary)
            }
            HStack {
                TextField("Voltmeter reading", text: $viewModel.voltmeterInput)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .voltmeter)
                Text("V").foregroundStyle(.secondary)
            }
            if let warning = viewModel.lastReadingWarning {
                Text(warning)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            Button("Record reading") {
                focusedField = nil
                viewModel.recordReading()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)

            if viewModel.canCalculate {
                Button("Calculate resistivity \u{03C1}") { viewModel.calculateResult() }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
            }
        }

        if viewModel.result != nil {
            ScatterPlotCanvasView(dataset: viewModel.studentDataset, definition: GraphCoachType.resistanceVsLength.definition)
                .frame(height: 200)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Button("New task") { viewModel.newTask() }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
        }
    }
}

/// Simple analogue dial: an arc, a needle at the current value, and a
/// label. (Mirrors `OhmsLawLabView`'s private `DialGaugeView` — each Lab
/// file keeps its own copy by design.) Finer 2\u{00B0} minor ticks added
/// alongside the 10\u{00B0} major ticks via the shared `minorTickStepDeg`
/// parameter, for a more legible scale without any new drawing code.
private struct DialGaugeView: View {
    let label: String
    let value: Double
    let maxValue: Double

    var body: some View {
        Canvas { context, size in
            // Pivot sits at 72%, not 85%, of the canvas height — the
            // previous 85% left only 15% of the canvas below it, not
            // enough room for the "A"/"V" label drawn at `center.y + 18`
            // to actually fit inside the canvas's bounds at the normal
            // (unzoomed) gauge height. That's why the label — the only
            // thing that visually tells the ammeter and voltmeter apart —
            // only became visible once "Zoom meters" made the canvas
            // tall enough to contain it.
            let center = CGPoint(x: size.width / 2, y: size.height * 0.72)
            let radius = min(size.width, size.height) * 0.58

            LabCanvasHelpers.drawProtractorArc(context: context, center: center, radius: radius, startDeg: 180, endDeg: 360, minorTickStepDeg: 2)

            let majorDivisions = 5
            for i in 0...majorDivisions {
                let divisionFraction = Double(i) / Double(majorDivisions)
                let degrees = 180 + 180 * divisionFraction
                let rad = degrees * .pi / 180
                let labelPoint = CGPoint(
                    x: center.x + (radius + 12) * cos(rad),
                    y: center.y + (radius + 12) * sin(rad)
                )
                let labelValue = maxValue * divisionFraction
                LabCanvasHelpers.drawLabel(
                    context: context,
                    text: String(format: labelValue.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", labelValue),
                    at: labelPoint, size: 9
                )
            }

            let fraction = max(0, min(1, value / maxValue))
            let angleDeg = 180 + 180 * fraction
            let angleRad = angleDeg * .pi / 180
            var needle = Path()
            needle.move(to: center)
            needle.addLine(to: CGPoint(x: center.x + radius * 0.85 * cos(angleRad), y: center.y + radius * 0.85 * sin(angleRad)))
            context.stroke(needle, with: .color(.red), lineWidth: 2.5)
            context.fill(Path(ellipseIn: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6)), with: .color(.primary))

            LabCanvasHelpers.drawLabel(context: context, text: label, at: CGPoint(x: center.x, y: center.y + 18), size: 14, weight: .bold)
        }
        .accessibilityLabel("\(label) meter reading diagram")
    }
}

/// Horizontal test wire with a draggable sliding contact, a driver-cell +
/// switch schematic feeding one fixed end, and a voltmeter drawn genuinely
/// in parallel across the active (highlighted) length — not just two
/// dial gauges floating above an abstract line. Same drag-math pattern as
/// `PotentiometerLabView`'s jockey, repurposed here as the circuit-defining
/// contact rather than a voltage tap-point.
private struct TestWireView: View {
    @Binding var testLengthM: Double
    let wireLengthM: Double

    var body: some View {
        GeometryReader { geo in
            let leftX: CGFloat = 40
            let wireWidth = geo.size.width - leftX - 24
            let wireY = geo.size.height * 0.46
            let contactX = leftX + CGFloat(testLengthM / wireLengthM) * wireWidth

            Canvas { context, _ in
                // Driver-cell + switch schematic feeding the fixed end at A.
                let battX = leftX - 22
                var battLong = Path()
                battLong.move(to: CGPoint(x: battX, y: wireY - 13))
                battLong.addLine(to: CGPoint(x: battX, y: wireY + 13))
                context.stroke(battLong, with: .color(.primary), lineWidth: 3)
                var battShort = Path()
                battShort.move(to: CGPoint(x: battX - 7, y: wireY - 7))
                battShort.addLine(to: CGPoint(x: battX - 7, y: wireY + 7))
                context.stroke(battShort, with: .color(.primary), lineWidth: 1.5)

                // Switch: a small break in the return lead below the wire,
                // with a diagonal "open" stroke — schematic, not functional.
                let switchX = battX - 7
                let switchY = wireY + 30
                var switchLeadIn = Path()
                switchLeadIn.move(to: CGPoint(x: battX - 7, y: wireY + 7))
                switchLeadIn.addLine(to: CGPoint(x: switchX, y: switchY - 6))
                context.stroke(switchLeadIn, with: .color(.primary), lineWidth: 1.5)
                var switchStroke = Path()
                switchStroke.move(to: CGPoint(x: switchX, y: switchY - 6))
                switchStroke.addLine(to: CGPoint(x: switchX + 14, y: switchY - 16))
                context.stroke(switchStroke, with: .color(.primary), lineWidth: 1.5)
                context.fill(Path(ellipseIn: CGRect(x: switchX - 2, y: switchY - 8, width: 4, height: 4)), with: .color(.primary))
                LabCanvasHelpers.drawLabel(context: context, text: "switch", at: CGPoint(x: switchX + 4, y: switchY + 6), size: 8, color: .secondary)

                var battLead = Path()
                battLead.move(to: CGPoint(x: battX - 7, y: wireY))
                battLead.addLine(to: CGPoint(x: battX - 20, y: wireY))
                context.stroke(battLead, with: .color(.primary), lineWidth: 1.5)

                // Test wire: full length shown greyed out, only the A-to-
                // contact segment highlighted since that's the length
                // actually in circuit.
                var fullWire = Path()
                fullWire.move(to: CGPoint(x: leftX, y: wireY))
                fullWire.addLine(to: CGPoint(x: leftX + wireWidth, y: wireY))
                context.stroke(fullWire, with: .color(Color(hex: "#8B9997").opacity(0.3)), lineWidth: 4)

                var activeWire = Path()
                activeWire.move(to: CGPoint(x: leftX, y: wireY))
                activeWire.addLine(to: CGPoint(x: contactX, y: wireY))
                context.stroke(activeWire, with: .color(Color(hex: "#C0392B")), lineWidth: 5)
                LabCanvasHelpers.drawLabel(context: context, text: "Wire in circuit", at: CGPoint(x: leftX + (contactX - leftX) / 2, y: wireY + 14), size: 8, weight: .semibold, color: Color(hex: "#C0392B"))

                LabCanvasHelpers.drawLabel(context: context, text: "A", at: CGPoint(x: leftX - 4, y: wireY - 18), size: 12, weight: .bold)
                LabCanvasHelpers.drawLabel(context: context, text: "B", at: CGPoint(x: leftX + wireWidth + 4, y: wireY - 18), size: 12, weight: .bold)

                LabCanvasHelpers.drawHorizontalRuler(
                    context: context, originY: wireY + 26, leftX: leftX, widthPx: wireWidth,
                    maxValue: wireLengthM * 100, minorStep: 5
                )
                var cm = 0
                let totalCm = Int(wireLengthM * 100)
                while cm <= totalCm {
                    if cm % 20 == 0 {
                        let x = leftX + CGFloat(Double(cm) / Double(totalCm)) * wireWidth
                        LabCanvasHelpers.drawLabel(context: context, text: "\(cm)", at: CGPoint(x: x, y: wireY + 50), size: 9)
                    }
                    cm += 5
                }
                LabCanvasHelpers.drawLabel(context: context, text: "length in circuit / cm", at: CGPoint(x: leftX + wireWidth / 2, y: wireY + 66), size: 10, color: .secondary)

                // Voltmeter, drawn as a shallow loop genuinely spanning the
                // active length in parallel, rather than implied only by a
                // separate dial elsewhere.
                let voltmeterArcHeight: CGFloat = 34
                let voltmeterCenterX = leftX + (contactX - leftX) / 2
                var voltLeadA = Path()
                voltLeadA.move(to: CGPoint(x: leftX, y: wireY))
                voltLeadA.addLine(to: CGPoint(x: leftX, y: wireY - voltmeterArcHeight))
                context.stroke(voltLeadA, with: .color(Color(hex: "#2E7D32")), lineWidth: 1.25)
                var voltLeadB = Path()
                voltLeadB.move(to: CGPoint(x: contactX, y: wireY))
                voltLeadB.addLine(to: CGPoint(x: contactX, y: wireY - voltmeterArcHeight))
                context.stroke(voltLeadB, with: .color(Color(hex: "#2E7D32")), lineWidth: 1.25)
                var voltTop = Path()
                voltTop.move(to: CGPoint(x: leftX, y: wireY - voltmeterArcHeight))
                voltTop.addLine(to: CGPoint(x: contactX, y: wireY - voltmeterArcHeight))
                context.stroke(voltTop, with: .color(Color(hex: "#2E7D32")), style: StrokeStyle(lineWidth: 1.25, dash: [3, 3]))
                context.stroke(
                    Path(ellipseIn: CGRect(x: voltmeterCenterX - 9, y: wireY - voltmeterArcHeight - 9, width: 18, height: 18)),
                    with: .color(Color(hex: "#2E7D32")), lineWidth: 1.5
                )
                context.fill(Path(ellipseIn: CGRect(x: voltmeterCenterX - 9, y: wireY - voltmeterArcHeight - 9, width: 18, height: 18)), with: .color(Color(.systemBackground)))
                LabCanvasHelpers.drawLabel(context: context, text: "V", at: CGPoint(x: voltmeterCenterX, y: wireY - voltmeterArcHeight), size: 10, weight: .bold, color: Color(hex: "#2E7D32"))
                LabCanvasHelpers.drawLabel(context: context, text: "Voltage across test length", at: CGPoint(x: voltmeterCenterX, y: wireY - voltmeterArcHeight - 20), size: 8, color: .secondary)

                // Sliding contact: a vertical lead down to the wire with a knob on top.
                var contactLead = Path()
                contactLead.move(to: CGPoint(x: contactX, y: wireY - 12))
                contactLead.addLine(to: CGPoint(x: contactX, y: wireY))
                context.stroke(contactLead, with: .color(Color(hex: "#2E7D32")), lineWidth: 3)
                context.fill(Path(ellipseIn: CGRect(x: contactX - 7, y: wireY - 20, width: 14, height: 14)), with: .color(Color(hex: "#2E7D32")))
                LabCanvasHelpers.drawLabel(context: context, text: "Sliding contact", at: CGPoint(x: contactX, y: wireY - 26), size: 8, color: .secondary)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let clampedX = min(max(value.location.x, leftX), leftX + wireWidth)
                        testLengthM = Double((clampedX - leftX) / wireWidth) * wireLengthM
                    }
            )
        }
    }
}
