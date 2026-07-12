//
//  PendulumVirtualLab.swift
//  PhysicsPracticalCoach
//
//  First concrete "Virtual Lab Experiment" — reference implementation for
//  every future one (Spring, Ohm's Law, Potentiometer, Density, Moments).
//  Only supplies static config (this file) and reuses:
//   - `VirtualLabWorkflowView` for all the wrapping-stage UI
//   - the EXISTING, unmodified `PendulumLabView` for Stages 4-7
//   - the EXISTING `AttemptRepository`/`LabAttemptRecorder` for persistence
//  No pendulum physics live here — that's still entirely `PendulumLabState`
//  and `PendulumExperimentViewModel`, untouched.
//

import SwiftUI

struct PendulumVirtualLabExperiment: VirtualLabExperiment {
    let title = "Pendulum Practical"

    let aim = "To investigate how the length of a simple pendulum affects its period of oscillation, and to use this relationship to determine a value for the acceleration due to gravity, g."

    let theory = "For small oscillations, a simple pendulum's period T is given by T = 2\u{03C0}\u{221A}(L/g), where L is the pendulum's length and g is the acceleration due to gravity. Plotting T\u{00B2} against L gives a straight line through the origin with gradient 4\u{03C0}\u{00B2}/g."

    let learningOutcome = "By the end of this experiment you should be able to set up a pendulum accurately, time multiple oscillations to reduce reaction-time error, and use a T\u{00B2}-L graph to determine g."

    let apparatusItems: [LabApparatusItem] = [
        LabApparatusItem(
            id: "retort_stand", name: "Retort stand", systemImage: "figure.stand",
            placementHint: "Start with the retort stand \u{2014} everything else attaches to it.",
            setUpInstruction: "Place the retort stand on a flat, stable surface.",
            precision: "N/A", uncertainty: "N/A",
            usageDescription: "Provides a rigid, fixed support so the pendulum's pivot doesn't move during the experiment."
        ),
        LabApparatusItem(
            id: "clamp", name: "Boss and clamp", systemImage: "wrench.and.screwdriver.fill",
            placementHint: "The clamp attaches to the retort stand before anything can hang from it.",
            setUpInstruction: "Attach the boss and clamp near the top of the stand.",
            precision: "N/A", uncertainty: "N/A",
            usageDescription: "Holds the string at a fixed pivot point, level with the top of the metre rule's zero mark."
        ),
        LabApparatusItem(
            id: "string", name: "String", systemImage: "line.diagonal",
            placementHint: "The string needs the clamp in place first, so it has something to hang from.",
            setUpInstruction: "Tie the string securely to the clamp.",
            precision: "N/A", uncertainty: "N/A",
            usageDescription: "Use a light, inextensible string \u{2014} its own mass and stretch would otherwise introduce error into L."
        ),
        LabApparatusItem(
            id: "bob", name: "Pendulum bob", systemImage: "circle.fill",
            placementHint: "The bob attaches to the free end of the string, after the string is already up.",
            setUpInstruction: "Tie the bob to the free end of the string so it hangs freely.",
            precision: "N/A", uncertainty: "N/A",
            usageDescription: "A dense, small bob approximates a point mass, which is what the T = 2\u{03C0}\u{221A}(L/g) formula assumes."
        ),
        LabApparatusItem(
            id: "metre_rule", name: "Metre rule", systemImage: "ruler",
            placementHint: "Bring the metre rule in once the pendulum is hanging, so you can measure its length.",
            setUpInstruction: "Position the metre rule vertically alongside the string, from the pivot down.",
            precision: "1 mm", uncertainty: "\u{00B1}0.5 mm",
            usageDescription: "Measures the pendulum's length L, from the pivot to the centre of the bob \u{2014} not to the bottom of the bob."
        ),
        LabApparatusItem(
            id: "stopwatch", name: "Stopwatch", systemImage: "stopwatch",
            placementHint: "The stopwatch is the last thing you need, once everything else is ready to swing.",
            setUpInstruction: "Have the stopwatch ready to start the instant you release the bob.",
            precision: "0.01 s", uncertainty: "\u{00B1}0.2\u20130.3 s (human reaction time, not the instrument itself)",
            usageDescription: "Times a fixed number of oscillations (commonly 10) so the period per swing can be found by dividing."
        ),
    ]

    let practicalQuestions: [ExperimentQuestion] = [
        ExperimentQuestion(
            id: "precaution",
            prompt: "State one precaution you should take in this experiment.",
            modelAnswerKeywords: ["small angle", "eye level", "avoid parallax", "draught", "air current", "fixed point", "same point"],
            modelAnswer: "Keep the release angle small (under about 10\u{00B0}), read the metre rule at eye level to avoid parallax error, and shield the pendulum from draughts.",
            marks: 2
        ),
        ExperimentQuestion(
            id: "ten_oscillations",
            prompt: "Why should you time multiple oscillations rather than just one?",
            modelAnswerKeywords: ["reaction time", "reaction-time", "average", "spread", "error"],
            modelAnswer: "Timing many oscillations spreads your reaction-time error over a much longer total time, making the error in each individual period much smaller than if you timed just one swing.",
            marks: 2
        ),
        ExperimentQuestion(
            id: "small_angle",
            prompt: "Why should the release angle be kept small?",
            modelAnswerKeywords: ["simple harmonic", "formula", "T = 2", "assumes", "approximation", "large angle"],
            modelAnswer: "The formula T = 2\u{03C0}\u{221A}(L/g) is only accurate for small-angle (simple harmonic) oscillations \u{2014} at large angles the period noticeably increases beyond what the formula predicts.",
            marks: 2
        ),
    ]

    let conclusionOptions = [
        "The period increases as the length increases, and T\u{00B2} is directly proportional to L \u{2014} consistent with T = 2\u{03C0}\u{221A}(L/g).",
        "The period is independent of the pendulum's length.",
        "The period decreases as the length increases.",
        "The period depends only on the mass of the bob.",
    ]
    let correctConclusionIndex = 0
}

struct PendulumVirtualLabView: View {
    let curriculum: Curriculum
    let repository: AttemptRepository
    @State private var workflowViewModel: VirtualLabWorkflowViewModel

    init(curriculum: Curriculum, repository: AttemptRepository) {
        self.curriculum = curriculum
        self.repository = repository
        _workflowViewModel = State(initialValue: VirtualLabWorkflowViewModel(
            experiment: PendulumVirtualLabExperiment(),
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum)
        ))
    }

    var body: some View {
        VirtualLabWorkflowView(viewModel: workflowViewModel) {
            PendulumLabView(
                curriculum: curriculum,
                repository: repository,
                onFinished: { result in
                    workflowViewModel.coreExperimentFinished(result)
                }
            )
        }
    }
}
