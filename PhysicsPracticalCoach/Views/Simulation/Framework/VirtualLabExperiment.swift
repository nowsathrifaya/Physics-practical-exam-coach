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
protocol VirtualLabExperiment {
    var title: String { get }
    var aim: String { get }
    var theory: String { get }
    var learningOutcome: String { get }
    var apparatusItems: [LabApparatusItem] { get }
    var practicalQuestions: [ExperimentQuestion] { get }
    var conclusionOptions: [String] { get }
    var correctConclusionIndex: Int { get }
}

// MARK: - Stages

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
        stage = .collectApparatus
    }

    /// `isCorrectDrop` is decided by the concrete experiment's bench-zone
    /// hit-testing (see `PendulumVirtualLab`'s apparatus stage view) — this
    /// model just tracks the outcome and surfaces the hint text.
    func placeApparatus(_ item: LabApparatusItem, isCorrectDrop: Bool) {
        if isCorrectDrop {
            placedApparatus.insert(item.id)
            apparatusHint = nil
        } else {
            apparatusHint = item.placementHint
        }
    }

    func proceedToSetUp() {
        guard allApparatusPlaced else { return }
        stage = .setUp
    }

    func proceedToCoreExperiment() {
        stage = .coreExperiment
    }

    /// Called once the experiment's own existing flow (Stages 4-7) finishes
    /// and produces a `LabRunResult` — advances the wrapping workflow into
    /// Stage 8 without the generic model needing to know anything about how
    /// that result was calculated.
    func coreExperimentFinished(_ result: LabRunResult) {
        coreResult = result
        stage = .practicalQuestions
    }

    func recordAnswer(for question: ExperimentQuestion, text: String) {
        questionAnswers[question.id] = text
    }

    func proceedToConclusion() {
        stage = .conclusion
    }

    func selectConclusion(_ index: Int) {
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
        stage = .results
        recorder.record(experimentTitle: experiment.title, result: outcome, maxScore: 100)
    }

    func viewExaminerFeedback() {
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
