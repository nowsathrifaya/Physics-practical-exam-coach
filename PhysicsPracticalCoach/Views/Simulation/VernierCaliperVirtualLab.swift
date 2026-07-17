//
//  VernierCaliperVirtualLab.swift
//  PhysicsPracticalCoach
//
//  "Virtual Lab Experiment" wiring for the Vernier Caliper practical — same
//  pattern as `PendulumVirtualLab.swift`: this file supplies only the
//  static config; the existing, unmodified `VernierExperimentViewModel`/
//  `VernierCaliperLabView` still own the actual reading logic and Stage
//  4-7 grading.
//

import SwiftUI

struct VernierCaliperVirtualLabExperiment: VirtualLabExperiment {
    let title = "Vernier Caliper Practical"

    let aim = "To measure the diameter of a cylindrical rod accurately using a vernier caliper, at several points along its length, allowing for any zero error."

    let theory = "A vernier caliper reads to a precision finer than its main scale by finding which vernier scale division coincides with a main scale division. The reading is (main scale value) + (coinciding vernier division \u00D7 vernier constant), corrected for any zero error by subtracting it from the raw reading."

    let learningOutcome = "By the end of this experiment you should be able to close the caliper's jaws on an object, read the main scale and the coinciding vernier line together, apply a given zero error, and average several readings for a possibly non-uniform rod."

    let apparatusItems: [LabApparatusItem] = [
        LabApparatusItem(
            id: "vernier_caliper", name: "Vernier caliper", systemImage: "ruler",
            placementHint: "The caliper is the main instrument — bring it in first.",
            setUpInstruction: "Check and note the caliper's zero error before making any measurements.",
            precision: "0.01 cm", uncertainty: "\u{00B1}0.01 cm",
            usageDescription: "Measures the rod's diameter precisely by combining main scale and vernier scale readings."
        ),
        LabApparatusItem(
            id: "rod", name: "Cylindrical rod", systemImage: "cylinder",
            placementHint: "The rod goes between the jaws once the caliper is ready and zero error is noted.",
            setUpInstruction: "Close the caliper's jaws gently onto the rod at the chosen point along its length.",
            usageDescription: "The object under test — measured at three points since it may not be perfectly uniform."
        ),
    ]

    let practicalQuestions: [ExperimentQuestion] = [
        ExperimentQuestion(
            id: "precaution",
            prompt: "State one precaution you should take in this experiment.",
            modelAnswerKeywords: ["gently", "not too tight", "perpendicular", "eye level", "coinciding line", "avoid parallax"],
            modelAnswer: "Close the jaws gently onto the rod (not so tight that it deforms) and read the coinciding vernier line directly from the front to avoid parallax.",
            marks: 2
        ),
        ExperimentQuestion(
            id: "zero_error",
            prompt: "Explain how you apply a zero error when reading the vernier caliper.",
            modelAnswerKeywords: ["subtract", "positive zero error", "negative zero error", "corrected reading", "raw reading minus"],
            modelAnswer: "The corrected reading is found by subtracting the zero error (with its sign) from the raw reading, since a positive zero error means the raw reading is too large and a negative zero error means it is too small.",
            marks: 2
        ),
        ExperimentQuestion(
            id: "why_three_points",
            prompt: "Why is the rod measured at three different points along its length rather than just once?",
            modelAnswerKeywords: ["not uniform", "average", "possibly non-uniform", "reduce error", "reliable"],
            modelAnswer: "The rod may not be perfectly uniform along its length, so measuring at several points and averaging gives a more reliable value for its diameter.",
            marks: 2
        ),
    ]

    let conclusionOptions = [
        "The rod's diameter, corrected for zero error and averaged over several points, gives a reliable measurement of its true diameter.",
        "The vernier caliper's reading needs no correction regardless of zero error.",
        "A single reading at one point is always sufficient for any rod.",
        "The main scale alone gives the same precision as the full vernier reading.",
    ]
    let correctConclusionIndex = 0
}

struct VernierCaliperVirtualLabView: View {
    let curriculum: Curriculum
    let repository: AttemptRepository
    @State private var workflowViewModel: VirtualLabWorkflowViewModel

    init(curriculum: Curriculum, repository: AttemptRepository) {
        self.curriculum = curriculum
        self.repository = repository
        _workflowViewModel = State(initialValue: VirtualLabWorkflowViewModel(
            experiment: VernierCaliperVirtualLabExperiment(),
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum)
        ))
    }

    var body: some View {
        VirtualLabWorkflowView(viewModel: workflowViewModel) {
            VernierCaliperLabView(
                curriculum: curriculum,
                repository: repository,
                onFinished: { result in
                    workflowViewModel.coreExperimentFinished(result)
                }
            )
        }
    }
}
