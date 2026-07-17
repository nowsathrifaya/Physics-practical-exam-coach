//
//  ResistanceWireVirtualLab.swift
//  PhysicsPracticalCoach
//
//  "Virtual Lab Experiment" wiring for Resistance of a Wire — same pattern
//  as `PendulumVirtualLab.swift`: this file supplies only the static
//  config; the existing, unmodified `ResistanceWireExperimentViewModel`/
//  `ResistanceWireLabView` still own the actual physics and Stage 4-7
//  grading.
//

import SwiftUI

struct ResistanceWireVirtualLabExperiment: VirtualLabExperiment {
    let title = "Resistance of a Wire Practical"

    let aim = "To investigate how the resistance of a wire varies with its length, and to determine the resistivity of the wire's material."

    let theory = "Resistance is given by R = \u{03C1}l/A, where \u{03C1} is resistivity, l is the length in circuit, and A is the cross-sectional area. Plotting R against l gives a straight line through the origin with gradient \u{03C1}/A, so resistivity can be found from \u{03C1} = gradient \u00D7 A."

    let learningOutcome = "By the end of this experiment you should be able to vary the length of wire in circuit using a sliding contact, take ammeter/voltmeter readings at each length, calculate R = V/I, and use an R-l graph to find resistivity."

    let apparatusItems: [LabApparatusItem] = [
        LabApparatusItem(
            id: "cell", name: "Battery (cells)", systemImage: "battery.100",
            placementHint: "The battery drives current through the wire, so connect it first.",
            setUpInstruction: "Connect the battery in series with the switch and the wire under test.",
            usageDescription: "Supplies the e.m.f. that drives current through the length of wire in circuit."
        ),
        LabApparatusItem(
            id: "test_wire", name: "Resistance wire on scale", systemImage: "line.horizontal.3",
            placementHint: "Set up the wire on its scale before the sliding contact has anything to touch.",
            setUpInstruction: "Stretch the wire along a metre scale, connected to the circuit at one fixed end.",
            precision: "1 mm", uncertainty: "\u{00B1}0.5 mm",
            usageDescription: "The wire under test — the length between the fixed end and the sliding contact is the l used in R = \u{03C1}l/A."
        ),
        LabApparatusItem(
            id: "sliding_contact", name: "Sliding contact", systemImage: "hand.point.up.left.fill",
            placementHint: "Position the sliding contact once the wire is stretched along its scale.",
            setUpInstruction: "Move the sliding contact to set the length of wire l actually in the circuit.",
            usageDescription: "Sets which length of wire is included in the circuit for each trial."
        ),
        LabApparatusItem(
            id: "ammeter", name: "Ammeter", systemImage: "gauge.with.needle",
            placementHint: "Connect the ammeter in series once the wire and sliding contact are ready.",
            setUpInstruction: "Connect the ammeter in series with the wire.",
            precision: "0.01 A", uncertainty: "\u{00B1}0.02 A",
            usageDescription: "Measures the current I through the length of wire in circuit."
        ),
        LabApparatusItem(
            id: "voltmeter", name: "Voltmeter", systemImage: "gauge.with.needle.fill",
            placementHint: "Connect the voltmeter last, across the active length of wire.",
            setUpInstruction: "Connect the voltmeter in parallel across the length of wire between the fixed end and the sliding contact.",
            precision: "0.1 V", uncertainty: "\u{00B1}0.1 V",
            usageDescription: "Measures the potential difference V across the active length of wire, so R = V/I can be found."
        ),
    ]

    let practicalQuestions: [ExperimentQuestion] = [
        ExperimentQuestion(
            id: "precaution",
            prompt: "State one precaution you should take in this experiment.",
            modelAnswerKeywords: ["switch off", "heating", "parallax", "clean contact", "firm contact", "loose connections"],
            modelAnswer: "Only switch on briefly to take each reading, avoiding heating the wire, and ensure the sliding contact makes firm, clean contact with the wire.",
            marks: 2
        ),
        ExperimentQuestion(
            id: "why_r_increases_with_l",
            prompt: "Explain why the resistance increases as the length of wire in the circuit increases.",
            modelAnswerKeywords: ["r = \u03c1l/a", "more collisions", "longer path", "proportional to length", "electrons collide"],
            modelAnswer: "A longer wire gives free electrons more collisions with the lattice ions along their path, and since R = \u03c1l/A, resistance increases directly with length.",
            marks: 2
        ),
        ExperimentQuestion(
            id: "resistivity_from_gradient",
            prompt: "Explain how you would use your R-l graph, together with the wire's cross-sectional area A, to find the resistivity \u{03C1}.",
            modelAnswerKeywords: ["gradient", "\u03c1 = gradient", "multiply by area", "r = \u03c1l/a rearranged"],
            modelAnswer: "Since R = (\u{03C1}/A)l, the gradient of the R-l graph equals \u{03C1}/A, so multiplying the gradient by the given cross-sectional area A gives the resistivity \u{03C1}.",
            marks: 2
        ),
    ]

    let conclusionOptions = [
        "Resistance is directly proportional to length, consistent with R = \u{03C1}l/A for a wire of constant cross-section.",
        "Resistance is independent of the length of wire in the circuit.",
        "Resistance decreases as the length of wire in the circuit increases.",
        "Resistance depends only on the current, not on the length of wire.",
    ]
    let correctConclusionIndex = 0
}

struct ResistanceWireVirtualLabView: View {
    let curriculum: Curriculum
    let repository: AttemptRepository
    @State private var workflowViewModel: VirtualLabWorkflowViewModel

    init(curriculum: Curriculum, repository: AttemptRepository) {
        self.curriculum = curriculum
        self.repository = repository
        _workflowViewModel = State(initialValue: VirtualLabWorkflowViewModel(
            experiment: ResistanceWireVirtualLabExperiment(),
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum)
        ))
    }

    var body: some View {
        VirtualLabWorkflowView(viewModel: workflowViewModel) {
            ResistanceWireLabView(
                curriculum: curriculum,
                repository: repository,
                onFinished: { result in
                    workflowViewModel.coreExperimentFinished(result)
                }
            )
        }
    }
}
