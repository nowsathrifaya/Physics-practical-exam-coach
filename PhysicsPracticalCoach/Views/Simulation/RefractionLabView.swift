//
//  RefractionLabView.swift
//  PhysicsPracticalCoach
//
//  Refraction through a Glass Block lab experiment, built on the Lab
//  framework (see `PendulumLabView.swift` for the reference template and
//  `LAB_FRAMEWORK.md` for the architecture). Eighth distinct drag
//  mechanic, and the first rotational one: the student drags the incident
//  ray around a fixed-radius arc above the point of incidence (like
//  choosing where to place their first pin), rather than along a single
//  linear axis.
//
//  EXAM DESIGN: mirrors the real optical-pins practical
//  (`AceQuestionBank.refrac_ace_01`/`refrac_ace_02`) — the student chooses
//  their own angle of incidence i (their experimental setup, not a source
//  of error), then the app draws the refracted ray genuinely bent by a
//  hidden refractive index via Snell's law and hands the student a
//  protractor to read the angle of refraction r themselves. That reading
//  step is the actual source of measurement error, never faked or
//  shortcut — exactly the parallax-style error `refrac_ace_01` describes,
//  just introduced through by-eye protractor reading instead of pin
//  alignment. At least 5 trials at different i are expected, spread widely
//  enough to trust a best-fit line, then the student's own (i, r) pairs are
//  plotted as sin i vs sin r — the exact axes `refrac_ace_02` asks
//  students to interpret — with n taken directly as the gradient.
//

import SwiftUI

// MARK: - 1. Apparatus state (physical simulation only)

@Observable
final class RefractionLabState {
    enum Phase { case settingIncidence, readingRefraction }

    private static let minIncidenceDeg: Double = 15
    private static let maxIncidenceDeg: Double = 75

    /// Hidden true refractive index of the glass block for this session.
    let refractiveIndex: Double

    private(set) var phase: Phase = .settingIncidence

    /// Angle of incidence i, in degrees from the normal — the student's
    /// own choice, set by dragging the incident-ray handle around a
    /// fixed-radius arc. Not a source of measurement error: like a real
    /// practical, the student picks where to place their pins.
    private(set) var angleOfIncidenceDeg: Double

    init(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        refractiveIndex = ((rng.nextDouble(1.44, 1.58)) * 100).rounded() / 100
        angleOfIncidenceDeg = rng.nextDouble(Self.minIncidenceDeg, Self.maxIncidenceDeg)
    }

    /// True angle of refraction for the current incidence angle, from
    /// Snell's law sin i = n sin r. Never shown as a number — only as the
    /// ray drawn on the canvas; the student must read it off the
    /// protractor themselves, exactly like tracing a ray on paper.
    var trueRefractionDeg: Double {
        let iRad = angleOfIncidenceDeg * .pi / 180
        let rRad = asin(sin(iRad) / refractiveIndex)
        return rRad * 180 / .pi
    }

    func setIncidenceFromDrag(rawAngleDeg: Double) {
        angleOfIncidenceDeg = min(max(rawAngleDeg, Self.minIncidenceDeg), Self.maxIncidenceDeg)
    }

    /// Locks in the chosen angle and reveals the refracted ray + protractor
    /// — matches placing the exit pins and then measuring the trace.
    func lockIncidence() {
        phase = .readingRefraction
    }

    /// Re-arms for another trial at a (potentially) new incidence angle —
    /// matches a real practical: reposition the pins, then re-measure.
    func rearmForNextTrial() {
        phase = .settingIncidence
    }
}

// MARK: - 2. Experiment view model (task, trials, grading)

@MainActor
@Observable
final class RefractionExperimentViewModel {
    private(set) var apparatus: RefractionLabState
    private let recorder: LabAttemptRecorder

    private(set) var readings: [LabReading] = []
    private(set) var result: LabRunResult?
    var refractionReadingInput: String = ""

    private static let minRecommendedTrials = 5
    private static let refractiveIndexToleranceFraction = 0.12
    private static let minIncidenceSpreadDeg = 30.0

    init(recorder: LabAttemptRecorder, seed: Int) {
        self.recorder = recorder
        self.apparatus = RefractionLabState(seed: seed)
    }

    var instructionText: String {
        switch apparatus.phase {
        case .settingIncidence:
            return "Drag the incident ray to set a new angle of incidence i, different from your other trials."
        case .readingRefraction:
            return "Read the refracted ray's angle from the normal off the protractor below, then enter it."
        }
    }

    func setIncidence(rawAngleDeg: Double) {
        apparatus.setIncidenceFromDrag(rawAngleDeg: rawAngleDeg)
    }

    func confirmIncidence() {
        apparatus.lockIncidence()
    }

    /// Student reads the refracted ray's angle off the protractor by eye and
    /// types it in — their own reading care IS the measurement, exactly
    /// like using a real protractor on a traced ray path.
    func recordReading() {
        guard let studentR = Double(refractionReadingInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")) else { return }
        readings.append(LabReading(
            trialNumber: readings.count + 1,
            label: "Angle of incidence i", value: (apparatus.angleOfIncidenceDeg * 10).rounded() / 10, unit: "\u{00B0}",
            derivedLabel: "Angle of refraction r (read)", derivedValue: (studentR * 10).rounded() / 10, derivedUnit: "\u{00B0}"
        ))
        refractionReadingInput = ""
        apparatus.rearmForNextTrial()
    }

    var canCalculate: Bool { readings.count >= 2 }

    func calculateResult() {
        guard canCalculate else { return }
        // sin i (y) vs sin r (x) -> gradient = n, matching
        // AceQuestionBank.refrac_ace_02's exact axis convention.
        let points = readings.compactMap { reading -> RegressionPoint? in
            guard let r = reading.derivedValue, r > 0, reading.value > 0 else { return nil }
            let iRad = reading.value * .pi / 180
            let rRad = r * .pi / 180
            return RegressionPoint(x: sin(rRad), y: sin(iRad))
        }
        guard points.count >= 2 else { return }
        let regression = LinearRegression.fit(points)
        let studentN = regression.slope

        let tolerance = apparatus.refractiveIndex * Self.refractiveIndexToleranceFraction
        let nCorrect = abs(studentN - apparatus.refractiveIndex) <= tolerance

        let iValues = readings.map(\.value)
        let spread = (iValues.max() ?? 0) - (iValues.min() ?? 0)
        let spreadCorrect = spread >= Self.minIncidenceSpreadDeg

        var feedback: [String] = []
        feedback.append("Your refractive index from the graph gradient: \(format(studentN)).")
        feedback.append("Accepted range: \(format(apparatus.refractiveIndex - tolerance))\u{2013}\(format(apparatus.refractiveIndex + tolerance)).")
        if !nCorrect {
            feedback.append("A gradient far from the accepted range usually means one or more angles of refraction were misread \u{2014} check your protractor readings.")
        }
        if !spreadCorrect {
            feedback.append("Your angles of incidence only span \(format(spread))\u{00B0} \u{2014} real mark schemes deduct for a cramped range. Spread trials across at least \(Int(Self.minIncidenceSpreadDeg))\u{00B0}.")
        }
        if readings.count < Self.minRecommendedTrials {
            feedback.append("Real exams expect at least \(Self.minRecommendedTrials) trials at different angles of incidence \u{2014} try recording more.")
        }

        let correct = nCorrect && spreadCorrect
        let score: Int
        if correct {
            score = 100
        } else if nCorrect {
            score = 75 // right physics, just too clustered a range to trust in a real exam
        } else {
            score = 45
        }

        let outcome = LabRunResult(
            correct: correct,
            score: score,
            feedback: feedback,
            examTip: "Plot sin i (y) against sin r (x) \u{2014} the gradient is the refractive index n directly, since sin i = n \u{00D7} sin r. In a real trace, use two pins on each side of the block to fix the ray direction accurately, and read both angles from the normal, not from the glass surface."
        )
        result = outcome
        recorder.record(experimentTitle: SimulationType.refraction.label, result: outcome)
    }

    var studentDataset: GraphDataset {
        let points = readings.compactMap { reading -> GraphPoint? in
            guard let r = reading.derivedValue, r > 0, reading.value > 0 else { return nil }
            let iRad = reading.value * .pi / 180
            let rRad = r * .pi / 180
            return GraphPoint(x: sin(rRad), y: sin(iRad))
        }
        return GraphDataset(type: .sinIVsSinR, seed: 0, points: points, expectedGradient: apparatus.refractiveIndex)
    }

    func newTask() {
        var rng = SeededRandomNumberGenerator(seed: Int.random(in: 0...Int(Int32.max)))
        apparatus = RefractionLabState(seed: rng.nextInt(0, Int(Int32.max)))
        readings = []
        result = nil
        refractionReadingInput = ""
    }

    private func format(_ value: Double) -> String { String(format: "%.2f", value) }
}

// MARK: - View

struct RefractionLabView: View {
    let curriculum: Curriculum
    @State private var viewModel: RefractionExperimentViewModel
    @FocusState private var readingFieldFocused: Bool

    init(curriculum: Curriculum, repository: AttemptRepository) {
        self.curriculum = curriculum
        _viewModel = State(initialValue: RefractionExperimentViewModel(
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum),
            seed: Int.random(in: 0...Int(Int32.max))
        ))
    }

    var body: some View {
        LabScaffoldView(
            title: "Refraction Lab",
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
            let originPoint = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.42)
            let incidentRayLength = min(geo.size.width, geo.size.height) * 0.36
            let refractedRayLength = min(geo.size.width, geo.size.height) * 0.42
            let protractorRadius = min(geo.size.width, geo.size.height) * 0.3
            let lab = viewModel.apparatus

            Canvas { context, size in
                // Glass block: shaded region below the surface line.
                let blockRect = CGRect(x: 0, y: originPoint.y, width: size.width, height: size.height - originPoint.y)
                context.fill(Path(blockRect), with: .color(Color(hex: "#0F5A4F").opacity(0.12)))

                var surface = Path()
                surface.move(to: CGPoint(x: 0, y: originPoint.y))
                surface.addLine(to: CGPoint(x: size.width, y: originPoint.y))
                context.stroke(surface, with: .color(Color(hex: "#5B6B69")), lineWidth: 2)
                LabCanvasHelpers.drawLabel(context: context, text: "Glass block", at: CGPoint(x: size.width - 44, y: originPoint.y + 18), size: 10, color: .secondary)

                // Normal: dashed vertical line through the point of incidence O.
                var normal = Path()
                normal.move(to: CGPoint(x: originPoint.x, y: originPoint.y - incidentRayLength - 14))
                normal.addLine(to: CGPoint(x: originPoint.x, y: originPoint.y + refractedRayLength + 14))
                context.stroke(normal, with: .color(Color(hex: "#8B9997")), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                LabCanvasHelpers.drawLabel(context: context, text: "Normal", at: CGPoint(x: originPoint.x + 32, y: originPoint.y - incidentRayLength - 14), size: 9, color: .secondary)

                // Incident ray: from A down to O, at angle i from the normal.
                let iRad = lab.angleOfIncidenceDeg * .pi / 180
                let pointA = CGPoint(
                    x: originPoint.x + incidentRayLength * CGFloat(sin(iRad)),
                    y: originPoint.y - incidentRayLength * CGFloat(cos(iRad))
                )
                var incidentRay = Path()
                incidentRay.move(to: pointA)
                incidentRay.addLine(to: originPoint)
                context.stroke(incidentRay, with: .color(Color(hex: "#C0392B")), lineWidth: 3)
                LabCanvasHelpers.drawLabel(
                    context: context, text: String(format: "i = %.0f\u{00B0}", lab.angleOfIncidenceDeg),
                    at: CGPoint(x: pointA.x + 20, y: pointA.y - 4), size: 11, weight: .semibold
                )

                if lab.phase == .settingIncidence {
                    LabCanvasHelpers.drawWeight(context: context, center: pointA, radiusPx: 9, color: Color(hex: "#C0392B"))
                }

                // Refracted ray + protractor: revealed only once the student
                // has locked their angle of incidence and moved to reading.
                if lab.phase == .readingRefraction {
                    let rRad = lab.trueRefractionDeg * .pi / 180
                    let pointB = CGPoint(
                        x: originPoint.x + refractedRayLength * CGFloat(sin(rRad)),
                        y: originPoint.y + refractedRayLength * CGFloat(cos(rRad))
                    )
                    var refractedRay = Path()
                    refractedRay.move(to: originPoint)
                    refractedRay.addLine(to: pointB)
                    context.stroke(refractedRay, with: .color(Color(hex: "#2E7D32")), lineWidth: 3)

                    LabCanvasHelpers.drawProtractorArc(
                        context: context, center: originPoint, radius: protractorRadius,
                        startDeg: 190, endDeg: 350, color: Color(hex: "#8B9997")
                    )

                    var deg = 190.0
                    while deg <= 350 {
                        if Int(deg) % 20 == 0 {
                            let rad = deg * .pi / 180
                            let labelPoint = CGPoint(
                                x: originPoint.x + (protractorRadius + 15) * CGFloat(cos(rad)),
                                y: originPoint.y + (protractorRadius + 15) * CGFloat(sin(rad))
                            )
                            let valueFromNormal = Int(abs(deg - 270).rounded())
                            LabCanvasHelpers.drawLabel(context: context, text: "\(valueFromNormal)\u{00B0}", at: labelPoint, size: 9, color: .secondary)
                        }
                        deg += 10
                    }
                }
            }
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard lab.phase == .settingIncidence else { return }
                        let dx = Double(value.location.x - originPoint.x)
                        let dy = Double(originPoint.y - value.location.y)
                        guard dy > 1 else { return }
                        let angle = atan2(dx, dy) * 180 / .pi
                        viewModel.setIncidence(rawAngleDeg: angle)
                    }
            )
        }
    }

    @ViewBuilder
    private var controls: some View {
        switch viewModel.apparatus.phase {
        case .settingIncidence:
            Button("Confirm angle \u{2014} trace the refracted ray") { viewModel.confirmIncidence() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        case .readingRefraction:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TextField("Angle of refraction r", text: $viewModel.refractionReadingInput)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .focused($readingFieldFocused)
                    Text("\u{00B0}").foregroundStyle(.secondary)
                }
                Button("Record trial") {
                    readingFieldFocused = false
                    viewModel.recordReading()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }

        if viewModel.canCalculate && viewModel.result == nil {
            Button("Calculate refractive index n") { viewModel.calculateResult() }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
        }

        if viewModel.result != nil {
            ScatterPlotCanvasView(dataset: viewModel.studentDataset, definition: GraphCoachType.sinIVsSinR.definition)
                .frame(height: 200)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Button("New task") { viewModel.newTask() }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
        }
    }
}
