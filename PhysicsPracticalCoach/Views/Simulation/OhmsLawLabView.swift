//
//  OhmsLawLabView.swift
//  PhysicsPracticalCoach
//
//  Ohm's Law lab experiment, built on the Lab framework (see
//  `PendulumLabView.swift` for the reference template and
//  `LAB_FRAMEWORK.md` for the architecture). The student drags a rheostat
//  slider to change the circuit current, reads the ammeter and voltmeter
//  themselves (typed reading + tolerance grading, same convention as
//  `ApparatusTrainer`'s instrument practice), and the final V-I graph reuses
//  the exact Graph Coach `.currentVoltage` axis definition and
//  `ScatterPlotCanvasView` — R is the gradient, same as the real mark scheme.
//

import SwiftUI

// MARK: - 1. Apparatus state

@Observable
final class OhmsLawLabState {
    /// Hidden true resistance of the wire under test (ohms).
    let trueResistanceOhm: Double
    private static let emfV = 6.0
    private static let internalResistanceOhm = 0.5
    private static let rheostatMaxOhm = 10.0

    /// 0...1 slider position along the rheostat track.
    var rheostatFraction: Double = 0.5

    init(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        trueResistanceOhm = ((rng.nextDouble(3, 12)) * 10).rounded() / 10
    }

    private var rheostatOhm: Double { rheostatFraction * Self.rheostatMaxOhm }

    /// True circuit current for the current rheostat setting (A).
    var trueCurrentA: Double {
        Self.emfV / (trueResistanceOhm + rheostatOhm + Self.internalResistanceOhm)
    }

    /// True voltage across the wire under test (V), what the voltmeter
    /// would show if perfectly read.
    var trueVoltageV: Double {
        trueCurrentA * trueResistanceOhm
    }
}

// MARK: - 2. Experiment view model

@MainActor
@Observable
final class OhmsLawExperimentViewModel {
    private(set) var apparatus: OhmsLawLabState
    private let recorder: LabAttemptRecorder

    private(set) var readings: [LabReading] = []
    private(set) var result: LabRunResult?
    var ammeterInput: String = ""
    var voltmeterInput: String = ""

    private static let ammeterTolerance = 0.03 // A
    private static let voltmeterTolerance = 0.1 // V

    init(recorder: LabAttemptRecorder, seed: Int) {
        self.recorder = recorder
        self.apparatus = OhmsLawLabState(seed: seed)
    }

    var instructionText: String {
        "Drag the rheostat slider to a new setting, then read the ammeter and voltmeter and record them."
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
        guard canCalculate else { return }
        // V (y) vs I (x) -> gradient = R, matching the standard exam convention.
        let points = readings.compactMap { reading -> RegressionPoint? in
            guard let voltage = reading.derivedValue else { return nil }
            return RegressionPoint(x: reading.value, y: voltage)
        }
        let regression = LinearRegression.fit(points)
        let studentR = regression.slope
        let tolerance = apparatus.trueResistanceOhm * 0.15
        let correct = abs(studentR - apparatus.trueResistanceOhm) <= tolerance

        var feedback: [String] = []
        feedback.append("Your gradient (resistance R): \(format(studentR)) \u{03A9}.")
        feedback.append("Accepted range: \(format(apparatus.trueResistanceOhm - tolerance))\u{2013}\(format(apparatus.trueResistanceOhm + tolerance)) \u{03A9}.")
        if readings.count < 5 {
            feedback.append("Real exams expect at least 5 rheostat settings \u{2014} try recording more trials next time.")
        }

        let outcome = LabRunResult(
            correct: correct,
            score: correct ? 100 : 45,
            feedback: feedback,
            examTip: "Plot V (y) against I (x) \u{2014} R is the gradient directly, since V = IR. Vary the rheostat across its full range for a well-spread set of points."
        )
        result = outcome
        recorder.record(experimentTitle: SimulationType.ohmsLaw.label, result: outcome)
    }

    var studentDataset: GraphDataset {
        let points = readings.compactMap { reading -> GraphPoint? in
            guard let voltage = reading.derivedValue else { return nil }
            return GraphPoint(x: reading.value, y: voltage)
        }
        return GraphDataset(type: .currentVoltage, seed: 0, points: points, expectedGradient: apparatus.trueResistanceOhm)
    }

    /// True ammeter/voltmeter readings the student should read off the
    /// dials right now — never shown as text, only rendered as needle
    /// positions, matching the "read it yourself" principle everywhere else
    /// in the app.
    var currentTrueReadings: (currentA: Double, voltageV: Double) {
        (apparatus.trueCurrentA, apparatus.trueVoltageV)
    }

    func newTask() {
        var rng = SeededRandomNumberGenerator(seed: Int.random(in: 0...Int(Int32.max)))
        apparatus = OhmsLawLabState(seed: rng.nextInt(0, Int(Int32.max)))
        readings = []
        result = nil
        ammeterInput = ""
        voltmeterInput = ""
    }

    private func format(_ value: Double) -> String { String(format: "%.2f", value) }
}

// MARK: - View

struct OhmsLawLabView: View {
    let curriculum: Curriculum
    @State private var viewModel: OhmsLawExperimentViewModel
    @FocusState private var focusedField: Field?

    private enum Field { case ammeter, voltmeter }

    init(curriculum: Curriculum, repository: AttemptRepository) {
        self.curriculum = curriculum
        _viewModel = State(initialValue: OhmsLawExperimentViewModel(
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum),
            seed: Int.random(in: 0...Int(Int32.max))
        ))
    }

    var body: some View {
        LabScaffoldView(
            title: "Ohm's Law Lab",
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
                    DialGaugeView(label: "A", value: readings.currentA, maxValue: 1.0)
                    DialGaugeView(label: "V", value: readings.voltageV, maxValue: 6.0)
                }
                .frame(height: 140)

                RheostatSliderView(fraction: $viewModel.apparatus.rheostatFraction)
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
                Button("Calculate resistance R") { viewModel.calculateResult() }
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

/// Simple analogue dial: an arc, a needle at the current value, and a
/// label. Deliberately schematic, not photorealistic — the student's job
/// is to read the needle position accurately, same skill as the Apparatus
/// Practice tab's ammeter/voltmeter questions.
private struct DialGaugeView: View {
    let label: String
    let value: Double
    let maxValue: Double

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height * 0.85)
            let radius = min(size.width, size.height) * 0.7

            LabCanvasHelpers.drawProtractorArc(context: context, center: center, radius: radius, startDeg: 180, endDeg: 360)

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

/// Horizontal rheostat slider — the student drags the knob left/right along
/// the track, same drag-math pattern as Pendulum's angle drag, just on one
/// axis instead of two.
private struct RheostatSliderView: View {
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
