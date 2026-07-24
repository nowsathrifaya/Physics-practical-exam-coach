//
//  CoolingCurveLabView.swift
//  PhysicsPracticalCoach
//
//  Cooling curve lab experiment, built on the Lab framework (see
//  `PendulumLabView.swift` for the reference template and
//  `LAB_FRAMEWORK.md` for the architecture). Converted next among the
//  remaining `GenericSimulationView` placeholders — the last one with a
//  meaningful "next" left after Vernier Caliper, leaving only Filament Lamp.
//
//  Tenth drag mechanic — except there isn't one. This is the first Lab
//  experiment driven entirely by real wall-clock time with no drag gesture
//  at all: a substance (molten wax/naphthalene-style) is already cooling
//  when the student starts the timer, and their only physical action is
//  tapping "Record reading" at moments of their own choosing, then reading
//  the thermometer (reusing `ThermometerCanvasView` from
//  `ApparatusVisuals.swift`, the same "reuse an apparatus renderer wholesale"
//  move Vernier Caliper made) exactly as it stands at that instant — no
//  freezing, hinting, or auto-capture of the true value.
//
//  The physics is genuinely a combined Newton's-law-of-cooling + isothermal
//  plateau model (liquid cools exponentially -> temperature holds constant
//  at the freezing point while latent heat is released during
//  solidification -> solid resumes cooling exponentially), not a fake
//  linear ramp. Nothing tells the student when the plateau starts or ends;
//  they only discover it because two readings taken a while apart come back
//  suspiciously close together — exactly how a real cooling-curve practical
//  reveals the freezing point, and the direct real-world basis for the
//  standard exam question "from your graph/table, state the freezing point
//  of the substance."
//
//  Deliberately NOT built on `GraphDatasetGenerator`/`LinearRegression`
//  unlike every other graph-adjacent Lab so far: a cooling curve is not a
//  straight line, so "gradient" has no meaning here. The graded quantity is
//  the freezing point the student reads off their own data, not a slope.
//

import SwiftUI

// MARK: - 1. Apparatus state

@Observable
final class CoolingCurveLabState {
    /// Ambient/room temperature the substance cools toward (deg C).
    let roomTempC: Double
    /// Starting (already-molten) temperature when the timer begins (deg C).
    let startTempC: Double
    /// Hidden freezing/solidification point (deg C) — the quantity the
    /// student is ultimately asked to state.
    let freezingPointC: Double
    /// Newton's-law cooling rate constant (per second), shared by the
    /// pre-freeze liquid phase and the post-freeze solid phase for
    /// simplicity — real liquids and solids of the same substance cool at
    /// only slightly different rates, and the shared constant keeps the
    /// model's one genuinely important feature (the plateau) unambiguous.
    let coolingConstantPerS: Double
    /// How long the substance sits at the freezing point releasing latent
    /// heat before resuming cooling (s).
    let plateauDurationS: Double

    private(set) var timerStartTime: Date?

    var timerRunning: Bool { timerStartTime != nil }

    init(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        roomTempC = rng.nextDouble(24, 30).rounded()
        startTempC = rng.nextDouble(82, 95).rounded()
        freezingPointC = rng.nextDouble(45, 65).rounded()
        coolingConstantPerS = ((rng.nextDouble(0.020, 0.035)) * 1000).rounded() / 1000
        plateauDurationS = rng.nextDouble(20, 35).rounded()
    }

    /// Elapsed seconds from timer start to the moment the (still-liquid)
    /// substance's exponential cooling first reaches the freezing point —
    /// derived from Newton's law of cooling, not a separately chosen value,
    /// so it stays physically consistent with `roomTempC`/`startTempC`/
    /// `coolingConstantPerS`.
    var plateauStartS: Double {
        let ratio = (freezingPointC - roomTempC) / (startTempC - roomTempC)
        return -log(ratio) / coolingConstantPerS
    }

    var plateauEndS: Double { plateauStartS + plateauDurationS }

    /// The true temperature at a given elapsed time — exponential decay
    /// toward room temperature, holding constant during the plateau, then
    /// exponential decay again. Never exposed as text anywhere in the UI;
    /// only ever rendered as a thermometer column height, exactly like
    /// every other "read it yourself" instrument in the app.
    func trueTempC(atElapsedS t: Double) -> Double {
        if t <= plateauStartS {
            return roomTempC + (startTempC - roomTempC) * exp(-coolingConstantPerS * t)
        } else if t <= plateauEndS {
            return freezingPointC
        } else {
            return roomTempC + (freezingPointC - roomTempC) * exp(-coolingConstantPerS * (t - plateauEndS))
        }
    }

    func startTimer() {
        timerStartTime = Date()
    }

    /// Wall-clock seconds since the timer started — the raw value a
    /// student's "record reading" tap captures, same convention as
    /// Pendulum's `elapsedSinceRelease`.
    func elapsed(at now: Date) -> Double {
        guard let timerStartTime else { return 0 }
        return now.timeIntervalSince(timerStartTime)
    }
}

// MARK: - 2. Experiment view model

@MainActor
@Observable
final class CoolingCurveExperimentViewModel {
    private(set) var apparatus: CoolingCurveLabState
    private let recorder: LabAttemptRecorder

    private(set) var readings: [LabReading] = []
    private(set) var result: LabRunResult?
    var tempInput: String = ""
    var freezingPointAnswerInput: String = ""

    /// Elapsed time captured the instant "Record reading" was tapped —
    /// freezes the thermometer display so the student can read it without
    /// racing the clock, exactly like pausing to read a real instrument.
    private(set) var pendingElapsedS: Double?

    private static let minReadingsForGoodCredit = 8
    private static let minReadingsToFinish = 4
    private static let tempToleranceC = 1.5
    private static let freezingPointToleranceC = 2.0

    /// Optional hook for the Virtual Lab Experiment workflow wrapper — fires
    /// once after `calculateResult()` sets `result`. Nil by default, so
    /// existing standalone `CoolingCurveLabView` usage behaves exactly as before;
    /// only the new wrapping workflow sets this.
    var onFinished: ((LabRunResult) -> Void)?

    init(recorder: LabAttemptRecorder, seed: Int) {
        self.recorder = recorder
        self.apparatus = CoolingCurveLabState(seed: seed)
    }

    var instructionText: String {
        if result != nil {
            return "Session complete. Start a new task to cool a different substance."
        }
        if !apparatus.timerRunning {
            return "Start the timer, then record the temperature at regular intervals as the substance cools."
        }
        if pendingElapsedS != nil {
            return "Read the thermometer now and enter your temperature."
        }
        if readings.count >= Self.minReadingsToFinish {
            return "Keep recording at regular intervals, or finish and state the freezing point from your own data."
        }
        return "Tap \u{201C}Record reading\u{201D} at a regular interval (roughly every 10\u{2013}15 s) and read the thermometer."
    }

    func startTimer() {
        apparatus.startTimer()
    }

    func captureReading(at now: Date) {
        guard apparatus.timerRunning, pendingElapsedS == nil else { return }
        pendingElapsedS = apparatus.elapsed(at: now)
    }

    /// The temperature to actually render on the thermometer right now —
    /// frozen at the captured instant while awaiting a typed reading,
    /// otherwise live and following wall-clock time.
    func displayTempC(at now: Date) -> Double {
        let t = pendingElapsedS ?? apparatus.elapsed(at: now)
        return apparatus.trueTempC(atElapsedS: t)
    }

    func confirmTempReading() {
        guard
            let elapsed = pendingElapsedS,
            let temp = Double(tempInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
        else { return }
        SoundManager.shared.play(.measurement)
        readings.append(LabReading(
            trialNumber: readings.count + 1,
            label: "t = \(Int(elapsed.rounded())) s", value: elapsed, unit: "s",
            derivedLabel: "Temperature", derivedValue: temp, derivedUnit: "\u{00B0}C"
        ))
        pendingElapsedS = nil
        tempInput = ""
    }

    func cancelPendingReading() {
        pendingElapsedS = nil
        tempInput = ""
    }

    var canFinish: Bool { readings.count >= Self.minReadingsToFinish }

    func calculateResult() {
        guard
            canFinish,
            let studentFreezingPoint = Double(freezingPointAnswerInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
        else { return }

        let perReadingCorrectCount = readings.filter {
            guard let temp = $0.derivedValue else { return false }
            return abs(temp - apparatus.trueTempC(atElapsedS: $0.value)) <= Self.tempToleranceC
        }.count

        let freezingPointCorrect = abs(studentFreezingPoint - apparatus.freezingPointC) <= Self.freezingPointToleranceC
        let majorityReadingsCorrect = perReadingCorrectCount * 2 >= readings.count

        var feedback: [String] = []
        feedback.append("\(perReadingCorrectCount) of \(readings.count) individual temperature readings were within tolerance.")
        feedback.append("Your stated freezing point: \(format(studentFreezingPoint)) \u{00B0}C.")
        feedback.append("Accepted range: \(format(apparatus.freezingPointC - Self.freezingPointToleranceC))\u{2013}\(format(apparatus.freezingPointC + Self.freezingPointToleranceC)) \u{00B0}C.")
        if readings.count < Self.minReadingsForGoodCredit {
            feedback.append("Real exams expect at least \(Self.minReadingsForGoodCredit) readings at regular intervals to plot a convincing curve \u{2014} try recording more next time.")
        }
        let hasBeforePlateau = readings.contains { $0.value < apparatus.plateauStartS }
        let hasAfterPlateau = readings.contains { $0.value > apparatus.plateauEndS }
        if !hasBeforePlateau || !hasAfterPlateau {
            feedback.append("Try to keep recording from before any plateau appears in your data until well after it ends \u{2014} the shape before and after is what confirms a genuine freezing point, not just a pause in your timing.")
        }

        let correct = freezingPointCorrect && majorityReadingsCorrect
        let outcome = LabRunResult(
            correct: correct,
            score: correct ? 100 : (freezingPointCorrect ? 70 : 40),
            feedback: feedback,
            examTip: "Plot temperature (y) against time (x). Where the line goes flat, the substance is solidifying and releasing latent heat at a constant rate \u{2014} that flat temperature is the freezing point, read directly off the y-axis, not the time axis."
        )
        result = outcome
        recorder.record(experimentTitle: SimulationType.coolingCurve.label, result: outcome)
        onFinished?(outcome)
    }

    func newTask() {
        var rng = SeededRandomNumberGenerator(seed: Int.random(in: 0...Int(Int32.max)))
        apparatus = CoolingCurveLabState(seed: rng.nextInt(0, Int(Int32.max)))
        readings = []
        result = nil
        tempInput = ""
        freezingPointAnswerInput = ""
        pendingElapsedS = nil
    }

    private func format(_ value: Double) -> String { String(format: "%.1f", value) }
}

// MARK: - View

struct CoolingCurveLabView: View {
    let curriculum: Curriculum
    @State private var viewModel: CoolingCurveExperimentViewModel
    @FocusState private var fieldFocused: Bool

    init(curriculum: Curriculum, repository: AttemptRepository, onFinished: ((LabRunResult) -> Void)? = nil) {
        self.curriculum = curriculum
        let model = CoolingCurveExperimentViewModel(
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum),
            seed: Int.random(in: 0...Int(Int32.max))
        )
        model.onFinished = onFinished
        _viewModel = State(initialValue: model)
    }

    var body: some View {
        LabScaffoldView(
            title: "Cooling Curve Lab",
            instructionText: viewModel.instructionText,
            apparatusHeight: 320,
            readings: viewModel.readings,
            result: viewModel.result,
            apparatus: { apparatusArea },
            controls: { controls }
        )
    }

    private var apparatusArea: some View {
        TimelineView(.animation(paused: !viewModel.apparatus.timerRunning || viewModel.pendingElapsedS != nil)) { timeline in
            let currentTempC = viewModel.displayTempC(at: timeline.date)
            VStack(spacing: 10) {
                ZStack {
                    BoilingTubeBackdrop(currentTempC: currentTempC, freezingPointC: viewModel.apparatus.freezingPointC)
                    ThermometerCanvasView(
                        bulbTempC: currentTempC,
                        scaleMinC: 0, scaleMaxC: 100
                    )
                }
                .frame(height: 240)

                if viewModel.apparatus.timerRunning {
                    Text(String(format: "t = %.0f s", viewModel.pendingElapsedS ?? viewModel.apparatus.elapsed(at: timeline.date)))
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    Text("Timer not started")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 8)
        }
    }
}

/// The actual experimental setup a cooling-curve practical uses — a
/// boiling tube of substance with a thermometer through a cork — drawn
/// behind `ThermometerCanvasView` so the apparatus reads as "a substance
/// cooling in a tube," not a thermometer floating in space. The
/// substance's fill visibly changes from molten (translucent amber) to
/// solid (opaque, crystalline) as it crosses the freezing point, which is
/// itself a physically-accurate cue students can use alongside the
/// thermometer reading.
private struct BoilingTubeBackdrop: View {
    let currentTempC: Double
    let freezingPointC: Double

    var body: some View {
        Canvas { context, size in
            let cx = size.width * 0.36
            let tubeWidth: CGFloat = 46
            let topY: CGFloat = 30
            let bottomY = size.height - 20
            let tubeRect = CGRect(x: cx - tubeWidth / 2, y: topY, width: tubeWidth, height: bottomY - topY)

            // Rounded-bottom boiling tube outline.
            var tube = Path()
            tube.move(to: CGPoint(x: tubeRect.minX, y: tubeRect.minY))
            tube.addLine(to: CGPoint(x: tubeRect.minX, y: tubeRect.maxY - tubeWidth / 2))
            tube.addArc(center: CGPoint(x: cx, y: tubeRect.maxY - tubeWidth / 2), radius: tubeWidth / 2, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            tube.addLine(to: CGPoint(x: tubeRect.maxX, y: tubeRect.minY))

            let isSolid = currentTempC < freezingPointC
            let substanceColor = isSolid ? Color(hex: "#EDE6D6") : Color(hex: "#E8A33D")
            context.fill(tube, with: .color(substanceColor.opacity(isSolid ? 0.85 : 0.5)))
            context.stroke(tube, with: .color(Color(hex: "#8B9997")), lineWidth: 2)

            // A few crystalline streaks once solidified — the one visual
            // tell, alongside the thermometer, that the plateau has ended.
            if isSolid {
                var streaks = Path()
                for i in 0..<4 {
                    let x = tubeRect.minX + tubeRect.width * (CGFloat(i) + 0.5) / 4
                    streaks.move(to: CGPoint(x: x, y: tubeRect.minY + 10))
                    streaks.addLine(to: CGPoint(x: x, y: tubeRect.maxY - 12))
                }
                context.stroke(streaks, with: .color(.white.opacity(0.5)), lineWidth: 1)
            }

            // Cork stopper with a notch for the thermometer to pass through.
            let corkRect = CGRect(x: cx - tubeWidth / 2 - 3, y: topY - 14, width: tubeWidth + 6, height: 16)
            context.fill(Path(roundedRect: corkRect, cornerRadius: 3), with: .color(Color(hex: "#B5895B")))
            context.stroke(Path(roundedRect: corkRect, cornerRadius: 3), with: .color(Color(hex: "#8A6A42")), lineWidth: 1)

            LabCanvasHelpers.drawLabel(context: context, text: isSolid ? "Solid" : "Liquid", at: CGPoint(x: cx, y: bottomY + 12), size: 10, color: .secondary)
        }
    }
}

extension CoolingCurveLabView {
    @ViewBuilder
    var controls: some View {
        if !viewModel.apparatus.timerRunning {
            Button("Start timer") { viewModel.startTimer() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        } else if viewModel.result == nil {
            if viewModel.pendingElapsedS != nil {
                HStack {
                    TextField("Temperature", text: $viewModel.tempInput)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .focused($fieldFocused)
                    Text("\u{00B0}C").foregroundStyle(.secondary)
                }
                HStack(spacing: 12) {
                    Button("Cancel") {
                        fieldFocused = false
                        viewModel.cancelPendingReading()
                    }
                    .buttonStyle(.bordered)
                    Button("Confirm reading") {
                        fieldFocused = false
                        viewModel.confirmTempReading()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
            } else {
                Button("Record reading") { viewModel.captureReading(at: Date()) }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)

                if viewModel.canFinish {
                    HStack {
                        TextField("Your freezing point", text: $viewModel.freezingPointAnswerInput)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .focused($fieldFocused)
                        Text("\u{00B0}C").foregroundStyle(.secondary)
                    }
                    Button("Calculate result") {
                        fieldFocused = false
                        viewModel.calculateResult()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
            }
        }

        if viewModel.result != nil {
            Button("New task") { viewModel.newTask() }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
        }
    }
}
