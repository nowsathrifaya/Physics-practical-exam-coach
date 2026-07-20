//
//  OhmsLawVirtualLab.swift
//  PhysicsPracticalCoach
//
//  "Virtual Lab Experiment" wiring for Ohm's Law — same pattern as
//  `PendulumVirtualLab.swift`: this file supplies only the static config;
//  the existing, unmodified `OhmsLawExperimentViewModel`/`OhmsLawLabView`
//  still own the actual circuit physics and Stage 4-7 grading.
//

import SwiftUI

struct OhmsLawVirtualLabExperiment: VirtualLabExperiment {
    let title = "Ohm's Law Practical"

    let aim = "To investigate the relationship between potential difference across, and current through, a resistor, and to determine its resistance."

    let theory = "Ohm's Law states that the current I through a resistor is directly proportional to the potential difference V across it, provided temperature stays constant: V = IR, where R is the resistance. Plotting V against I gives a straight line through the origin with gradient R."

    let learningOutcome = "By the end of this experiment you should be able to set up a series circuit correctly, vary current using a rheostat, take accurate ammeter/voltmeter readings, and use a V-I graph to determine resistance."

    let apparatusItems: [LabApparatusItem] = [
        LabApparatusItem(
            id: "cell", name: "Battery (cells)", systemImage: "battery.100",
            placementHint: "Start with the battery — it drives the whole circuit.",
            setUpInstruction: "Connect the battery into the circuit, positive terminal to the switch.",
            usageDescription: "Supplies the e.m.f. that drives current around the circuit."
        ),
        LabApparatusItem(
            id: "switch", name: "Switch", systemImage: "power",
            placementHint: "The switch connects right after the battery.",
            setUpInstruction: "Wire the switch in series with the battery, kept open until ready.",
            usageDescription: "Allows the circuit to be opened between readings, preventing unnecessary heating of the resistor."
        ),
        LabApparatusItem(
            id: "rheostat", name: "Rheostat", systemImage: "slider.horizontal.3",
            placementHint: "The rheostat goes in series, after the switch.",
            setUpInstruction: "Connect the rheostat in series, using it to vary the circuit current.",
            usageDescription: "A variable resistor used to change the current through the circuit for each trial."
        ),
        LabApparatusItem(
            id: "ammeter", name: "Ammeter", systemImage: "gauge.with.needle",
            placementHint: "The ammeter must be in series with the resistor, so it needs the rheostat wired first.",
            setUpInstruction: "Connect the ammeter in series with the resistor under test.",
            precision: "0.01 A", uncertainty: "\u{00B1}0.02 A",
            usageDescription: "Measures the current I flowing through the resistor. Must always be connected in series."
        ),
        LabApparatusItem(
            id: "voltmeter", name: "Voltmeter", systemImage: "gauge.with.needle.fill",
            placementHint: "The voltmeter connects across the resistor only once the rest of the circuit is complete.",
            setUpInstruction: "Connect the voltmeter in parallel across the resistor under test.",
            precision: "0.1 V", uncertainty: "\u{00B1}0.1 V",
            usageDescription: "Measures the potential difference V across the resistor. Must always be connected in parallel."
        ),
        LabApparatusItem(
            id: "resistor", name: "Resistor under test", systemImage: "poweroutlet.type.b.fill",
            placementHint: "The resistor is the component being investigated — connect it last, with the meters already around it.",
            setUpInstruction: "Place the resistor in the main circuit loop, with the ammeter in series and voltmeter in parallel across it.",
            usageDescription: "The component whose resistance R = V/I is being determined."
        ),
    ]

    let practicalQuestions: [ExperimentQuestion] = [
        ExperimentQuestion(
            id: "precaution",
            prompt: "State one precaution you should take in this experiment.",
            modelAnswerKeywords: ["switch off", "open circuit", "heating", "parallax", "eye level", "check connections", "loose"],
            modelAnswer: "Only close the switch briefly to take a reading, then open it again, to avoid the resistor heating up and its resistance changing.",
            marks: 2
        ),
        ExperimentQuestion(
            id: "ammeter_series",
            prompt: "Why must the ammeter be connected in series, not in parallel?",
            modelAnswerKeywords: ["low resistance", "same current", "measures current", "in the path", "full current"],
            modelAnswer: "The ammeter has a very low resistance and must carry the full circuit current, so it is connected in series so that all the current passes through it.",
            marks: 2
        ),
        ExperimentQuestion(
            id: "voltmeter_parallel",
            prompt: "Why must the voltmeter be connected in parallel across the resistor?",
            modelAnswerKeywords: ["high resistance", "same p.d.", "measures voltage", "across", "minimal current"],
            modelAnswer: "The voltmeter has a very high resistance so it draws negligible current, and being in parallel means it reads the same potential difference as exists across the resistor.",
            marks: 2
        ),
    ]

    let conclusionOptions = [
        "Current is directly proportional to voltage across the resistor, consistent with V = IR (Ohm's Law).",
        "Current is independent of the voltage across the resistor.",
        "Current decreases as the voltage across the resistor increases.",
        "Voltage depends only on the length of the connecting wires.",
    ]
    let correctConclusionIndex = 0

    // Pentagon loop, same component ids/icons as `apparatusItems` above so
    // the shelf chips match what the student already met in Stage 2.
    let circuitWiringTask: CircuitWiringTask? = CircuitWiringTask(
        components: [
            CircuitComponent(id: "cell", name: "Battery", systemImage: "battery.100"),
            CircuitComponent(id: "switch", name: "Switch", systemImage: "power"),
            CircuitComponent(id: "rheostat", name: "Rheostat", systemImage: "slider.horizontal.3"),
            CircuitComponent(id: "ammeter", name: "Ammeter", systemImage: "gauge.with.needle"),
            CircuitComponent(id: "voltmeter", name: "Voltmeter", systemImage: "gauge.with.needle.fill"),
            CircuitComponent(id: "resistor", name: "Resistor", systemImage: "poweroutlet.type.b.fill"),
        ],
        slots: [
            CircuitSlot(id: "cell", kind: .series, correctComponentID: "cell", position: CGPoint(x: 0.5, y: 0.15)),
            CircuitSlot(id: "switch", kind: .series, correctComponentID: "switch", position: CGPoint(x: 0.86, y: 0.39)),
            CircuitSlot(id: "ammeter", kind: .series, correctComponentID: "ammeter", position: CGPoint(x: 0.72, y: 0.78)),
            CircuitSlot(id: "resistor", kind: .series, correctComponentID: "resistor", position: CGPoint(x: 0.28, y: 0.78)),
            CircuitSlot(id: "rheostat", kind: .series, correctComponentID: "rheostat", position: CGPoint(x: 0.14, y: 0.39)),
            CircuitSlot(id: "voltmeter", kind: .parallel, correctComponentID: "voltmeter", position: CGPoint(x: 0.5, y: 0.62), parallelAcrossSlotID: "resistor"),
        ]
    )
}

struct OhmsLawVirtualLabView: View {
    let curriculum: Curriculum
    let repository: AttemptRepository
    @State private var workflowViewModel: VirtualLabWorkflowViewModel

    init(curriculum: Curriculum, repository: AttemptRepository) {
        self.curriculum = curriculum
        self.repository = repository
        _workflowViewModel = State(initialValue: VirtualLabWorkflowViewModel(
            experiment: OhmsLawVirtualLabExperiment(),
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum)
        ))
    }

    var body: some View {
        VirtualLabWorkflowView(viewModel: workflowViewModel) {
            OhmsLawLabView(
                curriculum: curriculum,
                repository: repository,
                onFinished: { result in
                    workflowViewModel.coreExperimentFinished(result)
                }
            )
        }
    }
}
