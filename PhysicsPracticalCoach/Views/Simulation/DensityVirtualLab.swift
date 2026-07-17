//
//  DensityVirtualLab.swift
//  PhysicsPracticalCoach
//
//  "Virtual Lab Experiment" wiring for Density by Displacement — same
//  pattern as `PendulumVirtualLab.swift`: this file supplies only the
//  static config; the existing, unmodified `DensityExperimentViewModel`/
//  `DensityLabView` still own the actual physics and Stage 4-7 grading.
//

import SwiftUI

struct DensityVirtualLabExperiment: VirtualLabExperiment {
    let title = "Density by Displacement Practical"

    let aim = "To determine the density of an irregularly-shaped solid by measuring the volume of water it displaces."

    let theory = "Density \u{03C1} = mass / volume. For an irregular solid, volume cannot be measured directly with a ruler, so it is found from the volume of water displaced when the solid is fully submerged: V = final level \u{2212} initial level. The density is then \u{03C1} = m / V."

    let learningOutcome = "By the end of this experiment you should be able to read a measuring cylinder's water level accurately before and after submerging a solid, and use the displaced volume together with a given mass to calculate density."

    let apparatusItems: [LabApparatusItem] = [
        LabApparatusItem(
            id: "measuring_cylinder", name: "Measuring cylinder", systemImage: "cylinder.fill",
            placementHint: "The measuring cylinder needs to be in place and part-filled before anything can be dropped into it.",
            setUpInstruction: "Half-fill the measuring cylinder with water and record the initial level.",
            precision: "1 cm\u{00B3}", uncertainty: "\u{00B1}0.5 cm\u{00B3}",
            usageDescription: "Holds the water and lets its rising level show the volume of the submerged solid."
        ),
        LabApparatusItem(
            id: "solid", name: "Irregular solid", systemImage: "diamond.fill",
            placementHint: "The solid goes in only once the cylinder is ready with its initial level recorded.",
            setUpInstruction: "Lower the solid gently into the cylinder using a thread, until it is fully submerged.",
            usageDescription: "The object under test — its mass is given, and its volume is found from displacement."
        ),
        LabApparatusItem(
            id: "thread", name: "Thread", systemImage: "line.diagonal",
            placementHint: "Tie the thread to the solid before lowering it in, so it can be submerged and retrieved without splashing.",
            setUpInstruction: "Tie the thread around the solid to lower and retrieve it without touching the sides.",
            usageDescription: "Lets the solid be lowered fully under the water without touching the cylinder walls, avoiding splashing."
        ),
    ]

    let practicalQuestions: [ExperimentQuestion] = [
        ExperimentQuestion(
            id: "precaution",
            prompt: "State one precaution you should take in this experiment.",
            modelAnswerKeywords: ["eye level", "parallax", "meniscus", "no air bubbles", "fully submerged", "avoid splashing"],
            modelAnswer: "Read the water level at eye level, at the bottom of the meniscus, and ensure the solid is fully submerged with no trapped air bubbles.",
            marks: 2
        ),
        ExperimentQuestion(
            id: "why_displacement",
            prompt: "Why is the displacement method used instead of measuring the solid's dimensions directly?",
            modelAnswerKeywords: ["irregular", "no regular shape", "cannot measure", "not a regular shape", "ruler won't"],
            modelAnswer: "The solid has an irregular shape, so its volume cannot be calculated from simple length measurements with a ruler; displaced water volume gives its volume directly.",
            marks: 2
        ),
        ExperimentQuestion(
            id: "thread_volume",
            prompt: "Why should the thread used to lower the solid be thin and largely kept out of the water?",
            modelAnswerKeywords: ["thread volume", "adds volume", "error", "displaces water", "negligible"],
            modelAnswer: "A thick thread would itself displace water and add to the apparent volume, introducing an error, so a thin thread kept mostly out of the water is used.",
            marks: 2
        ),
    ]

    let conclusionOptions = [
        "The solid's density can be found from its given mass divided by the volume of water it displaced.",
        "The solid's density equals the volume of water displaced.",
        "The solid's density is independent of its mass.",
        "The solid's density can only be found by weighing the displaced water.",
    ]
    let correctConclusionIndex = 0
}

struct DensityVirtualLabView: View {
    let curriculum: Curriculum
    let repository: AttemptRepository
    @State private var workflowViewModel: VirtualLabWorkflowViewModel

    init(curriculum: Curriculum, repository: AttemptRepository) {
        self.curriculum = curriculum
        self.repository = repository
        _workflowViewModel = State(initialValue: VirtualLabWorkflowViewModel(
            experiment: DensityVirtualLabExperiment(),
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum)
        ))
    }

    var body: some View {
        VirtualLabWorkflowView(viewModel: workflowViewModel) {
            DensityLabView(
                curriculum: curriculum,
                repository: repository,
                onFinished: { result in
                    workflowViewModel.coreExperimentFinished(result)
                }
            )
        }
    }
}
