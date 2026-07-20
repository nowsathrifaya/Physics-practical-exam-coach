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
//  Diagram fidelity pass: labelled point of incidence O, curved angle
//  indicator arcs for i and r (not just numeric labels), a two-tier
//  protractor scale (5° medium ticks, 10° labelled major ticks — true 1°
//  ticks aren't legible at phone-screen protractor radii, so a "zoom in to
//  read" toggle stands in for finer on-screen resolution instead), a
//  non-blocking plausibility warning on implausible readings, a specific
//  "measured from the surface, not the normal" diagnostic derived from
//  Snell's law rather than guessed, and a setup-phase nudge toward a wider
//  spread of trial angles.
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

    /// True angle of refraction for an arbitrary already-locked incidence
    /// angle (used post-hoc in grading to diagnose a specific past trial,
    /// without needing to have stored the true reading at record time).
    func trueRefractionDeg(forIncidenceDeg incidenceDeg: Double) -> Double {
        let iRad = incidenceDeg * .pi / 180
        let rRad = asin(sin(iRad) / refractiveIndex)
        return rRad * 180 / .pi
    }

    func setIncidenceFromDrag(rawAngleDeg: Double) {
        angleOfIncidenceDeg = min(max(rawAngleDeg, Self.minIncidenceDeg), Self.maxIncidenceDeg)
    }

    /// Locks in the chosen angle and reveals the refracted ray + protractor
    /// — matches placing the exit pins and then measuring the trace.
    /// When the refracted ray started revealing — drives a ~0.6s
    /// grow-in animation instead of the ray just snapping into place.
    private(set) var refractionRevealStart: Date?

    func lockIncidence() {
        phase = .readingRefraction
        refractionRevealStart = Date()
    }

    /// Re-arms for another trial at a (potentially) new incidence angle —
    /// matches a real practical: reposition the pins, then re-measure.
    func rearmForNextTrial() {
        phase = .settingIncidence
        refractionRevealStart = nil
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

    /// Non-blocking plausibility warning shown after recording a trial —
    /// students can still record an implausible reading (that's the whole
    /// point of letting real mistakes happen), they just aren't left
    /// thinking it was silently accepted as correct.
    private(set) var lastReadingWarning: String?

    static let minRecommendedTrials = 5
    private static let refractiveIndexToleranceFraction = 0.12
    private static let minIncidenceSpreadDeg = 30.0
    /// How close a previous trial's angle can be before we nudge the
    /// student toward a wider spread during setup.
    private static let tooCloseToleranceDeg = 8.0

    /// Optional hook for the Virtual Lab Experiment workflow wrapper — fires
    /// once after `calculateResult()` sets `result`. Nil by default, so
    /// existing standalone `RefractionLabView` usage behaves exactly as before;
    /// only the new wrapping workflow sets this.
    var onFinished: ((LabRunResult) -> Void)?

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

    /// Shown only during setup, only once there's at least one previous
    /// trial to compare against — encourages a wide spread of angles
    /// before the student locks one in, rather than only scolding them
    /// about it afterwards in the final feedback.
    var setupSpreadHint: String? {
        guard !readings.isEmpty else { return nil }
        let previousAngles = readings.map(\.value)
        let closest = previousAngles.min { abs($0 - apparatus.angleOfIncidenceDeg) < abs($1 - apparatus.angleOfIncidenceDeg) } ?? 0
        guard abs(closest - apparatus.angleOfIncidenceDeg) < Self.tooCloseToleranceDeg else { return nil }
        return "Previous angles: \(previousAngles.map { "\(Int($0.rounded()))\u{00B0}" }.joined(separator: ", ")). Try a noticeably different angle for a better spread."
    }

    func setIncidence(rawAngleDeg: Double) {
        apparatus.setIncidenceFromDrag(rawAngleDeg: rawAngleDeg)
    }

    func confirmIncidence() {
        apparatus.lockIncidence()
    }

    /// Student reads the refracted ray's angle off the protractor by eye and
    /// types it in — their own reading care IS the measurement, exactly
    /// like using a real protractor on a traced ray path. Physically
    /// implausible entries (r <= 0, or r >= i, which can never happen when
    /// light enters a denser medium) are still recorded, just flagged —
    /// this check needs no knowledge of the hidden refractive index, so it
    /// can't leak the answer.
    func recordReading() {
        guard let studentR = Double(refractionReadingInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")) else { return }

        if studentR <= 0 || studentR >= apparatus.angleOfIncidenceDeg {
            lastReadingWarning = "Check your protractor reading \u{2014} the angle of refraction should be smaller than the angle of incidence and greater than 0\u{00B0}. Remember to measure from the normal, not the surface."
        } else {
            lastReadingWarning = nil
        }

        readings.append(LabReading(
            trialNumber: readings.count + 1,
            label: "Angle of incidence i", value: (apparatus.angleOfIncidenceDeg * 10).rounded() / 10, unit: "\u{00B0}",
            derivedLabel: "Angle of refraction r (read)", derivedValue: (studentR * 10).rounded() / 10, derivedUnit: "\u{00B0}"
        ))
        SoundManager.shared.play(.measurement)
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
        feedback.append("Gradient = \(format(studentN))  \u{2192}  n = \(format(studentN))")
        feedback.append("Accepted range: \(format(apparatus.refractiveIndex - tolerance))\u{2013}\(format(apparatus.refractiveIndex + tolerance)).")
        if !nCorrect {
            feedback.append("A gradient far from the accepted range usually means one or more angles of refraction were misread \u{2014} check your protractor readings.")
        }

        // Diagnose "measured from the surface, not the normal" precisely:
        // since Snell's law fully determines the true r for each locked i,
        // we can check whether a specific trial's typed reading is much
        // closer to (90 - true r) than to the true r itself, without ever
        // revealing the hidden refractive index n.
        for reading in readings {
            guard let typedR = reading.derivedValue else { continue }
            let trueR = apparatus.trueRefractionDeg(forIncidenceDeg: reading.value)
            let surfaceReadingPattern = 90 - trueR
            if abs(typedR - surfaceReadingPattern) <= 3, abs(typedR - trueR) > 8 {
                feedback.append("Trial \(reading.trialNumber): this reading looks like it may have been measured from the glass surface instead of the normal \u{2014} worth rechecking.")
            }
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
        onFinished?(outcome)
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
        lastReadingWarning = nil
    }

    private func format(_ value: Double) -> String { String(format: "%.2f", value) }
}

// MARK: - View

/// Draws a small optical-pin marker (a teardrop + head, like a map pin)
/// with a letter label beside it — a recognition cue so the diagram reads
/// as "the pins experiment" at a glance, even though the app doesn't use
/// the pins themselves for any calculation.
private func drawPin(context: GraphicsContext, at point: CGPoint, label: String, color: Color) {
    var pin = Path()
    pin.addEllipse(in: CGRect(x: point.x - 3.5, y: point.y - 3.5, width: 7, height: 7))
    pin.move(to: CGPoint(x: point.x - 2.5, y: point.y + 2.5))
    pin.addLine(to: CGPoint(x: point.x, y: point.y + 9))
    pin.addLine(to: CGPoint(x: point.x + 2.5, y: point.y + 2.5))
    pin.closeSubpath()
    context.fill(pin, with: .color(color))
    context.stroke(pin, with: .color(.white.opacity(0.8)), lineWidth: 0.75)
    LabCanvasHelpers.drawLabel(context: context, text: label, at: CGPoint(x: point.x + 10, y: point.y - 2), size: 9, weight: .bold, color: color)
}

struct RefractionLabView: View {
    let curriculum: Curriculum
    @State private var viewModel: RefractionExperimentViewModel
    @FocusState private var readingFieldFocused: Bool
    @State private var isZoomed = false

    init(curriculum: Curriculum, repository: AttemptRepository, onFinished: ((LabRunResult) -> Void)? = nil) {
        self.curriculum = curriculum
        let model = RefractionExperimentViewModel(
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum),
            seed: Int.random(in: 0...Int(Int32.max))
        )
        model.onFinished = onFinished
        _viewModel = State(initialValue: model)
    }

    var body: some View {
        LabScaffoldView(
            title: "Refraction Lab",
            instructionText: viewModel.instructionText,
            apparatusHeight: isZoomed ? 460 : 320,
            readings: viewModel.readings,
            result: viewModel.result,
            apparatus: { apparatusArea },
            controls: { controls }
        )
    }

    private var apparatusArea: some View {
        GeometryReader { geo in
            let zoom: CGFloat = isZoomed ? 1.45 : 1.0
            let originPoint = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.42)
            let incidentRayLength = min(geo.size.width, geo.size.height) * 0.36 * zoom
            let refractedRayLength = min(geo.size.width, geo.size.height) * 0.42 * zoom
            let protractorRadius = min(geo.size.width, geo.size.height) * 0.3 * zoom
            let lab = viewModel.apparatus

            TimelineView(.animation) { timeline in
                Canvas { context, size in
                // Glass block: a bounded rectangle (not a full-width fill)
                // with visible side edges, a soft drop shadow, and a
                // diagonal glossy streak — reads as a physical object
                // sitting on the bench rather than a flat colour region.
                let blockMargin: CGFloat = size.width * 0.08
                let blockRect = CGRect(
                    x: blockMargin, y: originPoint.y,
                    width: size.width - blockMargin * 2, height: size.height - originPoint.y - 4
                )
                context.drawLayer { ctx in
                    ctx.addFilter(.shadow(color: .black.opacity(0.22), radius: 6, x: 0, y: 4))
                    ctx.fill(
                        RoundedRectangle(cornerRadius: 6).path(in: blockRect),
                        with: .linearGradient(
                            Gradient(colors: [Color(hex: "#BFE3F2").opacity(0.55), Color(hex: "#8FCBE8").opacity(0.30)]),
                            startPoint: CGPoint(x: 0, y: blockRect.minY),
                            endPoint: CGPoint(x: 0, y: blockRect.maxY)
                        )
                    )
                }
                context.stroke(RoundedRectangle(cornerRadius: 6).path(in: blockRect), with: .color(Color(hex: "#5B9BB5").opacity(0.6)), lineWidth: 1.5)

                // Glossy diagonal streak, clipped to the block — the detail
                // that reads as "glass" rather than "tinted plastic."
                context.drawLayer { ctx in
                    ctx.clip(to: RoundedRectangle(cornerRadius: 6).path(in: blockRect))
                    var streak = Path()
                    streak.move(to: CGPoint(x: blockRect.minX + blockRect.width * 0.12, y: blockRect.minY))
                    streak.addLine(to: CGPoint(x: blockRect.minX + blockRect.width * 0.32, y: blockRect.minY))
                    streak.addLine(to: CGPoint(x: blockRect.minX + blockRect.width * 0.14, y: blockRect.maxY))
                    streak.addLine(to: CGPoint(x: blockRect.minX + blockRect.width * 0.02, y: blockRect.maxY))
                    streak.closeSubpath()
                    ctx.fill(streak, with: .color(.white.opacity(0.28)))
                }

                var highlight = Path()
                highlight.move(to: CGPoint(x: blockRect.minX, y: originPoint.y + 3))
                highlight.addLine(to: CGPoint(x: blockRect.maxX, y: originPoint.y + 3))
                context.stroke(highlight, with: .color(.white.opacity(0.5)), lineWidth: 1.5)

                var surface = Path()
                surface.move(to: CGPoint(x: blockRect.minX, y: originPoint.y))
                surface.addLine(to: CGPoint(x: blockRect.maxX, y: originPoint.y))
                context.stroke(surface, with: .color(Color(hex: "#5B6B69")), lineWidth: 2)
                LabCanvasHelpers.drawLabel(context: context, text: "Air", at: CGPoint(x: blockRect.maxX - 22, y: originPoint.y - 16), size: 10, color: .secondary)
                LabCanvasHelpers.drawLabel(context: context, text: "Glass", at: CGPoint(x: blockRect.maxX - 26, y: originPoint.y + 18), size: 10, color: .secondary)

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
                // Curved angle-indicator arc between the normal and the
                // incident ray — shows *which* angle i refers to, not just
                // its numeric label, matching a real textbook ray diagram.
                LabCanvasHelpers.drawAngleIndicatorArc(
                    context: context, center: originPoint, radius: 26 * zoom,
                    startDeg: 270, endDeg: 270 + lab.angleOfIncidenceDeg,
                    color: Color(hex: "#C0392B"), label: "i"
                )

                if lab.phase == .settingIncidence {
                    LabCanvasHelpers.drawWeight(context: context, center: pointA, radiusPx: 9, color: Color(hex: "#C0392B"))
                }

                // Optical pins A and B along the incident ray — the actual
                // apparatus a real practical uses to fix the ray's path,
                // even though the app already knows the angle exactly.
                // Purely a recognition cue: "this is the optical pins
                // experiment," not something the student interacts with.
                drawPin(context: context, at: CGPoint(x: pointA.x + (originPoint.x - pointA.x) * 0.28, y: pointA.y + (originPoint.y - pointA.y) * 0.28), label: "A", color: Color(hex: "#C0392B"))
                drawPin(context: context, at: CGPoint(x: pointA.x + (originPoint.x - pointA.x) * 0.72, y: pointA.y + (originPoint.y - pointA.y) * 0.72), label: "B", color: Color(hex: "#C0392B"))

                // Refracted ray + protractor: revealed only once the student
                // has locked their angle of incidence and moved to reading.
                if lab.phase == .readingRefraction {
                    // Grow the ray in over ~0.6s rather than snapping it
                    // into place instantly — "red ray touches the
                    // surface, green ray bends into view."
                    let elapsed = lab.refractionRevealStart.map { timeline.date.timeIntervalSince($0) } ?? 1
                    let revealProgress = min(1, max(0, elapsed / 0.6))

                    let rRad = lab.trueRefractionDeg * .pi / 180
                    let pointB = CGPoint(
                        x: originPoint.x + refractedRayLength * CGFloat(sin(rRad)),
                        y: originPoint.y + refractedRayLength * CGFloat(cos(rRad))
                    )
                    let animatedPointB = CGPoint(
                        x: originPoint.x + (pointB.x - originPoint.x) * CGFloat(revealProgress),
                        y: originPoint.y + (pointB.y - originPoint.y) * CGFloat(revealProgress)
                    )
                    var refractedRay = Path()
                    refractedRay.move(to: originPoint)
                    refractedRay.addLine(to: animatedPointB)
                    context.stroke(refractedRay, with: .color(Color(hex: "#2E7D32")), lineWidth: 3)

                    if revealProgress > 0.7 {
                        LabCanvasHelpers.drawAngleIndicatorArc(
                            context: context, center: originPoint, radius: 22 * zoom,
                            startDeg: 90 - lab.trueRefractionDeg, endDeg: 90,
                            color: Color(hex: "#2E7D32"), label: "r"
                        )

                        LabCanvasHelpers.drawProtractorArc(
                            context: context, center: originPoint, radius: protractorRadius,
                            startDeg: 190, endDeg: 350, color: Color(hex: "#8B9997"),
                            minorTickStepDeg: 5
                        )

                        var deg = 190.0
                        while deg <= 350 {
                            if Int(deg) % 10 == 0 {
                                let rad = deg * .pi / 180
                                let labelPoint = CGPoint(
                                    x: originPoint.x + (protractorRadius + 15) * CGFloat(cos(rad)),
                                    y: originPoint.y + (protractorRadius + 15) * CGFloat(sin(rad))
                                )
                                let valueFromNormal = Int(abs(deg - 270).rounded())
                                LabCanvasHelpers.drawLabel(context: context, text: "\(valueFromNormal)\u{00B0}", at: labelPoint, size: 8 * zoom, color: .secondary)
                            }
                            deg += 5
                        }

                        // Optical pins C and D along the refracted ray,
                        // matching pins A/B on the incident ray.
                        drawPin(context: context, at: CGPoint(x: originPoint.x + (pointB.x - originPoint.x) * 0.35, y: originPoint.y + (pointB.y - originPoint.y) * 0.35), label: "C", color: Color(hex: "#2E7D32"))
                        drawPin(context: context, at: CGPoint(x: originPoint.x + (pointB.x - originPoint.x) * 0.78, y: originPoint.y + (pointB.y - originPoint.y) * 0.78), label: "D", color: Color(hex: "#2E7D32"))
                    }
                }

                // Point of incidence O, drawn last so it sits on top of the
                // rays where they meet — exactly how a real exam diagram
                // marks it.
                LabCanvasHelpers.drawWeight(context: context, center: originPoint, radiusPx: 3.5, color: .primary)
                LabCanvasHelpers.drawLabel(context: context, text: "O", at: CGPoint(x: originPoint.x - 14, y: originPoint.y + 12), size: 12, weight: .bold)
                }
            }
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard lab.phase == .settingIncidence else { return }
                        let dx = Double(value.location.x - originPoint.x)
                        // Previously bailed out entirely (no response at
                        // all) for any touch at or below the point of
                        // incidence — a large dead zone across the lower
                        // half of the board where dragging did nothing.
                        // Clamp instead, so every touch on the board
                        // produces a sensible angle rather than silence.
                        let dy = max(Double(originPoint.y - value.location.y), 1)
                        let angle = atan2(dx, dy) * 180 / .pi
                        viewModel.setIncidence(rawAngleDeg: angle)
                    }
            )
        }
    }

    @ViewBuilder
    private var controls: some View {
        if viewModel.result == nil {
            TrialProgressView(completed: viewModel.readings.count, target: RefractionExperimentViewModel.minRecommendedTrials)
        }

        switch viewModel.apparatus.phase {
        case .settingIncidence:
            if let hint = viewModel.setupSpreadHint {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            Button("Trace Ray") { viewModel.confirmIncidence() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        case .readingRefraction:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\u{2713} Measure from the normal, not the surface.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(isZoomed ? "\u{1F50D} Zoom out" : "\u{1F50D} Zoom in to read") {
                        withAnimation { isZoomed.toggle() }
                    }
                    .font(.caption)
                }
                HStack {
                    TextField("Angle of refraction r", text: $viewModel.refractionReadingInput)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .focused($readingFieldFocused)
                    Text("\u{00B0}").foregroundStyle(.secondary)
                }
                if let warning = viewModel.lastReadingWarning {
                    Text(warning)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                Button("Save Reading") {
                    readingFieldFocused = false
                    viewModel.recordReading()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }

        if viewModel.canCalculate && viewModel.result == nil {
            Button("Plot Graph & Calculate n") { viewModel.calculateResult() }
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
