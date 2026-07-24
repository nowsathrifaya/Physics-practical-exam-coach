//
//  PotentiometerLabView.swift
//  PhysicsPracticalCoach
//
//  Potentiometer lab experiment, built on the Lab framework (see
//  `PendulumLabView.swift` for the reference template and
//  `LAB_FRAMEWORK.md` for the architecture). Chosen as the first
//  `GenericSimulationView` placeholder to convert since it's the most
//  frequently examined of the seven remaining slider placeholders (WAEC/NECO
//  past papers 2014, 2018, 2022, 2023 — see `SimulationType.potentiometer`).
//
//  The student drags a jockey along a resistance wire, reads the voltmeter
//  themselves (typed reading + tolerance grading, same convention as
//  Ohm's Law and Apparatus Practice), and records V against jockey position
//  l for several positions. Because the wire is uniform and the driver
//  current is held constant, V is directly proportional to l; the final
//  graph reuses the Graph Coach `.potentialGradient` axis definition and
//  `ScatterPlotCanvasView`, and the gradient is the potential gradient
//  K = I x r that a real WAEC/NECO mark scheme asks for.
//
//  Two exam-technique lessons from `AceQuestionBank.poten_ace_01/02` are
//  baked directly into this experiment rather than just described in text:
//  the instruction reminds the student to tap (not press-and-hold) the
//  jockey, and the hidden contact-resistance offset means the V-l line
//  sometimes doesn't pass through the origin — exactly the scenario
//  `poten_ace_02` asks students to explain.
//

import SwiftUI

// MARK: - 1. Apparatus state

@Observable
final class PotentiometerLabState {
    static let wireLengthM: Double = 1.00

    /// Hidden, constant driver current set up by the driver cell + protective
    /// resistor for this session (A) — a real potentiometer experiment keeps
    /// this fixed throughout, only the jockey position varies.
    let driverCurrentA: Double
    /// Hidden resistance per unit length of the uniform wire (ohm/m).
    let resistancePerMetreOhm: Double
    /// Hidden small voltage offset from contact resistance at the wire's end
    /// connections — usually zero, but sometimes nonzero so the V-l graph
    /// doesn't pass through the origin, matching `poten_ace_02`.
    let contactResistanceOffsetV: Double

    var jockeyPositionM: Double = 0.5

    init(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        driverCurrentA = ((rng.nextDouble(0.20, 0.50)) * 100).rounded() / 100
        resistancePerMetreOhm = ((rng.nextDouble(2.0, 5.0)) * 10).rounded() / 10
        contactResistanceOffsetV = rng.nextBoolean() ? 0 : ((rng.nextDouble(0.02, 0.06)) * 100).rounded() / 100
    }

    /// True potential gradient K = I x r (V/m) — what the V-l graph's
    /// gradient should equal, independent of the contact-resistance offset.
    var truePotentialGradientVPerM: Double { driverCurrentA * resistancePerMetreOhm }

    /// True voltmeter reading for the current jockey position (V) — never
    /// shown as text, only rendered as a needle position, matching the
    /// "read it yourself" principle everywhere else in the app.
    var trueVoltageAtJockeyV: Double {
        truePotentialGradientVPerM * jockeyPositionM + contactResistanceOffsetV
    }

    func setJockeyPosition(_ value: Double) {
        jockeyPositionM = min(max(value, 0), Self.wireLengthM)
    }
}

// MARK: - 2. Experiment view model

@MainActor
@Observable
final class PotentiometerExperimentViewModel {
    private(set) var apparatus: PotentiometerLabState
    private let recorder: LabAttemptRecorder

    private(set) var readings: [LabReading] = []
    private(set) var result: LabRunResult?
    var voltmeterInput: String = ""

    /// Optional hook for the Virtual Lab Experiment workflow wrapper — fires
    /// once after `calculateResult()` sets `result`. Nil by default, so
    /// existing standalone `PotentiometerLabView` usage behaves exactly as before;
    /// only the new wrapping workflow sets this.
    var onFinished: ((LabRunResult) -> Void)?

    init(recorder: LabAttemptRecorder, seed: Int) {
        self.recorder = recorder
        self.apparatus = PotentiometerLabState(seed: seed)
    }

    /// Forwards to `apparatus.jockeyPositionM` so the UI can form a two-way
    /// binding without needing write access to `apparatus` itself.
    var jockeyPositionM: Double {
        get { apparatus.jockeyPositionM }
        set { apparatus.setJockeyPosition(newValue) }
    }

    var instructionText: String {
        "Drag the jockey to a new position along the wire and tap briefly — don't press and hold, that wears the wire down. Then read the voltmeter and record it."
    }

    func recordReading() {
        guard let voltmeterValue = Double(voltmeterInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")) else { return }
        SoundManager.shared.play(.measurement)
        readings.append(LabReading(
            trialNumber: readings.count + 1,
            label: "Length l", value: (apparatus.jockeyPositionM * 100).rounded() / 100, unit: "m",
            derivedLabel: "Voltage V", derivedValue: (voltmeterValue * 1000).rounded() / 1000, derivedUnit: "V"
        ))
        voltmeterInput = ""
    }

    var canCalculate: Bool { readings.count >= 2 }

    func calculateResult() {
        guard canCalculate else { return }
        // V (y) vs l (x) -> gradient = K, the potential gradient.
        let points = readings.compactMap { reading -> RegressionPoint? in
            guard let voltage = reading.derivedValue else { return nil }
            return RegressionPoint(x: reading.value, y: voltage)
        }
        guard points.count >= 2 else { return } // defensive: LinearRegression.fit requires >=2
        let regression = LinearRegression.fit(points)
        let studentGradient = regression.slope
        let trueGradient = apparatus.truePotentialGradientVPerM
        let tolerance = trueGradient * 0.15
        let correct = abs(studentGradient - trueGradient) <= tolerance

        var feedback: [String] = []
        feedback.append("Your potential gradient K (gradient of V against l): \(format(studentGradient)) V/m.")
        feedback.append("Accepted range: \(format(trueGradient - tolerance))\u{2013}\(format(trueGradient + tolerance)) V/m.")
        if abs(regression.intercept) > 0.03 {
            feedback.append("Your line's y-intercept (\(format(regression.intercept)) V) isn't close to zero \u{2014} in a real practical this points to contact resistance at the wire's end connections, not an error in your gradient.")
        }
        if readings.count < 5 {
            feedback.append("Real exams expect at least 5 jockey positions spread across the wire \u{2014} try recording more trials next time.")
        }

        let outcome = LabRunResult(
            correct: correct,
            score: correct ? 100 : 45,
            feedback: feedback,
            examTip: "Plot V (y) against l (x) \u{2014} the gradient is the potential gradient K = I \u{00D7} r. Tap the jockey briefly rather than pressing and holding it \u{2014} holding it down wears the wire and changes its resistance per unit length."
        )
        result = outcome
        recorder.record(experimentTitle: SimulationType.potentiometer.label, result: outcome)
        onFinished?(outcome)
    }

    var studentDataset: GraphDataset {
        let points = readings.compactMap { reading -> GraphPoint? in
            guard let voltage = reading.derivedValue else { return nil }
            return GraphPoint(x: reading.value, y: voltage)
        }
        return GraphDataset(type: .potentialGradient, seed: 0, points: points, expectedGradient: apparatus.truePotentialGradientVPerM)
    }

    var currentTrueVoltageV: Double { apparatus.trueVoltageAtJockeyV }

    func newTask() {
        var rng = SeededRandomNumberGenerator(seed: Int.random(in: 0...Int(Int32.max)))
        apparatus = PotentiometerLabState(seed: rng.nextInt(0, Int(Int32.max)))
        readings = []
        result = nil
        voltmeterInput = ""
    }

    private func format(_ value: Double) -> String { String(format: "%.3f", value) }
}

// MARK: - View

struct PotentiometerLabView: View {
    let curriculum: Curriculum
    @State private var viewModel: PotentiometerExperimentViewModel
    @FocusState private var voltmeterFocused: Bool

    init(curriculum: Curriculum, repository: AttemptRepository, onFinished: ((LabRunResult) -> Void)? = nil) {
        self.curriculum = curriculum
        let model = PotentiometerExperimentViewModel(
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum),
            seed: Int.random(in: 0...Int(Int32.max))
        )
        model.onFinished = onFinished
        _viewModel = State(initialValue: model)
    }

    var body: some View {
        LabScaffoldView(
            title: "Potentiometer Lab",
            instructionText: viewModel.instructionText,
            apparatusHeight: 300,
            readings: viewModel.readings,
            result: viewModel.result,
            apparatus: { apparatusArea },
            controls: { controls }
        )
    }

    private var apparatusArea: some View {
        GeometryReader { geo in
            VStack(spacing: 16) {
                DialGaugeView(label: "V", value: viewModel.currentTrueVoltageV, maxValue: 3.0)
                    .frame(height: 110)

                JockeyWireView(
                    positionM: Binding(
                        get: { viewModel.jockeyPositionM },
                        set: { viewModel.jockeyPositionM = $0 }
                    ),
                    wireLengthM: PotentiometerLabState.wireLengthM
                )
                .frame(height: 130)
            }
            .padding(16)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    @ViewBuilder
    private var controls: some View {
        if viewModel.result == nil {
            HStack {
                TextField("Voltmeter reading", text: $viewModel.voltmeterInput)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($voltmeterFocused)
                Text("V").foregroundStyle(.secondary)
            }
            Button("Record reading") {
                voltmeterFocused = false
                viewModel.recordReading()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)

            if viewModel.canCalculate {
                Button("Calculate potential gradient K") { viewModel.calculateResult() }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
            }
        }

        if viewModel.result != nil {
            ScatterPlotCanvasView(dataset: viewModel.studentDataset, definition: GraphCoachType.potentialGradient.definition)
                .frame(height: 200)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Button("New task") { viewModel.newTask() }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
        }
    }
}

/// Simple analogue dial: an arc, a needle at the current value, and a
/// label. Deliberately schematic, not photorealistic — the student's job is
/// to read the needle position accurately, same skill as the Apparatus
/// Practice tab's ammeter/voltmeter questions. (Mirrors `OhmsLawLabView`'s
/// private `DialGaugeView` — each Lab file keeps its own copy by design,
/// same as the Kotlin/Compose side would with a file-local composable.)
private struct DialGaugeView: View {
    let label: String
    let value: Double
    let maxValue: Double

    var body: some View {
        Canvas { context, size in
            // Same fix as the other Dial Gauge copies (Resistance Wire,
            // Ohm's Law, Filament Lamp): pivot at 72%, not 85%, of the
            // canvas height, so the "V" label has real headroom instead
            // of being crammed against the very bottom edge.
            let center = CGPoint(x: size.width / 2, y: size.height * 0.72)
            let radius = min(size.width, size.height) * 0.58

            LabCanvasHelpers.drawGaugeFace(context: context, center: center, radius: radius)
            LabCanvasHelpers.drawProtractorArc(context: context, center: center, radius: radius, startDeg: 180, endDeg: 360)

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
        .accessibilityLabel("Voltmeter reading diagram")
    }
}

/// Horizontal resistance wire with a draggable jockey, a driver-cell
/// schematic, and a cm ruler beneath the wire — the student's drag position
/// directly sets `positionM`, same drag-math pattern as Ohm's Law's
/// rheostat slider, just labelled and scaled for the potentiometer's fixed
/// 1 m wire.
private struct JockeyWireView: View {
    @Binding var positionM: Double
    let wireLengthM: Double

    var body: some View {
        GeometryReader { geo in
            let leftX: CGFloat = 40
            let wireWidth = geo.size.width - leftX - 24
            let wireY = geo.size.height * 0.38
            let jockeyX = leftX + CGFloat(positionM / wireLengthM) * wireWidth

            Canvas { context, _ in
                // Driver-cell schematic (long thin + short thick plate) feeding end A.
                let battX = leftX - 22
                var battLong = Path()
                battLong.move(to: CGPoint(x: battX, y: wireY - 13))
                battLong.addLine(to: CGPoint(x: battX, y: wireY + 13))
                context.stroke(battLong, with: .color(.primary), lineWidth: 3)
                var battShort = Path()
                battShort.move(to: CGPoint(x: battX - 7, y: wireY - 7))
                battShort.addLine(to: CGPoint(x: battX - 7, y: wireY + 7))
                context.stroke(battShort, with: .color(.primary), lineWidth: 1.5)
                var battLead = Path()
                battLead.move(to: CGPoint(x: battX - 7, y: wireY))
                battLead.addLine(to: CGPoint(x: battX - 20, y: wireY))
                context.stroke(battLead, with: .color(.primary), lineWidth: 1.5)

                // Wire (steel-colored, uniform resistance wire from A to B).
                var wire = Path()
                wire.move(to: CGPoint(x: leftX, y: wireY))
                wire.addLine(to: CGPoint(x: leftX + wireWidth, y: wireY))
                context.stroke(wire, with: .color(Color(hex: "#8B9997")), lineWidth: 4)
                var wireHighlight = Path()
                wireHighlight.move(to: CGPoint(x: leftX, y: wireY - 1.3))
                wireHighlight.addLine(to: CGPoint(x: leftX + wireWidth, y: wireY - 1.3))
                context.stroke(wireHighlight, with: .color(.white.opacity(0.4)), lineWidth: 1)

                LabCanvasHelpers.drawLabel(context: context, text: "A", at: CGPoint(x: leftX - 4, y: wireY - 18), size: 12, weight: .bold)
                LabCanvasHelpers.drawLabel(context: context, text: "B", at: CGPoint(x: leftX + wireWidth + 4, y: wireY - 18), size: 12, weight: .bold)

                LabCanvasHelpers.drawHorizontalRuler(
                    context: context, originY: wireY + 10, leftX: leftX, widthPx: wireWidth,
                    maxValue: wireLengthM * 100, minorStep: 5, unit: "cm"
                )
                LabCanvasHelpers.drawLabel(context: context, text: "length along wire", at: CGPoint(x: leftX + wireWidth / 2, y: wireY + 42), size: 10, color: .secondary)

                // Jockey probe: a vertical lead down to the wire with a wiper knob on top.
                var jockeyLead = Path()
                jockeyLead.move(to: CGPoint(x: jockeyX, y: wireY - 30))
                jockeyLead.addLine(to: CGPoint(x: jockeyX, y: wireY))
                context.stroke(jockeyLead, with: .color(Color(hex: "#D98B36")), lineWidth: 3)
                let knobRect = CGRect(x: jockeyX - 7, y: wireY - 38, width: 14, height: 14)
                context.fill(
                    Path(ellipseIn: knobRect),
                    with: .radialGradient(Gradient(colors: [Color(hex: "#F2B36B"), Color(hex: "#D98B36")]), center: CGPoint(x: jockeyX - 3, y: wireY - 34), startRadius: 0, endRadius: 12)
                )
                context.stroke(Path(ellipseIn: knobRect), with: .color(.black.opacity(0.2)), lineWidth: 0.75)

                LabCanvasHelpers.drawLabel(
                    context: context, text: String(format: "l = %.2f m", positionM),
                    at: CGPoint(x: leftX + wireWidth / 2, y: wireY - 46), size: 13, weight: .semibold
                )
            }
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let clampedX = min(max(value.location.x, leftX), leftX + wireWidth)
                        positionM = Double((clampedX - leftX) / wireWidth) * wireLengthM
                    }
            )
        }
    }
}
