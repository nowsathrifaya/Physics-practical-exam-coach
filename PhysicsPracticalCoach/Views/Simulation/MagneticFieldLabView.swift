//
//  MagneticFieldLabView.swift
//  PhysicsPracticalCoach
//
//  Magnetic Effect of a Current lab experiment, built on the Lab framework
//  (see `PendulumLabView.swift` for the reference template and
//  `LAB_FRAMEWORK.md` for the architecture). Fills the syllabus gap for
//  "investigation of the magnetic effect of current in a conductor". The
//  wire is viewed end-on (as in the real experiment: a vertical wire
//  through a horizontal card, viewed from above), so it renders as a single
//  point with plotting compasses arranged around it \u{2014} current direction is
//  "out of the page" (\u{2299}) or "into the page" (\u{2297}), and every compass needle
//  points tangentially to the field's concentric circles.
//
//  Convention used throughout (standard right-hand-grip convention, drawn
//  exactly as it is normally shown in textbook diagrams): current OUT of
//  the page \u{2192} field circles anticlockwise (as drawn on the page); current
//  INTO the page \u{2192} field circles clockwise.
//

import SwiftUI

// MARK: - 1. Apparatus state

@Observable
final class MagneticFieldLabState {
    /// true = current flowing out of the page (\u{2299}), false = into the page (\u{2297}).
    private(set) var currentOutOfPage = true

    init() {}

    func flipCurrent() {
        currentOutOfPage.toggle()
    }

    /// Tangential field direction at the compass placed directly to the
    /// RIGHT of the wire (the position used for grading) \u{2014} "Up" for
    /// out-of-page current, "Down" for into-the-page current, following the
    /// anticlockwise/clockwise convention described above.
    var rightPositionNeedleDirection: String {
        currentOutOfPage ? "Up" : "Down"
    }
}

// MARK: - 2. Experiment view model

@MainActor
@Observable
final class MagneticFieldExperimentViewModel {
    private(set) var apparatus = MagneticFieldLabState()
    private let recorder: LabAttemptRecorder

    var rightNeedleAnswer: String?
    var reversalAnswer: String?
    private(set) var result: LabRunResult?

    let needleOptions = ["Up", "Down", "Left", "Right"]
    let reversalOptions = ["It reverses direction", "It stays the same", "It points straight at the wire"]

    init(recorder: LabAttemptRecorder) {
        self.recorder = recorder
    }

    var instructionText: String {
        "Tap 'Flip current direction' to see how the compass needles respond, then answer both questions below."
    }

    func flipCurrent() {
        apparatus.flipCurrent()
    }

    var canSubmit: Bool { rightNeedleAnswer != nil && reversalAnswer != nil }

    func submit() {
        guard let rightNeedleAnswer, let reversalAnswer else { return }

        let rightCorrect = rightNeedleAnswer == apparatus.rightPositionNeedleDirection
        let reversalCorrect = reversalAnswer == reversalOptions[0]
        let correct = rightCorrect && reversalCorrect

        var feedback: [String] = []
        feedback.append(rightCorrect
            ? "Correct \u{2014} with current \(apparatus.currentOutOfPage ? "out of" : "into") the page, the needle to the right of the wire points \(apparatus.rightPositionNeedleDirection)."
            : "Not quite \u{2014} with current \(apparatus.currentOutOfPage ? "out of" : "into") the page, the needle to the right of the wire should point \(apparatus.rightPositionNeedleDirection).")
        feedback.append(reversalCorrect
            ? "Correct \u{2014} reversing the current reverses every needle's direction."
            : "Reversing the current reverses the field direction, so every needle flips to point the opposite way.")

        let outcome = LabRunResult(
            correct: correct,
            score: (rightCorrect ? 50 : 0) + (reversalCorrect ? 50 : 0),
            feedback: feedback,
            examTip: "The field around a straight current-carrying wire forms concentric circles, tangential to the compass needle at every point \u{2014} never radiating outward or inward like a point charge's field. Reversing the current reverses the field direction everywhere."
        )
        result = outcome
        recorder.record(experimentTitle: SimulationType.magneticFieldWire.label, result: outcome)
    }

    func newTask() {
        rightNeedleAnswer = nil
        reversalAnswer = nil
        result = nil
    }
}

// MARK: - View

struct MagneticFieldLabView: View {
    let curriculum: Curriculum
    @State private var viewModel: MagneticFieldExperimentViewModel

    init(curriculum: Curriculum, repository: AttemptRepository) {
        self.curriculum = curriculum
        _viewModel = State(initialValue: MagneticFieldExperimentViewModel(
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum)
        ))
    }

    var body: some View {
        LabScaffoldView(
            title: "Magnetic Field Lab",
            instructionText: viewModel.instructionText,
            apparatusHeight: 300,
            result: viewModel.result,
            apparatus: { apparatusArea },
            controls: { controls }
        )
    }

    private var apparatusArea: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) * 0.32
            let outOfPage = viewModel.apparatus.currentOutOfPage

            Canvas { context, _ in
                // Field circles, drawn faintly, purely decorative.
                for scale in [0.5, 0.75, 1.0] {
                    context.stroke(
                        Path(ellipseIn: CGRect(x: center.x - radius * scale, y: center.y - radius * scale, width: radius * scale * 2, height: radius * scale * 2)),
                        with: .color(.secondary.opacity(0.2)), lineWidth: 1
                    )
                }

                // The wire, viewed end-on: a dot (out of page) or a cross (into page).
                if outOfPage {
                    context.fill(Path(ellipseIn: CGRect(x: center.x - 6, y: center.y - 6, width: 12, height: 12)), with: .color(.primary))
                } else {
                    var cross = Path()
                    cross.move(to: CGPoint(x: center.x - 7, y: center.y - 7))
                    cross.addLine(to: CGPoint(x: center.x + 7, y: center.y + 7))
                    cross.move(to: CGPoint(x: center.x + 7, y: center.y - 7))
                    cross.addLine(to: CGPoint(x: center.x - 7, y: center.y + 7))
                    context.stroke(cross, with: .color(.primary), lineWidth: 3)
                }
                LabCanvasHelpers.drawLabel(context: context, text: outOfPage ? "current out of page" : "current into page", at: CGPoint(x: center.x, y: center.y - radius - 20), size: 11)

                // Four compasses at 12, 3, 6, 9 o'clock, needle tangential to
                // the field circle \u{2014} anticlockwise for out-of-page current,
                // clockwise for into-the-page current (see file header).
                let positions: [(offset: CGPoint, outDir: CGPoint, label: String)] = [
                    (CGPoint(x: 0, y: -radius), CGPoint(x: -1, y: 0), "top"),
                    (CGPoint(x: radius, y: 0), CGPoint(x: 0, y: -1), "right"),
                    (CGPoint(x: 0, y: radius), CGPoint(x: 1, y: 0), "bottom"),
                    (CGPoint(x: -radius, y: 0), CGPoint(x: 0, y: 1), "left")
                ]

                for position in positions {
                    let compassCenter = CGPoint(x: center.x + position.offset.x, y: center.y + position.offset.y)
                    context.stroke(Path(ellipseIn: CGRect(x: compassCenter.x - 14, y: compassCenter.y - 14, width: 28, height: 28)), with: .color(.secondary.opacity(0.5)), lineWidth: 1.5)

                    let dir = outOfPage ? position.outDir : CGPoint(x: -position.outDir.x, y: -position.outDir.y)
                    var needle = Path()
                    needle.move(to: CGPoint(x: compassCenter.x - dir.x * 10, y: compassCenter.y - dir.y * 10))
                    needle.addLine(to: CGPoint(x: compassCenter.x + dir.x * 10, y: compassCenter.y + dir.y * 10))
                    context.stroke(needle, with: .color(.red), lineWidth: 2.5)
                    context.fill(
                        Path(ellipseIn: CGRect(x: compassCenter.x + dir.x * 10 - 2.5, y: compassCenter.y + dir.y * 10 - 2.5, width: 5, height: 5)),
                        with: .color(.red)
                    )
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.apparatus.currentOutOfPage)
        }
    }

    @ViewBuilder
    private var controls: some View {
        Button("Flip current direction") { viewModel.flipCurrent() }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)

        if viewModel.result == nil {
            VStack(alignment: .leading, spacing: 8) {
                Text("With the current direction shown now, which way does the needle to the RIGHT of the wire point?")
                    .font(.subheadline)
                Picker("Needle direction", selection: $viewModel.rightNeedleAnswer) {
                    Text("Choose one").tag(String?.none)
                    ForEach(viewModel.needleOptions, id: \.self) { option in
                        Text(option).tag(String?.some(option))
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("What happens to every needle if the current is reversed?")
                    .font(.subheadline)
                Picker("Reversal effect", selection: $viewModel.reversalAnswer) {
                    Text("Choose one").tag(String?.none)
                    ForEach(viewModel.reversalOptions, id: \.self) { option in
                        Text(option).tag(String?.some(option))
                    }
                }
                .pickerStyle(.menu)
            }

            Button("Submit answers") { viewModel.submit() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(!viewModel.canSubmit)
        } else {
            Button("New task") { viewModel.newTask() }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
        }
    }
}
