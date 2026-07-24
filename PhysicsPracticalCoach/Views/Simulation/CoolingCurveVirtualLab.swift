//
//  CoolingCurveVirtualLab.swift
//  PhysicsPracticalCoach
//
//  "Virtual Lab Experiment" wiring for the Cooling Curve practical — same
//  pattern as `PendulumVirtualLab.swift`: this file supplies only the
//  static config; the existing, unmodified `CoolingCurveExperimentViewModel`/
//  `CoolingCurveLabView` still own the actual physics and Stage 4-7
//  grading.
//

import SwiftUI

struct CoolingCurveVirtualLabExperiment: VirtualLabExperiment {
    let title = "Cooling Curve Practical"

    let aim = "To determine the freezing point of a substance by recording its temperature at regular time intervals as it cools, and plotting a temperature-time graph."

    let theory = "As a hot liquid cools, its temperature falls steadily until it reaches its freezing point. While it solidifies, latent heat is released, so the temperature remains constant (a plateau) even though the substance is still losing heat to its surroundings. Once fully solid, the temperature resumes falling. The plateau's temperature is the substance's freezing point."

    let learningOutcome = "By the end of this experiment you should be able to record temperature at regular time intervals as a substance cools, identify the plateau in your temperature-time graph, and read off the freezing point."

    let apparatusItems: [LabApparatusItem] = [
        LabApparatusItem(
            id: "test_tube", name: "Test tube with molten substance", systemImage: "testtube.2",
            placementHint: "The molten substance needs to be ready and cooling before you start timing.",
            setUpInstruction: "Support the test tube of molten substance so it can cool undisturbed.",
            usageDescription: "Holds the substance as it cools from a liquid, through freezing, to a solid."
        ),
        LabApparatusItem(
            id: "thermometer", name: "Thermometer", systemImage: "thermometer.medium",
            placementHint: "The thermometer goes into the substance once the tube is set up, so it can be read throughout.",
            setUpInstruction: "Insert the thermometer bulb into the substance, without touching the sides of the tube.",
            precision: "1 \u{00B0}C", uncertainty: "\u{00B1}0.5 \u{00B0}C",
            usageDescription: "Measures the substance's temperature at each moment you choose to take a reading."
        ),
        LabApparatusItem(
            id: "stopwatch", name: "Stopwatch", systemImage: "stopwatch",
            placementHint: "Start the stopwatch once the tube and thermometer are ready, so every reading has a time attached.",
            setUpInstruction: "Start the stopwatch as soon as you begin taking readings, and note the time at each one.",
            precision: "0.01 s", uncertainty: "\u{00B1}0.2\u{2013}0.3 s (human reaction time)",
            usageDescription: "Times the readings so a temperature-time graph can be plotted."
        ),
    ]

    let practicalQuestions: [ExperimentQuestion] = [
        ExperimentQuestion(
            id: "precaution",
            prompt: "State one precaution you should take in this experiment.",
            modelAnswerKeywords: ["stir", "regular intervals", "not touch sides", "eye level", "even readings", "same intervals"],
            modelAnswer: "Stir the substance gently before each reading so the temperature is even throughout, take readings at regular time intervals, and keep the thermometer bulb away from the tube's sides.",
            marks: 2
        ),
        ExperimentQuestion(
            id: "why_plateau",
            prompt: "Explain why the temperature stays constant for a period while the substance is freezing.",
            modelAnswerKeywords: ["latent heat", "released", "solidifying", "heat still lost", "energy released as it solidifies"],
            modelAnswer: "As the substance freezes, it releases latent heat of fusion, which balances the heat still being lost to the surroundings, so the temperature stays constant until freezing is complete.",
            marks: 2
        ),
        ExperimentQuestion(
            id: "identify_freezing_point",
            prompt: "How would you identify the freezing point from your temperature-time graph?",
            modelAnswerKeywords: ["flat", "plateau", "horizontal section", "constant temperature", "level part"],
            modelAnswer: "The freezing point is the temperature at which the graph shows a flat, horizontal plateau, since the temperature stops falling while the substance solidifies.",
            marks: 2
        ),
    ]

    let conclusionOptions = [
        "The substance's temperature falls steadily, plateaus at its freezing point while solidifying, then continues to fall once fully solid.",
        "The substance's temperature falls at a constant rate throughout, with no plateau.",
        "The substance's temperature rises briefly before falling.",
        "The freezing point cannot be determined from a temperature-time graph.",
    ]
    let correctConclusionIndex = 0
}

struct CoolingCurveVirtualLabView: View {
    let curriculum: Curriculum
    let repository: AttemptRepository
    @State private var workflowViewModel: VirtualLabWorkflowViewModel

    init(curriculum: Curriculum, repository: AttemptRepository) {
        self.curriculum = curriculum
        self.repository = repository
        _workflowViewModel = State(initialValue: VirtualLabWorkflowViewModel(
            experiment: CoolingCurveVirtualLabExperiment(),
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum)
        ))
    }

    var body: some View {
        VirtualLabWorkflowView(viewModel: workflowViewModel) {
            CoolingCurveLabView(
                curriculum: curriculum,
                repository: repository,
                onFinished: { result in
                    workflowViewModel.coreExperimentFinished(result)
                }
            )
        }
    }
}
