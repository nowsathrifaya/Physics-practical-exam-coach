//
//  MomentsVirtualLab.swift
//  PhysicsPracticalCoach
//
//  "Virtual Lab Experiment" wiring for the Principle of Moments — same
//  pattern as `PendulumVirtualLab.swift`: this file supplies only the
//  static config; the existing, unmodified `MomentsExperimentViewModel`/
//  `MomentsLabView` still own the actual physics and Stage 4-7 grading.
//

import SwiftUI

struct MomentsVirtualLabExperiment: VirtualLabExperiment {
    let title = "Principle of Moments Practical"

    let aim = "To verify the principle of moments by balancing a beam pivoted at its centre using known and unknown forces at different distances."

    let theory = "The principle of moments states that for a beam in equilibrium, the sum of clockwise moments about the pivot equals the sum of anticlockwise moments: F\u2081d\u2081 = F\u2082d\u2082, where moment = force \u00D7 perpendicular distance from the pivot."

    let learningOutcome = "By the end of this experiment you should be able to position a known weight and balance it against another weight by adjusting its distance from the pivot, then verify that the clockwise and anticlockwise moments are equal."

    let apparatusItems: [LabApparatusItem] = [
        LabApparatusItem(
            id: "beam", name: "Metre rule (beam)", systemImage: "ruler",
            placementHint: "The beam is the foundation everything else sits on.",
            setUpInstruction: "Balance the metre rule on the pivot at its centre of gravity before adding any weights.",
            precision: "1 mm", uncertainty: "\u{00B1}0.5 mm",
            usageDescription: "Acts as the beam, and its scale is used to measure each weight's distance from the pivot."
        ),
        LabApparatusItem(
            id: "pivot", name: "Knife-edge pivot", systemImage: "triangle.fill",
            placementHint: "The pivot must be set up before the beam can rest on it.",
            setUpInstruction: "Position the knife-edge pivot under the centre of the beam.",
            usageDescription: "Provides a fixed, low-friction point about which the beam can rotate freely."
        ),
        LabApparatusItem(
            id: "known_weight", name: "Known weight", systemImage: "circle.fill",
            placementHint: "Hang the known weight on one side first, at a fixed distance.",
            setUpInstruction: "Hang the known weight at a fixed distance on one side of the pivot.",
            usageDescription: "Provides a fixed moment on one side of the pivot that the other side must balance."
        ),
        LabApparatusItem(
            id: "unknown_weight", name: "Weight to balance", systemImage: "circle.fill",
            placementHint: "The balancing weight goes on the other side, once the known weight is already hung.",
            setUpInstruction: "Hang the second weight on the opposite side, then slide it until the beam balances horizontally.",
            usageDescription: "Balanced against the known weight by adjusting its distance until the beam is horizontal."
        ),
    ]

    let practicalQuestions: [ExperimentQuestion] = [
        ExperimentQuestion(
            id: "precaution",
            prompt: "State one precaution you should take in this experiment.",
            modelAnswerKeywords: ["horizontal", "eye level", "centre of gravity", "balance first", "parallax", "still"],
            modelAnswer: "Ensure the beam itself is balanced at its centre of gravity before adding any weights, and check it is exactly horizontal at eye level before reading distances.",
            marks: 2
        ),
        ExperimentQuestion(
            id: "why_zero_beam",
            prompt: "Why must the beam be balanced on its own, with no weights attached, before the experiment begins?",
            modelAnswerKeywords: ["centre of gravity", "own weight", "cancel", "no extra moment", "uniform"],
            modelAnswer: "This ensures the beam's own weight acts exactly at the pivot, so it contributes no moment of its own and does not affect the results.",
            marks: 2
        ),
        ExperimentQuestion(
            id: "distance_measurement",
            prompt: "How should the distance of each weight from the pivot be measured, and why does this matter?",
            modelAnswerKeywords: ["perpendicular", "from the pivot", "centre of the weight", "horizontal distance"],
            modelAnswer: "Distance should be measured horizontally from the pivot to the centre of each hanging weight, since moment depends on the perpendicular distance from the pivot.",
            marks: 2
        ),
    ]

    let conclusionOptions = [
        "The beam balances when the clockwise moment equals the anticlockwise moment, verifying the principle of moments.",
        "The beam balances only when both weights are equal, regardless of distance.",
        "The beam balances only when both distances from the pivot are equal.",
        "Moment depends only on distance from the pivot, not on the size of the force.",
    ]
    let correctConclusionIndex = 0
}

struct MomentsVirtualLabView: View {
    let curriculum: Curriculum
    let repository: AttemptRepository
    @State private var workflowViewModel: VirtualLabWorkflowViewModel

    init(curriculum: Curriculum, repository: AttemptRepository) {
        self.curriculum = curriculum
        self.repository = repository
        _workflowViewModel = State(initialValue: VirtualLabWorkflowViewModel(
            experiment: MomentsVirtualLabExperiment(),
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum)
        ))
    }

    var body: some View {
        VirtualLabWorkflowView(viewModel: workflowViewModel) {
            MomentsLabView(
                curriculum: curriculum,
                repository: repository,
                onFinished: { result in
                    workflowViewModel.coreExperimentFinished(result)
                }
            )
        }
    }
}
