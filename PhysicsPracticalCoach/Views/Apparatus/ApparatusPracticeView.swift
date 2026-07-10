//
//  ApparatusPracticeView.swift
//  PhysicsPracticalCoach
//
//  Replaces `ApparatusPracticeFragment.kt` + its companion `ui.apparatus.*View`
//  Android custom Views. Generates a question via `ApparatusTrainer`, renders
//  the instrument with a native SwiftUI `Canvas`, takes the student's typed
//  reading, marks it, and records the attempt via `AttemptRepository` —
//  exactly the same flow as Android, redrawn with HIG-native controls
//  (a form-style numeric field, a prominent submit button, and a bottom
//  sheet–style feedback card instead of a fragment transaction).
//

import SwiftUI

@MainActor
@Observable
final class ApparatusPracticeViewModel {
    private let trainer = ApparatusTrainer()
    private let repository: AttemptRepository
    let apparatusType: ApparatusType
    let curriculum: Curriculum

    private(set) var question: ApparatusQuestion
    var studentInput: String = ""
    private(set) var result: ApparatusMarkResult?

    init(apparatusType: ApparatusType, curriculum: Curriculum, repository: AttemptRepository) {
        self.apparatusType = apparatusType
        self.curriculum = curriculum
        self.repository = repository
        self.question = trainer.question(type: apparatusType, seed: Int.random(in: 0...Int(Int32.max)), curriculum: curriculum)
    }

    func submit(onSaved: () -> Void) {
        let reading = Double(studentInput.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
        let outcome = trainer.mark(question: question, studentReading: reading)
        result = outcome
        repository.save(
            curriculum: curriculum,
            mode: .apparatusPractice,
            target: apparatusType.label,
            score: outcome.score,
            maxScore: 100,
            feedback: outcome.feedback
        )
        onSaved()
    }

    func nextQuestion() {
        question = trainer.question(type: apparatusType, seed: Int.random(in: 0...Int(Int32.max)), curriculum: curriculum)
        studentInput = ""
        result = nil
    }
}

struct ApparatusPracticeView: View {
    @State private var viewModel: ApparatusPracticeViewModel
    var onSaved: (() -> Void)?
    @FocusState private var inputFocused: Bool

    init(apparatusType: ApparatusType, curriculum: Curriculum, repository: AttemptRepository, onSaved: (() -> Void)? = nil) {
        _viewModel = State(initialValue: ApparatusPracticeViewModel(apparatusType: apparatusType, curriculum: curriculum, repository: repository))
        self.onSaved = onSaved
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                InstrumentCanvasView(visualState: viewModel.question.visualState)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text(viewModel.question.prompt)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    TextField("Your reading", text: $viewModel.studentInput)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .focused($inputFocused)
                    Text(viewModel.question.unit)
                        .foregroundStyle(.secondary)
                }

                if let result = viewModel.result {
                    ResultCard(result: result)
                }

                HStack(spacing: 12) {
                    Button(viewModel.result == nil ? "Submit" : "Next question") {
                        if viewModel.result == nil {
                            inputFocused = false
                            viewModel.submit(onSaved: { onSaved?() })
                        } else {
                            viewModel.nextQuestion()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.apparatusType.label)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ResultCard: View {
    let result: ApparatusMarkResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(result.correct ? "Correct" : "Outside tolerance", systemImage: result.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.headline)
                .foregroundStyle(result.correct ? .green : .red)
            ForEach(result.feedback, id: \.self) { line in
                Text(line).font(.footnote)
            }
            Divider()
            Text("Exam trap: \(result.examTrap)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((result.correct ? Color.green : Color.red).opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Instrument rendering

/// Dispatches to a dedicated `Canvas` renderer for the vernier caliper (the
/// flagship, fully bespoke instrument drawing demonstrating the pattern) and
/// a shared schematic dial renderer for the remaining eight instruments.
/// The schematic renderer is intentionally simple and correct rather than
/// pixel-matched to the Android drawables — see project notes for bespoke
/// artwork planned for the other eight in the next iteration.
struct InstrumentCanvasView: View {
    let visualState: ApparatusVisualState

    var body: some View {
        switch visualState {
        case let .vernier(mainScaleCm, vernierCoincidence, zeroErrorCm):
            VernierCaliperCanvasView(mainScaleCm: mainScaleCm, vernierCoincidence: vernierCoincidence, zeroErrorCm: zeroErrorCm)
        default:
            GenericDialCanvasView(visualState: visualState)
        }
    }
}

/// Bespoke vernier caliper rendering: main scale in mm, a sliding vernier
/// scale with 10 divisions, and the jaws — matching the reading logic in
/// `ApparatusTrainer.vernierQuestion`.
struct VernierCaliperCanvasView: View {
    let mainScaleCm: Double
    let vernierCoincidence: Int
    let zeroErrorCm: Double

    var body: some View {
        Canvas { context, size in
            let originX: CGFloat = 24
            let scaleWidth = size.width - 48
            let pxPerCm: CGFloat = scaleWidth / 9.0 // main scale drawn 0-9 cm
            let baselineY = size.height * 0.42

            // Main scale ticks (mm resolution)
            var mainScale = Path()
            for mm in 0...90 {
                let x = originX + CGFloat(mm) * (pxPerCm / 10)
                let isCm = mm % 10 == 0
                let tickHeight: CGFloat = isCm ? 18 : (mm % 5 == 0 ? 12 : 7)
                mainScale.move(to: CGPoint(x: x, y: baselineY))
                mainScale.addLine(to: CGPoint(x: x, y: baselineY - tickHeight))
            }
            context.stroke(mainScale, with: .color(.primary), lineWidth: 1)

            for cm in 0...9 {
                let x = originX + CGFloat(cm) * pxPerCm
                context.draw(Text("\(cm)").font(.system(size: 10)), at: CGPoint(x: x, y: baselineY - 30))
            }

            // Jaw position (fixed + moving jaw at mainScaleCm reading)
            let jawX = originX + CGFloat(mainScaleCm) * pxPerCm
            var jaws = Path()
            jaws.move(to: CGPoint(x: originX, y: baselineY + 10))
            jaws.addLine(to: CGPoint(x: originX, y: baselineY + 60))
            jaws.move(to: CGPoint(x: jawX, y: baselineY + 10))
            jaws.addLine(to: CGPoint(x: jawX, y: baselineY + 60))
            context.stroke(jaws, with: .color(.blue), lineWidth: 3)

            // Vernier scale (10 divisions across 9 main-scale mm, sliding with the jaw)
            var vernier = Path()
            let vernierSpanPx = pxPerCm * 0.9
            for division in 0...10 {
                let x = jawX + CGFloat(division) * (vernierSpanPx / 10)
                let isCoincidence = division == vernierCoincidence
                let tickHeight: CGFloat = isCoincidence ? 14 : 8
                vernier.move(to: CGPoint(x: x, y: baselineY + 60))
                vernier.addLine(to: CGPoint(x: x, y: baselineY + 60 + tickHeight))
            }
            context.stroke(vernier, with: .color(.blue), lineWidth: 1)

            let coincidenceX = jawX + CGFloat(vernierCoincidence) * (vernierSpanPx / 10)
            context.stroke(
                Path(ellipseIn: CGRect(x: coincidenceX - 4, y: baselineY + 60, width: 8, height: 8)),
                with: .color(.orange), lineWidth: 2
            )
        }
        .overlay(alignment: .bottom) {
            Text(zeroErrorCm == 0 ? "Zero error: none" : "Zero error: \(zeroErrorCm > 0 ? "+" : "")\(String(format: "%.2f", zeroErrorCm)) cm")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
        }
        .accessibilityLabel("Vernier caliper reading diagram")
    }
}

/// Shared schematic renderer for the eight instruments that don't yet have
/// bespoke artwork: draws a labelled semicircular dial or a simple bar,
/// enough to practice reading logic and marking while dedicated art for
/// each instrument is completed.
struct GenericDialCanvasView: View {
    let visualState: ApparatusVisualState

    var body: some View {
        Canvas { rawContext, size in
            var context = rawContext
            let center = CGPoint(x: size.width / 2, y: size.height * 0.62)
            let radius = min(size.width, size.height) * 0.38

            switch visualState {
            case let .ammeter(maxReading, needleReading), let .voltmeter(maxReading, needleReading):
                drawDial(context: &context, center: center, radius: radius, value: needleReading, maxValue: maxReading)
            case let .newtonMeter(maxReading, pointerReading):
                drawDial(context: &context, center: center, radius: radius, value: pointerReading, maxValue: maxReading)
            case let .thermometer(bulbTempC, scaleMinC, scaleMaxC):
                drawVerticalBar(context: &context, size: size, value: bulbTempC, minValue: Double(scaleMinC), maxValue: Double(scaleMaxC), color: .red)
            case let .measuringCylinder(maxVolumeCm3, liquidLevelCm3, _):
                drawVerticalBar(context: &context, size: size, value: liquidLevelCm3, minValue: 0, maxValue: Double(maxVolumeCm3), color: .blue)
            case let .burette(readingCm3):
                // Burette scale is 0 at top, 50 at bottom — invert the fill.
                drawVerticalBar(context: &context, size: size, value: 50 - readingCm3, minValue: 0, maxValue: 50, color: .cyan)
            case let .stopwatch(minutes, seconds, tenths):
                let text = String(format: "%d:%02d.%d", minutes, seconds, tenths)
                context.draw(Text(text).font(.system(size: 40, weight: .semibold, design: .monospaced)), at: center)
            default:
                break
            }
        }
        .accessibilityLabel("Instrument reading diagram")
    }

    private func drawDial(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, value: Double, maxValue: Double) {
        var arc = Path()
        arc.addArc(center: center, radius: radius, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        context.stroke(arc, with: .color(.primary.opacity(0.3)), lineWidth: 4)

        let fraction = max(0, min(1, value / maxValue))
        let angle = Angle.degrees(180 - 180 * fraction)
        let needleEnd = CGPoint(
            x: center.x + radius * 0.9 * cos(angle.radians),
            y: center.y - radius * 0.9 * sin(angle.radians)
        )
        var needle = Path()
        needle.move(to: center)
        needle.addLine(to: needleEnd)
        context.stroke(needle, with: .color(.red), lineWidth: 3)
        context.fill(Path(ellipseIn: CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8)), with: .color(.primary))

        context.draw(
            Text(String(format: "0 \u{2013} %.1f", maxValue)).font(.caption2),
            at: CGPoint(x: center.x, y: center.y + 24)
        )
    }

    private func drawVerticalBar(context: inout GraphicsContext, size: CGSize, value: Double, minValue: Double, maxValue: Double, color: Color) {
        let barWidth: CGFloat = 40
        let barRect = CGRect(x: size.width / 2 - barWidth / 2, y: 16, width: barWidth, height: size.height - 32)
        context.stroke(RoundedRectangle(cornerRadius: 6).path(in: barRect), with: .color(.primary.opacity(0.3)), lineWidth: 2)

        let fraction = max(0, min(1, (value - minValue) / (maxValue - minValue)))
        let fillHeight = barRect.height * fraction
        let fillRect = CGRect(x: barRect.minX, y: barRect.maxY - fillHeight, width: barRect.width, height: fillHeight)
        context.fill(RoundedRectangle(cornerRadius: 6).path(in: fillRect), with: .color(color.opacity(0.6)))
    }
}
