//
//  RefractionVirtualLab.swift
//  PhysicsPracticalCoach
//
//  "Virtual Lab Experiment" wiring for Refraction through a Glass Block —
//  same pattern as `PendulumVirtualLab.swift`: this file supplies only the
//  static config; the existing, unmodified `RefractionExperimentViewModel`/
//  `RefractionLabView` still own the actual optics and Stage 4-7 grading.
//

import SwiftUI

struct RefractionVirtualLabExperiment: VirtualLabExperiment {
    let title = "Refraction through a Glass Block Practical"

    let aim = "To investigate the refraction of light through a rectangular glass block and to determine the refractive index of the glass."

    let theory = "Snell's Law states that n = sin i / sin r, where i is the angle of incidence and r is the angle of refraction, both measured from the normal. Plotting sin i against sin r gives a straight line through the origin whose gradient is the refractive index n."

    let learningOutcome = "By the end of this experiment you should be able to set an angle of incidence, trace the refracted ray through a glass block, read the angle of refraction with a protractor, and use a sin i vs sin r graph to determine n."

    let apparatusItems: [LabApparatusItem] = [
        LabApparatusItem(
            id: "glass_block", name: "Rectangular glass block", systemImage: "square.fill",
            placementHint: "The glass block goes down first — the outline must be traced before any rays are drawn.",
            setUpInstruction: "Place the glass block on paper and trace around its outline.",
            usageDescription: "The transparent block whose refractive properties are being investigated."
        ),
        LabApparatusItem(
            id: "protractor", name: "Protractor", systemImage: "angle",
            placementHint: "The protractor is needed once a normal line exists at the point of incidence.",
            setUpInstruction: "Draw a normal line perpendicular to the glass surface at the point of incidence.",
            precision: "1\u{00B0}", uncertainty: "\u{00B1}1\u{00B0}",
            usageDescription: "Used to draw the normal and to measure both the angle of incidence and the angle of refraction from it."
        ),
        LabApparatusItem(
            id: "incident_ray", name: "Incident ray (light source)", systemImage: "sun.max.fill",
            placementHint: "Set the incident ray once the block outline and normal are drawn, choosing an angle of incidence.",
            setUpInstruction: "Direct the incident ray at a chosen angle of incidence i towards the point of incidence.",
            usageDescription: "A ray of light directed at the glass surface at a chosen angle i, which bends on entering the denser glass."
        ),
        LabApparatusItem(
            id: "ruler", name: "Ruler", systemImage: "ruler",
            placementHint: "Use the ruler last, to mark the emergent ray's path and join up points to find the refracted ray.",
            setUpInstruction: "Use the ruler to draw straight lines marking the path of the ray through the block.",
            usageDescription: "Used to draw straight, accurate lines showing the incident and refracted ray paths."
        ),
    ]

    let practicalQuestions: [ExperimentQuestion] = [
        ExperimentQuestion(
            id: "precaution",
            prompt: "State one precaution you should take in this experiment.",
            modelAnswerKeywords: ["thin", "sharp pencil", "eye level", "parallax", "normal", "accurately traced"],
            modelAnswer: "Use a sharp pencil to mark ray positions accurately, and view along the ray at eye level to avoid parallax error when tracing it.",
            marks: 2
        ),
        ExperimentQuestion(
            id: "measured_from_normal",
            prompt: "A student measured their angles from the glass surface instead of the normal. Explain the mistake.",
            modelAnswerKeywords: ["from the normal", "not the surface", "perpendicular", "incorrect angle", "should be from normal"],
            modelAnswer: "Angles of incidence and refraction must always be measured from the normal (perpendicular to the surface), not from the surface itself, otherwise the calculated angles \u2014 and hence n \u2014 will be wrong.",
            marks: 2
        ),
        ExperimentQuestion(
            id: "why_bends_toward_normal",
            prompt: "Explain why the ray bends towards the normal as it enters the glass block.",
            modelAnswerKeywords: ["denser medium", "slows down", "optically denser", "glass is denser", "speed decreases"],
            modelAnswer: "Glass is an optically denser medium than air, so light slows down on entering it, causing the ray to bend towards the normal.",
            marks: 2
        ),
    ]

    let conclusionOptions = [
        "sin i is directly proportional to sin r, with the gradient of the graph giving the refractive index n, consistent with Snell's Law.",
        "The angle of refraction is always equal to the angle of incidence.",
        "The angle of refraction is independent of the angle of incidence.",
        "The refractive index changes with the angle of incidence used.",
    ]
    let correctConclusionIndex = 0
}

struct RefractionVirtualLabView: View {
    let curriculum: Curriculum
    let repository: AttemptRepository
    @State private var workflowViewModel: VirtualLabWorkflowViewModel

    init(curriculum: Curriculum, repository: AttemptRepository) {
        self.curriculum = curriculum
        self.repository = repository
        _workflowViewModel = State(initialValue: VirtualLabWorkflowViewModel(
            experiment: RefractionVirtualLabExperiment(),
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum)
        ))
    }

    var body: some View {
        VirtualLabWorkflowView(viewModel: workflowViewModel) {
            RefractionLabView(
                curriculum: curriculum,
                repository: repository,
                onFinished: { result in
                    workflowViewModel.coreExperimentFinished(result)
                }
            )
        }
    }
}
