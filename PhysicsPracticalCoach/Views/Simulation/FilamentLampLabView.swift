//
//  FilamentLampLabView.swift
//  PhysicsPracticalCoach
//
//  Filament Lamp I-V Characteristic lab experiment, built on the Lab
//  framework (see `PendulumLabView.swift` for the reference template and
//  `LAB_FRAMEWORK.md` for the architecture). Converted last among the
//  `GenericSimulationView` placeholders — every curriculum simulation now
//  has a full Lab build.
//
//  Structurally the closest sibling to `OhmsLawLabView.swift` (same
//  rheostat drag + ammeter/voltmeter typed-reading circuit apparatus,
//  reusing the identical `.currentVoltage` Graph Coach axis definition),
//  but the whole point of this experiment is the one place it deliberately
//  ISN'T like Ohm's Law: the lamp's resistance is not constant. As current
//  rises the filament heats up and R = R0 + kI grows with it, so V is
//  quadratic in I rather than linear — solved self-consistently as the
//  positive root of the resulting quadratic circuit equation, not faked
//  with an arbitrary curve. There is deliberately no gradient to grade:
//  `GraphGradientMarker`/`LinearRegression` are not used (mirroring Cooling
//  Curve's break from the graph-coach convention for the same underlying
//  reason — a non-straight-line relationship has no single gradient). The
//  graded quantity is a resistance RATIO the student computes from their
//  own lowest- and highest-current readings, which is exactly the standard
//  exam technique for demonstrating non-ohmic behaviour: calculate R = V/I
//  at two different currents and show it isn't constant.
//

import SwiftUI

// MARK: - 1. Apparatus state

@Observable
final class FilamentLampLabState {
    private static let emfV = 6.0
    private static let rheostatMaxOhm = 40.0

    /// Cold (near-zero-current) resistance of the filament (ohms).
    let coldResistanceOhm: Double
    /// Rate at which resistance grows with current, R(I) = R0 + kI —
    /// deliberately tied to `coldResistanceOhm` (k = 6 x R0) rather than
    /// an independent random value, so every session produces a similarly
    /// shaped, clearly non-ohmic curve regardless of the exact R0 drawn.
    let tempCoefficient: Double

    /// 0...1 slider position along the rheostat track. Starts at 1 (full
    /// added resistance, lowest/safest current) matching the real
    /// practical convention of starting with maximum protective
    /// resistance in circuit before winding it down.
    var rheostatFraction: Double = 1.0

    init(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        coldResistanceOhm = ((rng.nextDouble(2.0, 4.0)) * 10).rounded() / 10
        tempCoefficient = coldResistanceOhm * 6.0
    }

    private var rheostatOhm: Double { rheostatFraction * Self.rheostatMaxOhm }

    /// Lamp resistance at a given current (ohms) — the filament's I-V
    /// relationship itself, evaluable at any current, not just the live
    /// circuit's current right now.
    func resistanceOhm(atCurrentA current: Double) -> Double {
        coldResistanceOhm + tempCoefficient * current
    }

    /// True circuit current for the current rheostat setting (A), found by
    /// solving EMF = I x rheostat + I x R(I) = kI^2 + (rheostat + R0)I - EMF = 0
    /// for its positive root — the lamp's own resistance depends on the
    /// current flowing through it, so this can't be read off directly the
    /// way Ohm's Law's fixed-resistance circuit can.
    var trueCurrentA: Double {
        let a = tempCoefficient
        let b = rheostatOhm + coldResistanceOhm
        let c = -Self.emfV
        let discriminant = b * b - 4 * a * c
        return (-b + discriminant.squareRoot()) / (2 * a)
    }

    /// True voltage across the lamp (V), what the voltmeter would show if
    /// perfectly read.
    var trueVoltageV: Double {
        trueCurrentA * resistanceOhm(atCurrentA: trueCurrentA)
    }
}

// MARK: - 2. Experiment view model

@MainActor
@Observable
final class FilamentLampExperimentViewModel {
    private(set) var apparatus: FilamentLampLabState
    private let recorder: LabAttemptRecorder

    /// Forwards to `apparatus.rheostatFraction` so the UI can form a
    /// two-way binding without needing write access to `apparatus` itself.
    var rheostatFraction: Double {
        get { apparatus.rheostatFraction }
        set { apparatus.rheostatFraction = newValue }
    }

    private(set) var readings: [LabReading] = []
    private(set) var result: LabRunResult?
    var ammeterInput: String = ""
    var voltmeterInput: String = ""
    var ratioAnswerInput: String = ""

    private static let voltmeterTolerance = 0.15 // V
    private static let ratioToleranceFraction = 0.25 // generous: compounds two readings' own errors

    init(recorder: LabAttemptRecorder, seed: Int) {
        self.recorder = recorder
        self.apparatus = FilamentLampLabState(seed: seed)
    }

    var instructionText: String {
        "Drag the rheostat across its full range and record the ammeter and voltmeter at several settings, from dim to bright."
    }

    func recordReading() {
        guard
            let ammeterValue = Double(ammeterInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")),
            let voltmeterValue = Double(voltmeterInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
        else { return }

        readings.append(LabReading(
            trialNumber: readings.count + 1,
            label: "Current I", value: (ammeterValue * 1000).rounded() / 1000, unit: "A",
            derivedLabel: "Voltage V", derivedValue: (voltmeterValue * 1000).rounded() / 1000, derivedUnit: "V"
        ))
        ammeterInput = ""
        voltmeterInput = ""
    }

    var canCalculate: Bool { readings.count >= 2 }

    func calculateResult() {
        guard
            canCalculate,
            let studentRatio = Double(ratioAnswerInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")),
            let minReading = readings.min(by: { $0.value < $1.value }),
            let maxReading = readings.max(by: { $0.value < $1.value }),
            minReading.value != maxReading.value
        else { return }

        let perReadingCorrectCount = readings.filter {
            guard let voltage = $0.derivedValue else { return false }
            let expectedVoltage = $0.value * apparatus.resistanceOhm(atCurrentA: $0.value)
            return abs(voltage - expectedVoltage) <= Self.voltmeterTolerance
        }.count

        // Expected ratio evaluated at the student's OWN lowest/highest
        // recorded currents, not the theoretical extremes of the
        // rheostat's range — same "grade against their own data"
        // convention as Cooling Curve's freezing point.
        let expectedRLow = apparatus.resistanceOhm(atCurrentA: minReading.value)
        let expectedRHigh = apparatus.resistanceOhm(atCurrentA: maxReading.value)
        let expectedRatio = expectedRHigh / expectedRLow
        let ratioTolerance = expectedRatio * Self.ratioToleranceFraction
        let ratioCorrect = abs(studentRatio - expectedRatio) <= ratioTolerance
        let majorityReadingsCorrect = perReadingCorrectCount * 2 >= readings.count

        var feedback: [String] = []
        feedback.append("\(perReadingCorrectCount) of \(readings.count) voltmeter readings were within tolerance.")
        feedback.append("R at your lowest current (\(format(minReading.value)) A): about \(format(expectedRLow)) \u{03A9}.")
        feedback.append("R at your highest current (\(format(maxReading.value)) A): about \(format(expectedRHigh)) \u{03A9}.")
        feedback.append("Your ratio: \(format(studentRatio)). Accepted range: \(format(expectedRatio - ratioTolerance))\u{2013}\(format(expectedRatio + ratioTolerance)).")
        if readings.count < 5 {
            feedback.append("Real exams expect at least 5 rheostat settings spread across the full range \u2014 try recording more trials next time.")
        }
        let spreadA = maxReading.value - minReading.value
        if spreadA < 0.15 {
            feedback.append("Your readings were bunched close together in current \u2014 spread the rheostat setting more widely to see the resistance change clearly.")
        }

        let correct = ratioCorrect && majorityReadingsCorrect
        let outcome = LabRunResult(
            correct: correct,
            score: correct ? 100 : (ratioCorrect ? 70 : 40),
            feedback: feedback,
            examTip: "R = V/I increases as the filament heats up and glows brighter, so the I-V graph curves away from a straight line through the origin \u2014 that curvature IS the evidence the lamp is non-ohmic. Calculate R separately at a low current and a high current to show it changes; an ohmic conductor would give the same R throughout."
        )
        result = outcome
        recorder.record(experimentTitle: SimulationType.filamentLamp.label, result: outcome)
    }

    var studentDataset: GraphDataset {
        let points = readings.compactMap { reading -> GraphPoint? in
            guard let voltage = reading.derivedValue else { return nil }
            return GraphPoint(x: reading.value, y: voltage)
        }
        return GraphDataset(type: .currentVoltage, seed: 0, points: points, expectedGradient: 0)
    }

    /// True ammeter/voltmeter readings the student should read off the
    /// dials right now — never shown as text, only rendered as needle
    /// positions, same "read it yourself" convention as Ohm's Law.
    var currentTrueReadings: (currentA: Double, voltageV: Double) {
        (apparatus.trueCurrentA, apparatus.trueVoltageV)
    }

    func newTask() {
        var rng = SeededRandomNumberGenerator(seed: Int.random(in: 0...Int(Int32.max)))
        apparatus = FilamentLampLabState(seed: rng.nextInt(0, Int(Int32.max)))
        readings = []
        result = nil
        ammeterInput = ""
        voltmeterInput = ""
        ratioAnswerInput = ""
    }

    private func format(_ value: Double) -> String { String(format: "%.2f", value) }
}

// MARK: - View

struct FilamentLampLabView: View {
    let curriculum: Curriculum
    @State private var viewModel: FilamentLampExperimentViewModel
    @FocusState private var focusedField: Field?

    private enum Field { case ammeter, voltmeter, ratio }

    init(curriculum: Curriculum, repository: AttemptRepository) {
        self.curriculum = curriculum
        _viewModel = State(initialValue: FilamentLampExperimentViewModel(
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum),
            seed: Int.random(in: 0...Int(Int32.max))
        ))
    }

    var body: some View {
        LabScaffoldView(
            title: "Filament Lamp Lab",
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
            let readings = viewModel.currentTrueReadings
            VStack(spacing: 20) {
                HStack(spacing: 24) {
                    FilamentDialGaugeView(label: "A", value: readings.currentA, maxValue: 0.6)
                    FilamentDialGaugeView(label: "V", value: readings.voltageV, maxValue: 6.0)
                }
                .frame(height: 140)

                FilamentBulbView(brightness: readings.currentA / 0.6)
                    .frame(height: 40)

                FilamentRheostatSliderView(fraction: $viewModel.rheostatFraction)
                    .frame(height: 60)
            }
            .padding(16)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    @ViewBuilder
    private var controls: some View {
        if viewModel.result == nil {
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
            Button("Record reading") {
                focusedField = nil
                viewModel.recordReading()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)

            if viewModel.canCalculate {
                HStack {
                    TextField("R(high) \u{00F7} R(low)", text: $viewModel.ratioAnswerInput)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .ratio)
                    Text("ratio").foregroundStyle(.secondary)
                }
                Button("Calculate result") {
                    focusedField = nil
                    viewModel.calculateResult()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }
        }

        if viewModel.result != nil {
            ScatterPlotCanvasView(dataset: viewModel.studentDataset, definition: GraphCoachType.currentVoltage.definition)
                .frame(height: 200)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Button("New task") { viewModel.newTask() }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
        }
    }
}

/// Duplicates Ohm's Law's dial gauge deliberately rather than sharing it
/// across files (that view is file-private there) — same minor, accepted
/// duplication convention already used for small per-experiment drag
/// controls throughout the Lab views.
private struct FilamentDialGaugeView: View {
    let label: String
    let value: Double
    let maxValue: Double

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height * 0.85)
            let radius = min(size.width, size.height) * 0.7

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
    }
}

/// Small visual payoff distinct from Ohm's Law: the bulb itself glows
/// brighter as current rises, giving an intuitive (non-numeric) preview of
/// what the ammeter/voltmeter readings will show, exactly like a real
/// filament lamp visibly brightening as the rheostat is wound down.
private struct FilamentBulbView: View {
    /// 0...1 fraction of maximum current.
    let brightness: Double

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = size.height * 0.45
            let clamped = max(0, min(1, brightness))

            if clamped > 0.05 {
                let glowRadius = radius * (1.4 + clamped * 1.8)
                context.fill(
                    Path(ellipseIn: CGRect(x: center.x - glowRadius, y: center.y - glowRadius, width: glowRadius * 2, height: glowRadius * 2)),
                    with: .color(Color(hex: "#F5C542").opacity(clamped * 0.35))
                )
            }
            let bulbColor = Color(hex: "#F5C542").opacity(0.25 + clamped * 0.75)
            context.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)), with: .color(bulbColor))
            context.stroke(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)), with: .color(Color(hex: "#8A6A1F")), lineWidth: 1.5)
        }
    }
}

/// Horizontal rheostat slider — identical drag mechanic to Ohm's Law's,
/// duplicated locally for the same file-privacy reason as
/// `FilamentDialGaugeView`.
private struct FilamentRheostatSliderView: View {
    @Binding var fraction: Double

    var body: some View {
        GeometryReader { geo in
            let trackWidth = geo.size.width - 32
            let knobX = 16 + CGFloat(fraction) * trackWidth

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.tertiarySystemFill))
                    .frame(height: 6)
                    .offset(y: geo.size.height / 2 - 3)

                Circle()
                    .fill(Color(hex: "#0F5A4F"))
                    .frame(width: 28, height: 28)
                    .position(x: knobX, y: geo.size.height / 2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newX = min(max(value.location.x, 16), 16 + trackWidth)
                                fraction = Double((newX - 16) / trackWidth)
                            }
                    )
            }
        }
    }
}
