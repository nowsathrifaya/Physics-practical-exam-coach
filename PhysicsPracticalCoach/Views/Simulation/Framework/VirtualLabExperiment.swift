//
//  VirtualLabExperiment.swift
//  PhysicsPracticalCoach
//
//  Shared contract + workflow controller for the "Virtual Lab Experiments"
//  feature (formerly "Simulation"). This is a wrapper layer, NOT a
//  replacement for the existing Lab framework: an experiment's actual
//  physics/apparatus state (e.g. `PendulumLabState`) and its existing
//  score/graph logic (e.g. `PendulumExperimentViewModel`) are untouched and
//  still own Stages 4-7 (Perform, Record Results, Graph, Calculations)
//  exactly as before. This file only adds the stages that wrap around that
//  core: Introduction, Collect Apparatus, Set Up, Practical Questions,
//  Conclusion, Results, and Examiner Feedback.
//
//  A concrete experiment (Pendulum first, then Spring/Ohm's Law/
//  Potentiometer/Density/Moments later) only needs to:
//   1. Conform to `VirtualLabExperiment` with its static config (title, aim,
//      theory, apparatus list, practical questions, conclusion options).
//   2. Embed its existing Lab view (e.g. `PendulumLabView`'s inner content)
//      as the Stage 4-7 content, and call `coreExperimentFinished(_:)` once
//      that existing flow produces its `LabRunResult` — see
//      `PendulumVirtualLab.swift` for the reference wiring.
//

import Foundation
import CoreGraphics

// MARK: - Static per-experiment configuration

/// One piece of apparatus a student drags onto the bench in Stage 2, then
/// assembles/positions in Stage 3.
struct LabApparatusItem: Identifiable, Hashable {
    let id: String
    let name: String
    let systemImage: String
    /// Shown when the student drops it in the wrong place — teaches rather
    /// than simply rejecting, per the spec's "educational hints" requirement.
    let placementHint: String
    /// Shown once correctly placed, describing the assembly action for
    /// Stage 3 (e.g. "Attach the string to the clamp.").
    let setUpInstruction: String
    /// Shown in the info sheet (\u{2139}\u{fe0f} button on each apparatus card) —
    /// revision-style facts about the instrument itself. Defaulted to empty
    /// so existing call sites compile unchanged; experiments can fill these
    /// in for genuine measuring instruments (rulers, stopwatches) where
    /// precision/uncertainty are real exam-technique content.
    var precision: String = ""
    var uncertainty: String = ""
    var usageDescription: String = ""
}

/// One Stage 8 practical exam-style question. Marked with lightweight
/// keyword matching against `modelAnswerKeywords` — the same
/// tolerance-based philosophy as the rest of the app's marking (never exact
/// string matching), then the full `modelAnswer` is shown as feedback
/// either way so the student sees the expected exam-technique reasoning.
struct ExperimentQuestion: Identifiable, Hashable {
    let id: String
    let prompt: String
    let modelAnswerKeywords: [String]
    let modelAnswer: String
    let marks: Int
}

/// Static configuration a concrete experiment supplies. The generic
/// `VirtualLabWorkflowView` renders Stages 1, 2, 3, 8, 9, 10, 11 entirely
/// from this data; Stages 4-7 are supplied separately as that experiment's
/// own existing view (see `coreContent` usage in `PendulumVirtualLab.swift`).
protocol VirtualLabExperiment: Sendable {
    var title: String { get }
    var aim: String { get }
    var theory: String { get }
    var learningOutcome: String { get }
    var apparatusItems: [LabApparatusItem] { get }
    var practicalQuestions: [ExperimentQuestion] { get }
    var conclusionOptions: [String] { get }
    var correctConclusionIndex: Int { get }
}

extension VirtualLabExperiment {
    /// Nil for every experiment by default — only circuit-based labs
    /// override this. When present, Stage 3 shows the interactive circuit
    /// assembly instead of the plain checklist.
    var circuitWiringTask: CircuitWiringTask? { nil }
}

extension VirtualLabExperiment {
    /// Marks available for each stage, mirrored from the constants used in
    /// `VirtualLabWorkflowViewModel.finishExperiment()` — purely for the
    /// "marks throughout" display; the actual scoring logic lives in the
    /// view model, unchanged, and stays the single source of truth.
    var apparatusStageMarks: Int { 10 }
    var questionStageMarks: Int { max(practicalQuestions.reduce(0) { $0 + $1.marks }, 1) }
    var conclusionStageMarks: Int { 10 }
}

// MARK: - Circuit wiring (Stage 3, for circuit-based experiments)

/// One draggable circuit component chip — battery, switch, rheostat,
/// ammeter, voltmeter, or the component under test (resistor/lamp).
struct CircuitComponent: Identifiable, Hashable {
    let id: String
    let name: String
    let systemImage: String
}

enum CircuitSlotKind {
    /// Sits in the main current loop.
    case series
    /// A branch connected across another slot's two nodes, not carrying
    /// the main loop current.
    case parallel
}

/// One empty position on the schematic. `position` is a unit-square
/// fraction (0...1 in both axes) of the canvas, so the same schematic
/// layout can be reused at any canvas size.
struct CircuitSlot: Identifiable {
    let id: String
    let kind: CircuitSlotKind
    let correctComponentID: String
    let position: CGPoint
    /// Only set for `.parallel` slots — which series slot's two nodes this
    /// branch connects across, purely for drawing the stub wire correctly.
    let parallelAcrossSlotID: String?

    init(id: String, kind: CircuitSlotKind, correctComponentID: String, position: CGPoint, parallelAcrossSlotID: String? = nil) {
        self.id = id
        self.kind = kind
        self.correctComponentID = correctComponentID
        self.position = position
        self.parallelAcrossSlotID = parallelAcrossSlotID
    }
}

/// A complete circuit-assembly task for Stage 3: the schematic slots plus
/// the components to place into them. Optional on `VirtualLabExperiment` —
/// only circuit-based labs (Ohm's Law, Filament Lamp, and later
/// Resistance Wire/Potentiometer) provide one; everything else falls back
/// to the plain checklist Set Up stage.
struct CircuitWiringTask {
    let components: [CircuitComponent]
    let slots: [CircuitSlot]

    /// Feedback for placing `componentID` into `slot` — uses the slot's
    /// *kind*, not just "right or wrong," so a misplaced ammeter and a
    /// misplaced voltmeter each get the specific, teachable message about
    /// series vs parallel rather than a generic "incorrect."
    func feedback(forPlacing componentID: String, into slot: CircuitSlot) -> (message: String, isCorrect: Bool) {
        if componentID == slot.correctComponentID {
            return ("Correct.", true)
        }
        if componentID == "ammeter" && slot.kind == .parallel {
            return ("Ammeter must be connected in series.", false)
        }
        if componentID == "voltmeter" && slot.kind == .series {
            return ("Voltmeter should be connected in parallel.", false)
        }
        let correctName = components.first { $0.id == slot.correctComponentID }?.name ?? "a different component"
        return ("This position needs \(correctName), not that.", false)
    }
}


enum LabExperimentStage: Int, CaseIterable, Identifiable {
    case introduction = 0
    case collectApparatus
    case setUp
    case coreExperiment   // wraps the experiment's existing Stage 4-7 flow
    case practicalQuestions
    case conclusion
    case results
    case examinerFeedback

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .introduction: return "Introduction"
        case .collectApparatus: return "Collect Apparatus"
        case .setUp: return "Set Up Experiment"
        case .coreExperiment: return "Perform & Record"
        case .practicalQuestions: return "Practical Questions"
        case .conclusion: return "Conclusion"
        case .results: return "Results"
        case .examinerFeedback: return "Examiner Feedback"
        }
    }

    /// 1-based step number shown in the progress indicator. `coreExperiment`
    /// covers the spec's Stages 4-7 in one step here, since that's the
    /// existing Lab flow's own internal phases (see `PendulumLabState.Phase`)
    /// rather than four separate screens.
    var stepNumber: Int { rawValue + 1 }
    static var totalSteps: Int { allCases.count }

    /// Short emoji + label used in the checklist-style progress indicator —
    /// deliberately terser than `title`, which is used as the in-stage
    /// heading elsewhere.
    var emoji: String {
        switch self {
        case .introduction: return "\u{1F9EA}"
        case .collectApparatus: return "\u{1F4E6}"
        case .setUp: return "\u{1F527}"
        case .coreExperiment: return "\u{23F3}"
        case .practicalQuestions: return "\u{2753}"
        case .conclusion: return "\u{1F4DD}"
        case .results: return "\u{1F4CA}"
        case .examinerFeedback: return "\u{1F3C6}"
        }
    }

    var shortLabel: String {
        switch self {
        case .introduction: return "Intro"
        case .collectApparatus: return "Apparatus"
        case .setUp: return "Setup"
        case .coreExperiment: return "Experiment"
        case .practicalQuestions: return "Questions"
        case .conclusion: return "Conclusion"
        case .results: return "Results"
        case .examinerFeedback: return "Report"
        }
    }
}

// MARK: - Results / feedback

/// Section-by-section marks for the Stage 10 report. Deliberately additive,
/// not a replacement: `VirtualLabWorkflowViewModel` still produces a real
/// `LabRunResult` for `LabAttemptRecorder`/`LabFeedbackCard` to consume
/// completely unchanged — this is purely the richer breakdown shown on the
/// Results stage itself, with the same numbers folded into that
/// `LabRunResult`'s feedback lines for Progress-tab history.
struct ExperimentSectionScore: Identifiable {
    var id: String { section }
    let section: String
    let score: Int
    let maxScore: Int
}

struct ExaminerFeedbackNote: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let isPositive: Bool
}

// MARK: - Workflow controller

@MainActor
@Observable
final class VirtualLabWorkflowViewModel {
    let experiment: VirtualLabExperiment
    private let recorder: LabAttemptRecorder

    private(set) var stage: LabExperimentStage = .introduction
    private(set) var placedApparatus: Set<String> = []
    private(set) var apparatusHint: String?
    private(set) var conclusionSelection: Int?
    private(set) var questionAnswers: [String: String] = [:]
    private(set) var sectionScores: [ExperimentSectionScore] = []
    private(set) var examinerNotes: [ExaminerFeedbackNote] = []
    private(set) var finalResult: LabRunResult?

    /// The result from the experiment's own existing Stage 4-7 flow (e.g.
    /// `PendulumExperimentViewModel.calculateResult()`). The generic
    /// workflow never re-implements physics grading — it only wraps this.
    private var coreResult: LabRunResult?

    init(experiment: VirtualLabExperiment, recorder: LabAttemptRecorder) {
        self.experiment = experiment
        self.recorder = recorder
    }

    var allApparatusPlaced: Bool { placedApparatus.count == experiment.apparatusItems.count }

    func startExperiment() {
        SoundManager.shared.play(.tap)
        stage = .collectApparatus
    }

    /// `isCorrectDrop` is decided by the concrete experiment's bench-zone
    /// hit-testing (see `PendulumVirtualLab`'s apparatus stage view) — this
    /// model just tracks the outcome and surfaces the hint text.
    func placeApparatus(_ item: LabApparatusItem, isCorrectDrop: Bool) {
        if isCorrectDrop {
            placedApparatus.insert(item.id)
            apparatusHint = nil
            SoundManager.shared.play(.success)
        } else {
            apparatusHint = item.placementHint
            SoundManager.shared.play(.error)
        }
    }

    func proceedToSetUp() {
        guard allApparatusPlaced else { return }
        SoundManager.shared.play(.tap)
        stage = .setUp
    }

    func proceedToCoreExperiment() {
        SoundManager.shared.play(.tap)
        stage = .coreExperiment
    }

    /// Called once the experiment's own existing flow (Stages 4-7) finishes
    /// and produces a `LabRunResult` — advances the wrapping workflow into
    /// Stage 8 without the generic model needing to know anything about how
    /// that result was calculated.
    func coreExperimentFinished(_ result: LabRunResult) {
        coreResult = result
        SoundManager.shared.play(result.correct ? .success : .tap)
        stage = .practicalQuestions
    }

    func recordAnswer(for question: ExperimentQuestion, text: String) {
        questionAnswers[question.id] = text
    }

    func proceedToConclusion() {
        SoundManager.shared.play(.tap)
        stage = .conclusion
    }

    func selectConclusion(_ index: Int) {
        SoundManager.shared.play(.tap)
        conclusionSelection = index
    }

    /// Marks Stage 8 by keyword match, then folds every stage's marks into
    /// the Stage 10 report and produces the single `LabRunResult` the rest
    /// of the app (Progress tab, `LabAttemptRecorder`) already knows how to
    /// display and store — no changes needed to either of those.
    func finishExperiment() {
        guard let coreResult else { return }

        let apparatusScore = ExperimentSectionScore(
            section: "Apparatus & Setup",
            score: allApparatusPlaced ? 10 : 5,
            maxScore: 10
        )

        let coreScore = ExperimentSectionScore(
            section: "Experiment, Results & Graph",
            score: coreResult.score,
            maxScore: 100
        )

        let questionMaxTotal = experiment.practicalQuestions.reduce(0) { $0 + $1.marks }
        var questionEarned = 0
        for question in experiment.practicalQuestions {
            let answer = (questionAnswers[question.id] ?? "").lowercased()
            let hit = question.modelAnswerKeywords.contains { answer.contains($0.lowercased()) }
            if hit { questionEarned += question.marks }
        }
        let questionScore = ExperimentSectionScore(
            section: "Practical Questions",
            score: questionEarned,
            maxScore: max(questionMaxTotal, 1)
        )

        let conclusionScore = ExperimentSectionScore(
            section: "Conclusion",
            score: conclusionSelection == experiment.correctConclusionIndex ? 10 : 0,
            maxScore: 10
        )

        sectionScores = [apparatusScore, coreScore, questionScore, conclusionScore]

        let totalScore = sectionScores.reduce(0) { $0 + $1.score }
        let totalMax = sectionScores.reduce(0) { $0 + $1.maxScore }
        let percentage = totalMax > 0 ? Int((Double(totalScore) / Double(totalMax)) * 100.0) : 0

        examinerNotes = buildExaminerNotes()

        let feedbackLines =
            sectionScores.map { "\($0.section): \($0.score)/\($0.maxScore)" }
            + ["Total: \(totalScore)/\(totalMax) (\(percentage)%)"]
            + examinerNotes.map { $0.text }

        let outcome = LabRunResult(
            correct: percentage >= 70,
            score: percentage,
            feedback: feedbackLines,
            examTip: experiment.theory
        )
        finalResult = outcome
        SoundManager.shared.play(outcome.correct ? .complete : .error)
        stage = .results
        recorder.record(experimentTitle: experiment.title, result: outcome, maxScore: 100)
    }

    func viewExaminerFeedback() {
        SoundManager.shared.play(.tap)
        stage = .examinerFeedback
    }

    private func buildExaminerNotes() -> [ExaminerFeedbackNote] {
        var notes: [ExaminerFeedbackNote] = []
        for score in sectionScores {
            let ratio = score.maxScore > 0 ? Double(score.score) / Double(score.maxScore) : 0
            if ratio >= 0.8 {
                notes.append(ExaminerFeedbackNote(text: "Strong performance in \(score.section.lowercased()).", isPositive: true))
            } else if ratio < 0.5 {
                notes.append(ExaminerFeedbackNote(text: "Review \(score.section.lowercased()) \u{2014} this needs more practice.", isPositive: false))
            }
        }
        if notes.isEmpty {
            notes.append(ExaminerFeedbackNote(text: "Solid, consistent performance across every section.", isPositive: true))
        }
        return notes
    }

    func restart() {
        SoundManager.shared.play(.tap)
        stage = .introduction
        placedApparatus = []
        apparatusHint = nil
        conclusionSelection = nil
        questionAnswers = [:]
        sectionScores = []
        examinerNotes = []
        finalResult = nil
        coreResult = nil
    }
}
