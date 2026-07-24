//
//  LensVirtualLab.swift
//  PhysicsPracticalCoach
//
//  "Virtual Lab Experiment" wiring for the Converging Lens practical — same
//  pattern as `PendulumVirtualLab.swift`: this file supplies only the
//  static config; the existing, unmodified `LensExperimentViewModel`/
//  `LensLabView` still own the actual optics and Stage 4-7 grading.
//

import SwiftUI

struct LensVirtualLabExperiment: VirtualLabExperiment {
    let title = "Converging Lens Practical"

    let aim = "To determine the focal length of a converging lens using the thin lens formula, by measuring object and image distances for several lens positions."

    let theory = "The thin lens formula is 1/f = 1/u + 1/v, where u is the object distance, v the image distance, and f the focal length. Plotting 1/v against 1/u gives a straight line with intercepts of 1/f on both axes, so f can be found from the reciprocal of the y-intercept."

    let learningOutcome = "By the end of this experiment you should be able to position a lens to set the object distance u, find the screen position that gives the sharpest image to determine v, and use a 1/v vs 1/u graph to find the focal length."

    let apparatusItems: [LabApparatusItem] = [
        LabApparatusItem(
            id: "illuminated_object", name: "Illuminated object (cross-wire)", systemImage: "lightbulb.fill",
            placementHint: "The object stays fixed at one end of the bench, so set it up first.",
            setUpInstruction: "Fix the illuminated object at one end of the optical bench.",
            usageDescription: "Provides a well-lit object whose sharp image is searched for on the screen."
        ),
        LabApparatusItem(
            id: "optical_bench", name: "Optical bench", systemImage: "ruler",
            placementHint: "The bench needs to be in place before the lens or screen can be positioned on it.",
            setUpInstruction: "Set up the graduated optical bench between the object and screen positions.",
            precision: "1 mm", uncertainty: "\u{00B1}0.5 mm",
            usageDescription: "A graduated track along which the object, lens, and screen distances are measured."
        ),
        LabApparatusItem(
            id: "lens", name: "Converging lens", systemImage: "circle.dashed",
            placementHint: "Position the lens once the object and bench are ready.",
            setUpInstruction: "Slide the lens to set a chosen object distance u from the illuminated object.",
            usageDescription: "The converging lens under test — moving it sets the object distance u for each trial."
        ),
        LabApparatusItem(
            id: "screen", name: "Screen", systemImage: "rectangle.portrait",
            placementHint: "The screen goes in last, once the lens is at its chosen position, so you can search for the sharp image.",
            setUpInstruction: "Slide the screen back and forth until the image is as sharp as possible, then read its distance v from the lens.",
            usageDescription: "Used to locate the sharpest image position, giving the image distance v."
        ),
    ]

    let practicalQuestions: [ExperimentQuestion] = [
        ExperimentQuestion(
            id: "precaution",
            prompt: "State one precaution you should take in this experiment.",
            modelAnswerKeywords: ["parallax", "eye level", "sharp image", "no parallax", "darken", "sharpest"],
            modelAnswer: "Move the screen slowly and judge sharpness by the edges of the image, checking from directly in front to avoid parallax error.",
            marks: 2
        ),
        ExperimentQuestion(
            id: "bracket_method",
            prompt: "Describe how you locate the sharpest image position for a given object distance.",
            modelAnswerKeywords: ["move screen", "either side", "bracket", "back and forth", "blurred", "sharp edges"],
            modelAnswer: "Move the screen back and forth past the position where the image looks sharpest, narrowing in from both sides (the bracket method) until the image edges are as sharp as possible.",
            marks: 2
        ),
        ExperimentQuestion(
            id: "graph_choice",
            prompt: "Why is 1/v plotted against 1/u rather than v against u directly?",
            modelAnswerKeywords: ["straight line", "linear", "1/f = 1/u + 1/v", "linearise", "not linear"],
            modelAnswer: "1/f = 1/u + 1/v is already a linear equation in 1/u and 1/v, so plotting these reciprocals gives a straight line whose intercept directly gives 1/f, unlike a curve if v were plotted against u.",
            marks: 2
        ),
    ]

    let conclusionOptions = [
        "1/v is directly related to 1/u by a straight-line graph, consistent with the thin lens formula 1/f = 1/u + 1/v.",
        "v is directly proportional to u for a converging lens.",
        "The focal length changes with the object distance used.",
        "Image distance is independent of object distance for a converging lens.",
    ]
    let correctConclusionIndex = 0
}

struct LensVirtualLabView: View {
    let curriculum: Curriculum
    let repository: AttemptRepository
    @State private var workflowViewModel: VirtualLabWorkflowViewModel

    init(curriculum: Curriculum, repository: AttemptRepository) {
        self.curriculum = curriculum
        self.repository = repository
        _workflowViewModel = State(initialValue: VirtualLabWorkflowViewModel(
            experiment: LensVirtualLabExperiment(),
            recorder: LabAttemptRecorder(repository: repository, curriculum: curriculum)
        ))
    }

    var body: some View {
        VirtualLabWorkflowView(viewModel: workflowViewModel) {
            LensLabView(
                curriculum: curriculum,
                repository: repository,
                onFinished: { result in
                    workflowViewModel.coreExperimentFinished(result)
                }
            )
        }
    }
}
