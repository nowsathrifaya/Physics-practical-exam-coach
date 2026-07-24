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
                    .frame(height: instrumentCanvasHeight)
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

    /// Tall, narrow instruments (newton meter, burette, thermometer, measuring
    /// cylinder, stopwatch) read more clearly with extra vertical room than the
    /// wide, short vernier/micrometer/dial gauges.
    private var instrumentCanvasHeight: CGFloat {
        switch viewModel.apparatusType {
        case .vernierCaliper, .micrometer, .ammeter, .voltmeter:
            return 220
        case .newtonMeter, .burette, .measuringCylinder, .thermometer:
            return 300
        case .stopwatch:
            return 260
        }
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

/// Dispatches to a dedicated, realistic `Canvas` renderer for each of the 9
/// apparatus types — see `ApparatusVisuals.swift` for the vernier caliper,
/// micrometer, ammeter/voltmeter dial, newton meter, thermometer, measuring
/// cylinder, burette, and stopwatch renderers.
struct InstrumentCanvasView: View {
    let visualState: ApparatusVisualState

    var body: some View {
        switch visualState {
        case let .vernier(mainScaleCm, vernierCoincidence, zeroErrorCm):
            VernierCaliperCanvasView(mainScaleCm: mainScaleCm, vernierCoincidence: vernierCoincidence, zeroErrorCm: zeroErrorCm)
        case let .micrometer(sleeveWholeMm, showHalfMm, thimbleHundredths, zeroErrorMm):
            MicrometerCanvasView(sleeveWholeMm: sleeveWholeMm, showHalfMm: showHalfMm, thimbleHundredths: thimbleHundredths, zeroErrorMm: zeroErrorMm)
        case let .ammeter(maxReading, needleReading):
            DialGaugeCanvasView(unitLabel: "A", maxReading: maxReading, needleReading: needleReading)
        case let .voltmeter(maxReading, needleReading):
            DialGaugeCanvasView(unitLabel: "V", maxReading: maxReading, needleReading: needleReading)
        case let .newtonMeter(maxReading, pointerReading):
            NewtonMeterCanvasView(maxReading: maxReading, pointerReading: pointerReading)
        case let .thermometer(bulbTempC, scaleMinC, scaleMaxC):
            ThermometerCanvasView(bulbTempC: bulbTempC, scaleMinC: scaleMinC, scaleMaxC: scaleMaxC)
        case let .measuringCylinder(maxVolumeCm3, liquidLevelCm3, minorDivisionCm3):
            MeasuringCylinderCanvasView(maxVolumeCm3: maxVolumeCm3, liquidLevelCm3: liquidLevelCm3, minorDivisionCm3: minorDivisionCm3)
        case let .burette(readingCm3):
            BuretteCanvasView(readingCm3: readingCm3)
        case let .stopwatch(minutes, seconds, tenths):
            StopwatchCanvasView(minutes: minutes, seconds: seconds, tenths: tenths)
        }
    }
}
