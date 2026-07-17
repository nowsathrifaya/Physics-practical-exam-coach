//
//  PotentiometerVirtualLab.swift
//  PhysicsPracticalCoach
//
//  "Virtual Lab Experiment" wiring for the Potentiometer — same pattern as
//  `PendulumVirtualLab.swift`: this file supplies only the static config;
//  the existing, unmodified `PotentiometerExperimentViewModel`/
//  `PotentiometerLabView` still own the actual physics and Stage 4-7
//  grading.
//

import SwiftUI

struct PotentiometerVirtualLabExperiment: VirtualLabExperiment {
    let title = "Potentiometer Practical"

    let aim = "To investigate how the potential difference across a length of resistance wire varies with that length, using a sliding jockey."

    let theory = "With a constant driver current I flowing through a uniform resistance wire, the potential difference across a length l of the wire is V = I \u00D7 r \u00D7 l, where r is the resistance per unit length. So V is directly proportional to l, and the gradient of a V-l graph gives the potential gradient K = I \u00D7 r."

    let learningOutcome = "By the end of this experiment you should be able to tap a jockey along a resistance wire at several positions, read the voltmeter accurately at each, and use a V-l graph to find the potential gradient."

    let apparatusItems: [LabApparatusItem] = [
        LabApparatusItem(
            id: "driver_cell", name: "Driver cell", systemImage: "battery.100",
            placementHint: "The driver cell powers the whole wire, so it needs to be connected first.",
            setUpInstruction: "Connect the driver cell in series with a protective resistor across the full wire.",
            usageDescription: "Drives a small, constant current through the length of resistance wire."
        ),
        LabApparatusItem(
            id: "wire", name: "Resistance wire on scale", systemImage: "line.horizontal.3",
            placementHint: "The wire must be connected to the driver cell before the jockey has anything to touch.",
            setUpInstruction: "Stretch the uniform resistance wire along a metre scale, connected at both ends to the driver circuit.",
            precision: "1 mm", uncertainty: "\u{00B1}0.5 mm",
            usageDescription: "A uniform wire whose resistance per unit length is constant, so distance along it can stand in for resistance."
        ),
        LabApparatusItem(
            id: "jockey", name: "Jockey (sliding contact)", systemImage: "hand.point.up.left.fill",
            placementHint: "The jockey needs the wire set up first, since it taps down onto it.",
            setUpInstruction: "Tap (don't press and hold) the jockey onto the wire at each chosen position l.",
            usageDescription: "Makes momentary contact with the wire at a chosen position, defining the length l over which V is measured."
        ),
        LabApparatusItem(
            id: "voltmeter", name: "Voltmeter", systemImage: "gauge.with.needle",
            placementHint: "Connect the voltmeter last, once the jockey can make contact with the wire.",
            setUpInstruction: "Connect the voltmeter between one end of the wire and the jockey.",
            precision: "0.01 V", uncertainty: "\u{00B1}0.02 V",
            usageDescription: "Measures the potential difference V between the fixed end of the wire and the jockey's contact point."
        ),
    ]

    let practicalQuestions: [ExperimentQuestion] = [
        ExperimentQuestion(
            id: "precaution",
            prompt: "State one precaution you should take in this experiment.",
            modelAnswerKeywords: ["tap", "not press", "avoid sliding", "parallax", "eye level", "constant current", "do not drag"],
            modelAnswer: "Tap the jockey gently onto the wire rather than dragging it, to avoid scraping the wire's surface, and keep the driver current constant throughout.",
            marks: 2
        ),
        ExperimentQuestion(
            id: "why_proportional",
            prompt: "Explain why V is directly proportional to the length l of wire used.",
            modelAnswerKeywords: ["v = i", "constant current", "resistance proportional to length", "uniform wire", "r = \u03c1l/a"],
            modelAnswer: "Since the wire is uniform, its resistance is proportional to its length; with a constant driver current, V = IR is therefore also directly proportional to l.",
            marks: 2
        ),
        ExperimentQuestion(
            id: "not_through_origin",
            prompt: "Your V-l graph does not pass exactly through the origin. Suggest why.",
            modelAnswerKeywords: ["contact resistance", "connection", "offset", "resistance at the end", "junction"],
            modelAnswer: "Small contact resistance at the wire's end connections adds a constant offset voltage, so the line has a small non-zero intercept rather than passing exactly through the origin.",
            marks: 2
        ),
    ]

    let conclusionOptions = [
        "The potential difference across the wire is directly proportional to its length, consistent with a constant potential gradient.",
        "The potential difference is independent of the length of wire used.",
        "The potential difference decreases as the length of wire increases.",
        "The potential difference depends only on the driver cell's e.m.f., not on length.",
    ]
    let correctConclusionIndex = 0
}

struct PotentiometerVirtualLabView: View {
    let curriculum: Curriculum
    let repository: AttemptRepository
    @State private var workflowViewModel: VirtualLabWorkflowViewModel

    init(curriculum: Curriculum, repository: AttemptRepository) {
        self.curriculum = curriculum
        self.repository = repository
        _workflowViewModel = State(initialValue: VirtualLabWorkflowViewModel(
            experiment: PotentiometerVirtualLabExperiment(),
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum)
        ))
    }

    var body: some View {
        VirtualLabWorkflowView(viewModel: workflowViewModel) {
            PotentiometerLabView(
                curriculum: curriculum,
                repository: repository,
                onFinished: { result in
                    workflowViewModel.coreExperimentFinished(result)
                }
            )
        }
    }
}
