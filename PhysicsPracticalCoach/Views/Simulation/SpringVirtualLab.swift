//
//  SpringVirtualLab.swift
//  PhysicsPracticalCoach
//
//  "Virtual Lab Experiment" wiring for Hooke's Law — same pattern as
//  `PendulumVirtualLab.swift`: this file supplies only the static config
//  (apparatus, practical questions, conclusion options); the existing,
//  unmodified `SpringExperimentViewModel`/`SpringLabView` still own the
//  actual physics and Stage 4-7 grading.
//

import SwiftUI

struct SpringVirtualLabExperiment: VirtualLabExperiment {
    let title = "Hooke's Law Practical"

    let aim = "To investigate the relationship between the force applied to a spring and its extension, and to determine the spring constant k."

    let theory = "Hooke's Law states that the extension x of a spring is directly proportional to the applied force F, provided the elastic limit is not exceeded: F = kx, where k is the spring constant. Plotting F against x gives a straight line through the origin with gradient k."

    let learningOutcome = "By the end of this experiment you should be able to load a spring with a range of masses, read extension accurately against a fixed reference point, and use an F-x graph to determine k."

    let apparatusItems: [LabApparatusItem] = [
        LabApparatusItem(
            id: "retort_stand", name: "Retort stand", systemImage: "figure.stand",
            placementHint: "Start with the retort stand — the spring needs a rigid support to hang from.",
            setUpInstruction: "Place the retort stand on a flat, stable surface.",
            usageDescription: "Provides a rigid, fixed support so the spring's top end doesn't move as it's loaded."
        ),
        LabApparatusItem(
            id: "clamp", name: "Boss and clamp", systemImage: "wrench.and.screwdriver.fill",
            placementHint: "The clamp attaches to the stand before the spring has anything to hang from.",
            setUpInstruction: "Attach the boss and clamp near the top of the stand.",
            usageDescription: "Holds the spring's top end at a fixed point."
        ),
        LabApparatusItem(
            id: "spring", name: "Spring", systemImage: "arrow.up.and.down",
            placementHint: "The spring hangs from the clamp — that needs to be up first.",
            setUpInstruction: "Hang the spring from the clamp, unloaded.",
            usageDescription: "The spring under test — its extension is measured as masses are added to its hook."
        ),
        LabApparatusItem(
            id: "metre_rule", name: "Metre rule", systemImage: "ruler",
            placementHint: "Bring the rule in once the spring is hanging, so you can measure its extension.",
            setUpInstruction: "Clamp the metre rule vertically alongside the spring, with a fixed reference mark level with the pointer/hook at zero load.",
            precision: "1 mm", uncertainty: "\u{00B1}0.5 mm",
            usageDescription: "Measures the spring's extension from the fixed reference mark to the pointer, for each load."
        ),
        LabApparatusItem(
            id: "masses", name: "Slotted masses", systemImage: "circle.fill",
            placementHint: "Add masses one at a time once the spring and rule are set up.",
            setUpInstruction: "Hang masses one at a time on the spring's hook, reading the new extension after each addition.",
            usageDescription: "Provides a range of known loads F = mg so extension can be measured against force."
        ),
    ]

    let practicalQuestions: [ExperimentQuestion] = [
        ExperimentQuestion(
            id: "precaution",
            prompt: "State one precaution you should take in this experiment.",
            modelAnswerKeywords: ["eye level", "parallax", "elastic limit", "exceed", "pointer", "same point", "gently"],
            modelAnswer: "Read the scale at eye level to avoid parallax error, add masses gently to avoid overshoot, and do not exceed the spring's elastic limit.",
            marks: 2
        ),
        ExperimentQuestion(
            id: "elastic_limit",
            prompt: "What would you observe on your graph if the elastic limit had been exceeded, and why?",
            modelAnswerKeywords: ["curve", "no longer straight", "not proportional", "bends", "levels off", "deviate"],
            modelAnswer: "The graph would start to curve away from the straight line, since extension is no longer proportional to force once the spring is permanently stretched beyond its elastic limit.",
            marks: 2
        ),
        ExperimentQuestion(
            id: "gradient_meaning",
            prompt: "Why does the gradient of your F-x graph give the spring constant k?",
            modelAnswerKeywords: ["f = kx", "f=kx", "rearrange", "k = f/x", "gradient is k", "directly proportional"],
            modelAnswer: "Since F = kx, plotting F against x gives a straight line through the origin whose gradient is k directly, without needing any further rearrangement.",
            marks: 2
        ),
    ]

    let conclusionOptions = [
        "Extension is directly proportional to the applied force, consistent with Hooke's Law F = kx.",
        "Extension is independent of the applied force.",
        "Extension decreases as the applied force increases.",
        "Extension depends only on the natural length of the spring.",
    ]
    let correctConclusionIndex = 0
}

struct SpringVirtualLabView: View {
    let curriculum: Curriculum
    let repository: AttemptRepository
    @State private var workflowViewModel: VirtualLabWorkflowViewModel

    init(curriculum: Curriculum, repository: AttemptRepository) {
        self.curriculum = curriculum
        self.repository = repository
        _workflowViewModel = State(initialValue: VirtualLabWorkflowViewModel(
            experiment: SpringVirtualLabExperiment(),
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum)
        ))
    }

    var body: some View {
        VirtualLabWorkflowView(viewModel: workflowViewModel) {
            SpringLabView(
                curriculum: curriculum,
                repository: repository,
                onFinished: { result in
                    workflowViewModel.coreExperimentFinished(result)
                }
            )
        }
    }
}
