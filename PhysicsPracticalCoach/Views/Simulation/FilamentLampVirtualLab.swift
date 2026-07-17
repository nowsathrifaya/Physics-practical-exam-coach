//
//  FilamentLampVirtualLab.swift
//  PhysicsPracticalCoach
//
//  "Virtual Lab Experiment" wiring for the Filament Lamp I-V Characteristic
//  practical — same pattern as `PendulumVirtualLab.swift`: this file
//  supplies only the static config; the existing, unmodified
//  `FilamentLampExperimentViewModel`/`FilamentLampLabView` still own the
//  actual circuit physics and Stage 4-7 grading.
//

import SwiftUI

struct FilamentLampVirtualLabExperiment: VirtualLabExperiment {
    let title = "Filament Lamp I-V Characteristic Practical"

    let aim = "To investigate how the current through a filament lamp varies with the potential difference across it, and to show that the lamp does not obey Ohm's Law."

    let theory = "For an ohmic conductor, V is directly proportional to I, giving a straight-line V-I graph. A filament lamp's resistance increases with temperature as R = R\u2080 + kI, so as current increases, the filament heats up and its resistance rises, curving the V-I graph rather than keeping it a straight line."

    let learningOutcome = "By the end of this experiment you should be able to vary the current through a filament lamp using a rheostat, take ammeter/voltmeter readings across a wide range, and compare R = V/I at low and high current to demonstrate non-ohmic behaviour."

    let apparatusItems: [LabApparatusItem] = [
        LabApparatusItem(
            id: "cell", name: "Battery (cells)", systemImage: "battery.100",
            placementHint: "The battery drives the circuit, so connect it first.",
            setUpInstruction: "Connect the battery in series with the switch, rheostat, and lamp.",
            usageDescription: "Supplies the e.m.f. that drives current through the filament lamp."
        ),
        LabApparatusItem(
            id: "rheostat", name: "Rheostat", systemImage: "slider.horizontal.3",
            placementHint: "The rheostat goes in series after the battery, so the current can be varied.",
            setUpInstruction: "Connect the rheostat in series to vary the current through the lamp.",
            usageDescription: "Varies the current, allowing readings to be taken over a wide range from low to high current."
        ),
        LabApparatusItem(
            id: "ammeter", name: "Ammeter", systemImage: "gauge.with.needle",
            placementHint: "The ammeter connects in series with the lamp, once the rheostat is wired.",
            setUpInstruction: "Connect the ammeter in series with the filament lamp.",
            precision: "0.01 A", uncertainty: "\u{00B1}0.02 A",
            usageDescription: "Measures the current I through the filament lamp at each rheostat setting."
        ),
        LabApparatusItem(
            id: "voltmeter", name: "Voltmeter", systemImage: "gauge.with.needle.fill",
            placementHint: "Connect the voltmeter last, across the lamp itself.",
            setUpInstruction: "Connect the voltmeter in parallel across the filament lamp.",
            precision: "0.1 V", uncertainty: "\u{00B1}0.1 V",
            usageDescription: "Measures the potential difference V across the filament lamp."
        ),
        LabApparatusItem(
            id: "lamp", name: "Filament lamp", systemImage: "lightbulb.fill",
            placementHint: "The lamp is the component under test — place it last, with the meters already positioned around it.",
            setUpInstruction: "Place the filament lamp in the circuit, with the ammeter in series and voltmeter in parallel across it.",
            usageDescription: "The component under test — its resistance rises with temperature, so it does not obey Ohm's Law."
        ),
    ]

    let practicalQuestions: [ExperimentQuestion] = [
        ExperimentQuestion(
            id: "precaution",
            prompt: "State one precaution you should take in this experiment.",
            modelAnswerKeywords: ["wide range", "switch off between", "avoid overheating", "spread readings", "do not exceed rated"],
            modelAnswer: "Take readings over a wide range of currents, spread evenly from low to high, and avoid leaving a high current on for longer than needed to prevent damaging the lamp.",
            marks: 2
        ),
        ExperimentQuestion(
            id: "why_not_ohmic",
            prompt: "Explain why the filament lamp does not give a straight-line V-I graph.",
            modelAnswerKeywords: ["temperature rises", "resistance increases", "heats up", "not constant resistance", "r increases with current"],
            modelAnswer: "As current increases, the filament heats up and its resistance increases, so V is no longer directly proportional to I and the graph curves rather than forming a straight line.",
            marks: 2
        ),
        ExperimentQuestion(
            id: "compare_resistance",
            prompt: "How would you use your readings to show that the lamp's resistance is not constant?",
            modelAnswerKeywords: ["calculate r = v/i", "compare at low and high", "different values", "not the same", "two currents"],
            modelAnswer: "Calculate R = V/I at a low current and again at a high current; since the two values are clearly different, this shows the lamp's resistance is not constant, unlike an ohmic conductor.",
            marks: 2
        ),
    ]

    let conclusionOptions = [
        "The lamp's resistance increases with current, so it does not obey Ohm's Law and its V-I graph is a curve, not a straight line.",
        "The lamp obeys Ohm's Law exactly like a fixed resistor.",
        "The lamp's resistance decreases as current increases.",
        "The lamp's resistance is completely independent of current.",
    ]
    let correctConclusionIndex = 0
}

struct FilamentLampVirtualLabView: View {
    let curriculum: Curriculum
    let repository: AttemptRepository
    @State private var workflowViewModel: VirtualLabWorkflowViewModel

    init(curriculum: Curriculum, repository: AttemptRepository) {
        self.curriculum = curriculum
        self.repository = repository
        _workflowViewModel = State(initialValue: VirtualLabWorkflowViewModel(
            experiment: FilamentLampVirtualLabExperiment(),
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum)
        ))
    }

    var body: some View {
        VirtualLabWorkflowView(viewModel: workflowViewModel) {
            FilamentLampLabView(
                curriculum: curriculum,
                repository: repository,
                onFinished: { result in
                    workflowViewModel.coreExperimentFinished(result)
                }
            )
        }
    }
}
