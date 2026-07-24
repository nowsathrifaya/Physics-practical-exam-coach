//
//  ReflectionLabView.swift
//  PhysicsPracticalCoach
//
//  Law of Reflection lab experiment, built on the Lab framework (see
//  `PendulumLabView.swift` for the reference template and `LAB_FRAMEWORK.md`
//  for the architecture). Fills the syllabus gap for "investigation of the
//  law of reflection using a plane mirror". The student sets an angle of
//  incidence, watches the incident and reflected rays draw themselves
//  against a protractor, then reads and types the angle of reflection
//  themselves \u{2014} across three trials \u{2014} to verify i = r empirically, exactly
//  as the optical-pin method does on paper.
//

import SwiftUI

// MARK: - 1. Apparatus state

@Observable
final class ReflectionLabState {
    /// Current angle of incidence set by the slider, in degrees from the
    /// normal (20\u{2013}70\u{00B0}, matching a realistic optical-pin setup where very
    /// shallow or very steep angles are hard to measure accurately).
    var incidenceAngleDeg: Double = 40
    private(set) var trialLocked = false

    init() {}

    func lockTrial() {
        trialLocked = true
    }

    func unlockForNextTrial() {
        trialLocked = false
    }
}

// MARK: - 2. Experiment view model

@MainActor
@Observable
final class ReflectionExperimentViewModel {
    private(set) var apparatus = ReflectionLabState()
    private let recorder: LabAttemptRecorder

    var reflectionAngleInput: String = ""
    private(set) var readings: [LabReading] = []
    private(set) var result: LabRunResult?

    private static let requiredTrials = 3
    private static let toleranceDeg = 2.0 // mimics realistic protractor-reading error

    init(recorder: LabAttemptRecorder) {
        self.recorder = recorder
    }

    var instructionText: String {
        if !apparatus.trialLocked {
            return "Trial \(readings.count + 1) of \(Self.requiredTrials): set an angle of incidence, then tap 'Set this trial'."
        }
        return "Read the angle of reflection off the protractor and enter it below."
    }

    func lockTrial() {
        apparatus.lockTrial()
    }

    func recordReflectionReading() {
        guard let value = Double(reflectionAngleInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")) else { return }
        readings.append(LabReading(
            trialNumber: readings.count + 1,
            label: "i (incidence)", value: apparatus.incidenceAngleDeg, unit: "\u{00B0}",
            derivedLabel: "r (reflection)", derivedValue: value, derivedUnit: "\u{00B0}"
        ))
        reflectionAngleInput = ""
        apparatus.unlockForNextTrial()
    }

    var canCalculate: Bool { readings.count >= Self.requiredTrials }

    func calculateResult() {
        guard canCalculate else { return }

        let errors = readings.map { abs(($0.derivedValue ?? 0) - $0.value) }
        let trialsWithinTolerance = errors.filter { $0 <= Self.toleranceDeg }.count
        let correct = trialsWithinTolerance == readings.count

        var feedback: [String] = []
        for (index, reading) in readings.enumerated() {
            let r = reading.derivedValue ?? 0
            feedback.append("Trial \(index + 1): i = \(format(reading.value))\u{00B0}, r = \(format(r))\u{00B0}.")
        }
        feedback.append("\(trialsWithinTolerance) of \(readings.count) trials had r within \(format(Self.toleranceDeg))\u{00B0} of i.")

        let outcome = LabRunResult(
            correct: correct,
            score: Int((Double(trialsWithinTolerance) / Double(readings.count)) * 100),
            feedback: feedback,
            examTip: "The law of reflection states the angle of incidence equals the angle of reflection, BOTH measured from the normal \u{2014} not from the mirror surface. Using the optical-pin, no-parallax method for both rays is what keeps this accurate on paper."
        )
        result = outcome
        recorder.record(experimentTitle: SimulationType.planeMirrorReflection.label, result: outcome)
    }

    func newTask() {
        apparatus = ReflectionLabState()
        readings = []
        result = nil
        reflectionAngleInput = ""
    }

    private func format(_ value: Double) -> String { String(format: "%.1f", value) }
}

// MARK: - View

struct ReflectionLabView: View {
    let curriculum: Curriculum
    @State private var viewModel: ReflectionExperimentViewModel
    @FocusState private var readingFieldFocused: Bool

    init(curriculum: Curriculum, repository: AttemptRepository) {
        self.curriculum = curriculum
        _viewModel = State(initialValue: ReflectionExperimentViewModel(
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum)
        ))
    }

    var body: some View {
        LabScaffoldView(
            title: "Reflection Lab",
            instructionText: viewModel.instructionText,
            apparatusHeight: 320,
            readings: viewModel.readings,
            result: viewModel.result,
            apparatus: { apparatusArea },
            controls: { controls }
        )
    }

    private var apparatusArea: some View {
        GeometryReader { geo in
            let mirrorY = geo.size.height * 0.68
            let mirrorPoint = CGPoint(x: geo.size.width / 2, y: mirrorY)
            let rayLength = min(geo.size.width, geo.size.height) * 0.5
            let incidenceRad = viewModel.apparatus.incidenceAngleDeg * .pi / 180

            Canvas { context, _ in
                // Mirror surface.
                var mirror = Path()
                mirror.move(to: CGPoint(x: 20, y: mirrorY))
                mirror.addLine(to: CGPoint(x: geo.size.width - 20, y: mirrorY))
                context.stroke(mirror, with: .color(Color(hex: "#2980B9")), lineWidth: 3)

                // Normal (dashed, perpendicular to the mirror).
                var normal = Path()
                normal.move(to: CGPoint(x: mirrorPoint.x, y: mirrorY - rayLength))
                normal.addLine(to: CGPoint(x: mirrorPoint.x, y: mirrorY + 24))
                context.stroke(normal, with: .color(.secondary.opacity(0.6)), style: StrokeStyle(lineWidth: 1.2, dash: [4, 4]))

                // Incident ray, from the upper-left at the set angle of incidence.
                let incidentSource = CGPoint(
                    x: mirrorPoint.x - rayLength * sin(incidenceRad),
                    y: mirrorPoint.y - rayLength * cos(incidenceRad)
                )
                var incident = Path()
                incident.move(to: incidentSource)
                incident.addLine(to: mirrorPoint)
                context.stroke(incident, with: .color(.orange), lineWidth: 2.5)

                if viewModel.apparatus.trialLocked {
                    // Reflected ray, drawn symmetrically \u{2014} the student's job
                    // is to independently read this angle off the protractor,
                    // not to see it computed for them.
                    let reflectedEnd = CGPoint(
                        x: mirrorPoint.x + rayLength * sin(incidenceRad),
                        y: mirrorPoint.y - rayLength * cos(incidenceRad)
                    )
                    var reflected = Path()
                    reflected.move(to: mirrorPoint)
                    reflected.addLine(to: reflectedEnd)
                    context.stroke(reflected, with: .color(.green), lineWidth: 2.5)

                    var protractor = Path()
                    protractor.addArc(center: mirrorPoint, radius: rayLength * 0.6, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
                    context.stroke(protractor, with: .color(.secondary.opacity(0.4)), lineWidth: 1)
                }

                LabCanvasHelpers.drawLabel(context: context, text: "i = \(String(format: "%.0f", viewModel.apparatus.incidenceAngleDeg))\u{00B0}", at: CGPoint(x: incidentSource.x, y: incidentSource.y - 10), size: 12)
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        if !viewModel.apparatus.trialLocked {
            VStack(alignment: .leading, spacing: 6) {
                Text("Angle of incidence: \(String(format: "%.0f", viewModel.apparatus.incidenceAngleDeg))\u{00B0}")
                    .font(.subheadline)
                Slider(value: $viewModel.apparatus.incidenceAngleDeg, in: 20...70, step: 1)
            }
            Button("Set this trial") { viewModel.lockTrial() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        } else {
            HStack {
                TextField("Reflection angle measured", text: $viewModel.reflectionAngleInput)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($readingFieldFocused)
                Text("\u{00B0}").foregroundStyle(.secondary)
            }
            Button("Record reading") {
                readingFieldFocused = false
                viewModel.recordReflectionReading()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }

        if viewModel.canCalculate && viewModel.result == nil {
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
