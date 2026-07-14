//
//  LensLabView.swift
//  PhysicsPracticalCoach
//
//  Converging Lens lab experiment, built on the Lab framework (see
//  `PendulumLabView.swift` for the reference template and
//  `LAB_FRAMEWORK.md` for the architecture). Sixth distinct drag mechanic:
//  a two-stage drag per trial along one shared optical-bench axis \u2014 first
//  the lens (sets the object distance u), then the screen (finds the
//  sharply focused image, exactly like a real bracket-method search) \u2014
//  reusing Ohm's Law/Potentiometer's one-axis drag math but applied twice
//  per trial instead of once.
//
//  EXAM DESIGN: mirrors a real WAEC/NECO/IGCSE lens practical \u2014 a lamp
//  and object pin sit at a fixed position, a converging lens of unknown
//  focal length is moved to set u, and the student slides a screen back
//  and forth until the image is "as sharp as possible" (see
//  `AceQuestionBank.lens_ace_01`: sharpness of the image edges is the
//  focus criterion, not size, and the image blurs on both sides of the
//  true position \u2014 the bracket method). That blur is genuinely simulated
//  here (rendered with a real Gaussian blur whose radius grows with
//  distance from the true image position), so the student's own care in
//  finding the sharp point is the actual source of measurement error,
//  never faked or shortcut. At least 5 trials at different u are expected,
//  then the student's own u/v readings are plotted as 1/v vs 1/u \u2014 the
//  exact rearrangement `AceQuestionBank.lens_pdo_01` asks students to
//  derive \u2014 with f found from the reciprocal of the y-intercept.
//

import SwiftUI

// MARK: - 1. Apparatus state (physical simulation only)

@Observable
final class LensLabState {
    enum Phase { case positioningLens, focusingScreen }

    static let benchLengthCm: Double = 100

    /// Hidden true focal length of the converging lens for this session (cm).
    let focalLengthCm: Double

    private(set) var phase: Phase = .positioningLens

    /// Object (illuminated cross-wire) is fixed at the left end of the bench.
    let objectPositionCm: Double = 0

    private(set) var lensPositionCm: Double
    private(set) var screenPositionCm: Double

    private var minLensCm: Double { focalLengthCm + 6 }
    private var maxLensCm: Double { 45 }

    init(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        focalLengthCm = ((rng.nextDouble(8, 16)) * 2).rounded() / 2 // nearest 0.5 cm
        let startFraction = rng.nextDouble(0, 1)
        let minLens = focalLengthCm + 6
        let maxLens: Double = 45
        lensPositionCm = minLens + startFraction * (maxLens - minLens)
        screenPositionCm = min(lensPositionCm + 20, Self.benchLengthCm - 2)
    }

    /// Object distance u \u2014 directly what the student set by dragging the lens.
    var objectDistanceCm: Double { lensPositionCm - objectPositionCm }

    /// True image distance v for the current lens position, from the thin
    /// lens formula 1/f = 1/u + 1/v (guaranteed real, since u > f is
    /// enforced by the drag clamp below).
    var trueImageDistanceCm: Double {
        let u = objectDistanceCm
        return (focalLengthCm * u) / (u - focalLengthCm)
    }

    var trueScreenPositionCm: Double { lensPositionCm + trueImageDistanceCm }

    /// How far the student's screen currently is from the true sharp-focus
    /// position \u2014 drives the blur radius drawn on the image, never shown
    /// as a number, exactly like a real bracket-method search.
    var blurDistanceCm: Double { abs(screenPositionCm - trueScreenPositionCm) }

    func setLensPosition(_ value: Double) {
        lensPositionCm = min(max(value, minLensCm), maxLensCm)
        screenPositionCm = max(screenPositionCm, lensPositionCm + 4)
    }

    func setScreenPosition(_ value: Double) {
        screenPositionCm = min(max(value, lensPositionCm + 4), Self.benchLengthCm - 2)
    }

    func startFocusing() {
        phase = .focusingScreen
    }

    /// Re-arms for another trial at a (potentially) new lens position \u2014
    /// matches a real practical: reposition the lens, then re-search for
    /// focus, exactly as Pendulum re-arms for another timing trial.
    func rearmForNextTrial() {
        phase = .positioningLens
    }
}

// MARK: - 2. Experiment view model (task, trials, grading)

@MainActor
@Observable
final class LensExperimentViewModel {
    private(set) var apparatus: LensLabState
    private let recorder: LabAttemptRecorder

    private(set) var readings: [LabReading] = []
    private(set) var result: LabRunResult?

    private static let minRecommendedTrials = 5
    private static let focalLengthToleranceFraction = 0.15
    private static let gradientTolerance = 0.25 // around the expected -1

    init(recorder: LabAttemptRecorder, seed: Int) {
        self.recorder = recorder
        self.apparatus = LensLabState(seed: seed)
    }

    var instructionText: String {
        switch apparatus.phase {
        case .positioningLens:
            return "Drag the lens to set a new object distance u, different from your other trials."
        case .focusingScreen:
            return "Drag the screen until the image is as sharp as possible \u2014 check it blurs again on both sides (the bracket method), then confirm."
        }
    }

    var sharpnessHint: (text: String, color: Color) {
        let blur = apparatus.blurDistanceCm
        if blur < 1.0 { return ("Sharp focus!", .green) }
        if blur < 4.0 { return ("Getting close \u2014 keep adjusting.", .orange) }
        return ("Blurred \u2014 slide the screen to search for the sharp point.", .secondary)
    }

    func confirmLensPosition() {
        apparatus.startFocusing()
    }

    /// Student taps this the instant the image looks sharpest \u2014 their own
    /// judgement of sharpness IS the measurement, exactly like using a real
    /// screen and metre rule in the exam hall.
    func confirmFocus() {
        let u = apparatus.objectDistanceCm
        let v = apparatus.screenPositionCm - apparatus.lensPositionCm
        readings.append(LabReading(
            trialNumber: readings.count + 1,
            label: "Object distance u", value: (u * 10).rounded() / 10, unit: "cm",
            derivedLabel: "Image distance v", derivedValue: (v * 10).rounded() / 10, derivedUnit: "cm"
        ))
        apparatus.rearmForNextTrial()
    }

    var canCalculate: Bool { readings.count >= 2 }

    func calculateResult() {
        guard canCalculate else { return }
        // 1/v (y) vs 1/u (x) -> gradient \u2248 -1 (a check), y-intercept = 1/f.
        let points = readings.compactMap { reading -> RegressionPoint? in
            guard let v = reading.derivedValue, reading.value > 0, v > 0 else { return nil }
            return RegressionPoint(x: 1 / reading.value, y: 1 / v)
        }
        guard points.count >= 2 else { return }
        let regression = LinearRegression.fit(points)
        let intercept = regression.intercept
        let studentF = intercept > 0 ? 1 / intercept : Double.infinity

        let tolerance = apparatus.focalLengthCm * Self.focalLengthToleranceFraction
        let fCorrect = studentF.isFinite && abs(studentF - apparatus.focalLengthCm) <= tolerance
        let gradientCorrect = abs(regression.slope - (-1)) <= Self.gradientTolerance

        var feedback: [String] = []
        if studentF.isFinite {
            feedback.append("Your focal length from the graph (f = 1 \u00F7 y-intercept): \(format(studentF)) cm.")
        } else {
            feedback.append("Your line's y-intercept wasn't usable to find f \u2014 check your 1/u and 1/v values are calculated correctly.")
        }
        feedback.append("Accepted range: \(format(apparatus.focalLengthCm - tolerance))\u{2013}\(format(apparatus.focalLengthCm + tolerance)) cm.")
        feedback.append("Your line's gradient: \(format(regression.slope)) (expected \u2248 \u22121 \u2014 this is a check on your readings, not the answer).")
        if !gradientCorrect {
            feedback.append("A gradient far from \u22121 usually means one or more (u, v) pairs weren't actually at sharp focus \u2014 re-check those trials.")
        }
        if readings.count < Self.minRecommendedTrials {
            feedback.append("Real exams expect at least \(Self.minRecommendedTrials) trials at different object distances, spread across the bench \u2014 try recording more.")
        }

        let correct = fCorrect
        let score: Int
        if correct {
            score = 100
        } else if gradientCorrect {
            score = 60 // readings were internally consistent, just off from the true f
        } else {
            score = 40
        }

        let outcome = LabRunResult(
            correct: correct,
            score: score,
            feedback: feedback,
            examTip: "Plot 1/v (y) against 1/u (x) \u2014 the gradient should come out close to \u22121 as a check, and the y-intercept equals 1/f, so f = 1 \u00F7 intercept. Judge focus by sharpness of the image edges, not by its size \u2014 bracket the sharp point by moving the screen past it in both directions."
        )
        result = outcome
        recorder.record(experimentTitle: SimulationType.lensFocusing.label, result: outcome)
    }

    var studentDataset: GraphDataset {
        let points = readings.compactMap { reading -> GraphPoint? in
            guard let v = reading.derivedValue, reading.value > 0, v > 0 else { return nil }
            return GraphPoint(x: 1 / reading.value, y: 1 / v)
        }
        return GraphDataset(type: .reciprocalLensDistances, seed: 0, points: points, expectedGradient: -1)
    }

    func newTask() {
        var rng = SeededRandomNumberGenerator(seed: Int.random(in: 0...Int(Int32.max)))
        apparatus = LensLabState(seed: rng.nextInt(0, Int(Int32.max)))
        readings = []
        result = nil
    }

    private func format(_ value: Double) -> String { String(format: "%.2f", value) }
}

// MARK: - View

struct LensLabView: View {
    let curriculum: Curriculum
    @State private var viewModel: LensExperimentViewModel

    init(curriculum: Curriculum, repository: AttemptRepository) {
        self.curriculum = curriculum
        _viewModel = State(initialValue: LensExperimentViewModel(
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum),
            seed: Int.random(in: 0...Int(Int32.max))
        ))
    }

    var body: some View {
        LabScaffoldView(
            title: "Lens Lab",
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
            let leftX: CGFloat = 24
            let benchWidthPx = geo.size.width - leftX - 24
            let benchY = geo.size.height * 0.5
            let pxPerCm = benchWidthPx / LensLabState.benchLengthCm
            let lab = viewModel.apparatus

            func x(_ cm: Double) -> CGFloat { leftX + CGFloat(cm) * pxPerCm }

            Canvas { context, _ in
                var bench = Path()
                bench.move(to: CGPoint(x: leftX, y: benchY))
                bench.addLine(to: CGPoint(x: leftX + benchWidthPx, y: benchY))
                context.stroke(bench, with: .color(Color(hex: "#8B9997")), lineWidth: 3)

                LabCanvasHelpers.drawHorizontalRuler(
                    context: context, originY: benchY + 8, leftX: leftX, widthPx: benchWidthPx,
                    maxValue: LensLabState.benchLengthCm, minorStep: 5
                )
                LabCanvasHelpers.drawLabel(
                    context: context, text: "distance along bench / cm",
                    at: CGPoint(x: leftX + benchWidthPx / 2, y: benchY + 46), size: 10, color: .secondary
                )

                // Object: fixed upward arrow at the origin.
                let objX = x(lab.objectPositionCm)
                var objectArrow = Path()
                objectArrow.move(to: CGPoint(x: objX, y: benchY))
                objectArrow.addLine(to: CGPoint(x: objX, y: benchY - 34))
                context.stroke(objectArrow, with: .color(Color(hex: "#D98B36")), lineWidth: 3)
                var objHead = Path()
                objHead.move(to: CGPoint(x: objX - 5, y: benchY - 28))
                objHead.addLine(to: CGPoint(x: objX, y: benchY - 34))
                objHead.addLine(to: CGPoint(x: objX + 5, y: benchY - 28))
                context.stroke(objHead, with: .color(Color(hex: "#D98B36")), lineWidth: 3)
                LabCanvasHelpers.drawLabel(context: context, text: "Object", at: CGPoint(x: objX, y: benchY - 46), size: 10)

                // Lens: vertical line with two convex arcs.
                let lensX = x(lab.lensPositionCm)
                var lensBody = Path()
                lensBody.move(to: CGPoint(x: lensX, y: benchY - 44))
                lensBody.addQuadCurve(to: CGPoint(x: lensX, y: benchY + 44), control: CGPoint(x: lensX + 10, y: benchY))
                lensBody.move(to: CGPoint(x: lensX, y: benchY - 44))
                lensBody.addQuadCurve(to: CGPoint(x: lensX, y: benchY + 44), control: CGPoint(x: lensX - 10, y: benchY))
                context.stroke(lensBody, with: .color(Color(hex: "#0F5A4F")), lineWidth: 3)
                LabCanvasHelpers.drawLabel(
                    context: context, text: String(format: "u = %.1f cm", lab.objectDistanceCm),
                    at: CGPoint(x: lensX, y: benchY - 58), size: 12, weight: .semibold
                )

                // Screen: a small rectangle, only meaningfully positioned once focusing has begun.
                let screenX = x(lab.screenPositionCm)
                let screenRect = CGRect(x: screenX - 3, y: benchY - 38, width: 6, height: 76)
                context.fill(Path(screenRect), with: .color(Color(hex: "#5B6B69")))
                if lab.phase == .focusingScreen {
                    LabCanvasHelpers.drawLabel(
                        context: context, text: String(format: "v = %.1f cm", lab.screenPositionCm - lab.lensPositionCm),
                        at: CGPoint(x: screenX, y: benchY - 52), size: 12, weight: .semibold
                    )
                }

                // Image: an inverted arrow at the TRUE image position, blurred by
                // how far the student's screen currently is from that position \u2014
                // a real bracket-method visual, not a faked hint.
                if lab.phase == .focusingScreen {
                    let imgX = x(lab.trueScreenPositionCm)
                    let blurRadius = min(lab.blurDistanceCm * 0.6, 16)
                    context.drawLayer { layer in
                        layer.addFilter(.blur(radius: blurRadius))
                        var image = Path()
                        image.move(to: CGPoint(x: imgX, y: benchY))
                        image.addLine(to: CGPoint(x: imgX, y: benchY + 30))
                        layer.stroke(image, with: .color(Color(hex: "#C0392B")), lineWidth: 3)
                        var imgHead = Path()
                        imgHead.move(to: CGPoint(x: imgX - 5, y: benchY + 24))
                        imgHead.addLine(to: CGPoint(x: imgX, y: benchY + 30))
                        imgHead.addLine(to: CGPoint(x: imgX + 5, y: benchY + 24))
                        layer.stroke(imgHead, with: .color(Color(hex: "#C0392B")), lineWidth: 3)
                    }
                }
            }
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let cm = Double((value.location.x - leftX) / pxPerCm)
                        switch lab.phase {
                        case .positioningLens: lab.setLensPosition(cm)
                        case .focusingScreen: lab.setScreenPosition(cm)
                        }
                    }
            )
        }
    }

    @ViewBuilder
    private var controls: some View {
        switch viewModel.apparatus.phase {
        case .positioningLens:
            Button("Confirm lens position \u2014 focus the screen") { viewModel.confirmLensPosition() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        case .focusingScreen:
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.sharpnessHint.text)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(viewModel.sharpnessHint.color)
                Button("Confirm sharp focus \u2014 record trial") { viewModel.confirmFocus() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            }
        }

        if viewModel.canCalculate && viewModel.result == nil {
            Button("Calculate focal length f") { viewModel.calculateResult() }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
        }

        if viewModel.result != nil {
            ScatterPlotCanvasView(dataset: viewModel.studentDataset, definition: GraphCoachType.reciprocalLensDistances.definition)
                .frame(height: 200)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Button("New task") { viewModel.newTask() }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
        }
    }
}
