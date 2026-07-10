//
//  SpringLabView.swift
//  PhysicsPracticalCoach
//
//  Hooke's Law lab experiment, built on the Lab framework (see
//  `PendulumLabView.swift` for the reference template and
//  `LAB_FRAMEWORK.md` for the architecture). Demonstrates a new drag
//  mechanic (drag a mass upward onto the hook) and reuses the Graph Coach
//  engine (`LinearRegression` + `ScatterPlotCanvasView` + the existing
//  `.forceExtension` graph definition) for the final F-x graph, since a
//  spring's own graph IS that type already defined elsewhere — no duplicate
//  plotting code needed.
//

import SwiftUI

// MARK: - 1. Apparatus state

@Observable
final class SpringLabState {
    private static let gravity = 9.81

    /// Hidden true spring constant for this session (N/m).
    let trueK: Double
    /// Currently loaded mass in kg (0 = nothing hung yet).
    private(set) var loadedMassKg: Double = 0
    private(set) var settleStartTime: Date?

    /// True (physics) extension for the current load, in metres.
    var trueExtensionM: Double { (loadedMassKg * Self.gravity) / trueK }

    init(seed: Int) {
        var rng = SeededRandomNumberGenerator(seed: seed)
        trueK = ((rng.nextDouble(15, 45)) * 10).rounded() / 10 // N/m, 1 d.p.
    }

    func loadMass(kg: Double) {
        loadedMassKg = kg
        settleStartTime = Date()
    }

    /// Damped-oscillation wobble on top of the true extension, purely for
    /// the visual settle animation — decays to ~0 within about 2 seconds,
    /// same "physically real, not a canned loop" principle as Pendulum.
    func animatedExtensionM(at now: Date) -> Double {
        guard let settleStartTime else { return trueExtensionM }
        let elapsed = now.timeIntervalSince(settleStartTime)
        guard elapsed < 2.0 else { return trueExtensionM }
        let decay = exp(-elapsed * 3.0)
        let wobble = sin(elapsed * 18.0) * decay * 0.015
        return trueExtensionM + wobble
    }
}

// MARK: - 2. Experiment view model

@MainActor
@Observable
final class SpringExperimentViewModel {
    private(set) var apparatus: SpringLabState
    private let recorder: LabAttemptRecorder

    let availableMassesG: [Double] = [50, 100, 150, 200, 250]
    private(set) var usedMasses: Set<Double> = []
    private(set) var readings: [LabReading] = []
    private(set) var result: LabRunResult?
    var pendingReadingInput: String = ""
    private(set) var awaitingReading = false

    init(recorder: LabAttemptRecorder, seed: Int) {
        self.recorder = recorder
        self.apparatus = SpringLabState(seed: seed)
    }

    var instructionText: String {
        if awaitingReading {
            return "Wait for the spring to settle, then read the extension off the ruler and enter it below."
        }
        if usedMasses.isEmpty {
            return "Drag a mass upward onto the hook to load the spring."
        }
        return "Drag another mass onto the hook, or calculate your result once you have enough trials."
    }

    func loadMass(_ grams: Double) {
        apparatus.loadMass(kg: grams / 1000.0)
        usedMasses.insert(grams)
        awaitingReading = true
    }

    func submitReading() {
        guard let value = Double(pendingReadingInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")) else { return }
        let load = apparatus.loadedMassKg * 9.81
        readings.append(LabReading(
            trialNumber: readings.count + 1,
            label: "Load F", value: (load * 1000).rounded() / 1000, unit: "N",
            derivedLabel: "Extension x", derivedValue: value, derivedUnit: "m"
        ))
        pendingReadingInput = ""
        awaitingReading = false
    }

    var canCalculate: Bool { readings.count >= 2 }

    func calculateResult() {
        guard canCalculate else { return }
        let points = readings.compactMap { reading -> RegressionPoint? in
            guard let x = reading.derivedValue else { return nil }
            return RegressionPoint(x: x, y: reading.value)
        }
        let regression = LinearRegression.fit(points)
        let studentK = regression.slope
        let tolerance = apparatus.trueK * 0.12
        let correct = abs(studentK - apparatus.trueK) <= tolerance

        var feedback: [String] = []
        feedback.append("Your gradient (spring constant k): \(format(studentK)) N/m.")
        feedback.append("Accepted range: \(format(apparatus.trueK - tolerance))\u{2013}\(format(apparatus.trueK + tolerance)) N/m.")
        if readings.count < 5 {
            feedback.append("Real exams expect at least 5 load values \u{2014} try adding more masses next time.")
        }

        let outcome = LabRunResult(
            correct: correct,
            score: correct ? 100 : 45,
            feedback: feedback,
            examTip: "Plot F (y) against x (x) \u{2014} k is the gradient directly, since F = kx. Use a large triangle on the best-fit line, not two adjacent points."
        )
        result = outcome
        recorder.record(experimentTitle: SimulationType.springExtension.label, result: outcome)
    }

    /// Chart of the student's own recorded readings, reusing the exact
    /// Graph Coach scatter plot + Force-vs-Extension axis definition.
    var studentDataset: GraphDataset {
        let points = readings.compactMap { reading -> GraphPoint? in
            guard let x = reading.derivedValue else { return nil }
            return GraphPoint(x: x, y: reading.value)
        }
        return GraphDataset(type: .forceExtension, seed: 0, points: points, expectedGradient: apparatus.trueK)
    }

    func newTask() {
        var rng = SeededRandomNumberGenerator(seed: Int.random(in: 0...Int(Int32.max)))
        apparatus = SpringLabState(seed: rng.nextInt(0, Int(Int32.max)))
        readings = []
        usedMasses = []
        result = nil
        pendingReadingInput = ""
        awaitingReading = false
    }

    private func format(_ value: Double) -> String { String(format: "%.2f", value) }
}

// MARK: - View

struct SpringLabView: View {
    let curriculum: Curriculum
    @State private var viewModel: SpringExperimentViewModel
    @FocusState private var readingFieldFocused: Bool

    init(curriculum: Curriculum, repository: AttemptRepository) {
        self.curriculum = curriculum
        _viewModel = State(initialValue: SpringExperimentViewModel(
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum),
            seed: Int.random(in: 0...Int(Int32.max))
        ))
    }

    var body: some View {
        LabScaffoldView(
            title: "Hooke's Law Lab",
            instructionText: viewModel.instructionText,
            apparatusHeight: 380,
            readings: viewModel.readings,
            result: viewModel.result,
            apparatus: { apparatusArea },
            controls: { controls }
        )
    }

    private var apparatusArea: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { geo in
                let pivot = CGPoint(x: geo.size.width / 2, y: 24)
                let rulerBottom = geo.size.height - 90
                let pxPerMetre: CGFloat = (rulerBottom - pivot.y - 40) / 0.3 // spring can extend up to ~0.3 m visually
                let extensionM = viewModel.apparatus.animatedExtensionM(at: timeline.date)
                let bottomY = pivot.y + 40 + CGFloat(extensionM) * pxPerMetre

                Canvas { context, _ in
                    LabCanvasHelpers.drawVerticalRuler(
                        context: context, originX: pivot.x + 60, topY: pivot.y,
                        heightPx: rulerBottom - pivot.y, maxValue: 0.30, minorStep: 0.01
                    )

                    // Spring: drawn as a zig-zag path from pivot to bottom hook.
                    var spring = Path()
                    spring.move(to: pivot)
                    let coils = 10
                    let coilWidth: CGFloat = 14
                    for i in 0...coils {
                        let t = CGFloat(i) / CGFloat(coils)
                        let y = pivot.y + t * (bottomY - pivot.y)
                        let x = pivot.x + (i % 2 == 0 ? -coilWidth : coilWidth)
                        spring.addLine(to: CGPoint(x: x, y: y))
                    }
                    spring.addLine(to: CGPoint(x: pivot.x, y: bottomY))
                    context.stroke(spring, with: .color(Color(hex: "#0F5A4F")), lineWidth: 2.5)

                    if viewModel.apparatus.loadedMassKg > 0 {
                        LabCanvasHelpers.drawWeight(context: context, center: CGPoint(x: pivot.x, y: bottomY + 16), radiusPx: 16, color: Color(hex: "#D98B36"))
                        LabCanvasHelpers.drawLabel(
                            context: context,
                            text: "\(Int(viewModel.apparatus.loadedMassKg * 1000)) g",
                            at: CGPoint(x: pivot.x, y: bottomY + 16), size: 11, color: .white
                        )
                    }

                    LabCanvasHelpers.drawLabel(
                        context: context,
                        text: viewModel.usedMasses.isEmpty ? "No load" : "Loaded",
                        at: CGPoint(x: pivot.x, y: pivot.y - 12), size: 12
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        if viewModel.awaitingReading {
            HStack {
                TextField("Extension reading", text: $viewModel.pendingReadingInput)
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
        } else if viewModel.result == nil {
            Text("Available masses").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            HStack(spacing: 10) {
                ForEach(viewModel.availableMassesG, id: \.self) { grams in
                    DraggableMassChip(grams: grams, isUsed: viewModel.usedMasses.contains(grams)) {
                        viewModel.loadMass(grams)
                    }
                }
            }
            if viewModel.canCalculate {
                Button("Calculate spring constant k") { viewModel.calculateResult() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            }
        }

        if viewModel.result != nil {
            ScatterPlotCanvasView(dataset: viewModel.studentDataset, definition: GraphCoachType.forceExtension.definition)
                .frame(height: 200)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Button("New task") { viewModel.newTask() }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
        }
    }
}

/// A mass the student drags upward onto the spring's hook. Success is
/// judged by drag distance (dragged up past a threshold), not by precise
/// hit-testing against the Canvas-rendered hook position — a deliberately
/// simple, robust gesture rather than fragile pixel-perfect drop detection.
private struct DraggableMassChip: View {
    let grams: Double
    let isUsed: Bool
    let onLoaded: () -> Void

    @State private var dragOffset: CGSize = .zero

    private static let loadThreshold: CGFloat = -70

    var body: some View {
        Circle()
            .fill(isUsed ? Color.gray.opacity(0.3) : Color(hex: "#D98B36"))
            .frame(width: 44, height: 44)
            .overlay {
                Text("\(Int(grams))g")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .offset(dragOffset)
            .opacity(isUsed ? 0.4 : 1)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard !isUsed else { return }
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        guard !isUsed else { return }
                        if value.translation.height <= Self.loadThreshold {
                            onLoaded()
                        }
                        withAnimation(.spring(response: 0.3)) {
                            dragOffset = .zero
                        }
                    }
            )
            .allowsHitTesting(!isUsed)
    }
}
