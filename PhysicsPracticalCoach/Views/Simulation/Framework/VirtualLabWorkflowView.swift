//
//  VirtualLabWorkflowView.swift
//  PhysicsPracticalCoach
//
//  Generic screen shell for every "Virtual Lab Experiment". Renders Stages
//  1, 2, 3, 8, 9, 10, 11 entirely from `VirtualLabExperiment`'s static
//  config; Stage 4-7 ("Perform & Record", covering the spec's Perform ->
//  Record Results -> Graph -> Calculations) is supplied by the concrete
//  experiment as its own existing Lab view via the `coreContent` builder —
//  for Pendulum this is the existing `PendulumLabView`'s content, completely
//  unmodified apart from the small `onFinished` hook added to its view model.
//

import SwiftUI

struct VirtualLabWorkflowView<CoreContent: View>: View {
    @State var viewModel: VirtualLabWorkflowViewModel
    @ViewBuilder var coreContent: () -> CoreContent

    init(viewModel: VirtualLabWorkflowViewModel, @ViewBuilder coreContent: @escaping () -> CoreContent) {
        _viewModel = State(initialValue: viewModel)
        self.coreContent = coreContent
    }

    var body: some View {
        VStack(spacing: 0) {
            progressHeader
            ScrollView {
                stageContent
                    .padding(20)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.experiment.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Stage \(viewModel.stage.stepNumber) of \(LabExperimentStage.totalSteps) \u{00B7} \(viewModel.stage.title)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ProgressView(value: Double(viewModel.stage.stepNumber), total: Double(LabExperimentStage.totalSteps))
                .tint(.accentColor)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private var stageContent: some View {
        switch viewModel.stage {
        case .introduction:
            IntroductionStageView(viewModel: viewModel)
        case .collectApparatus:
            CollectApparatusStageView(viewModel: viewModel)
        case .setUp:
            SetUpStageView(viewModel: viewModel)
        case .coreExperiment:
            coreContent()
        case .practicalQuestions:
            PracticalQuestionsStageView(viewModel: viewModel)
        case .conclusion:
            ConclusionStageView(viewModel: viewModel)
        case .results:
            ResultsStageView(viewModel: viewModel)
        case .examinerFeedback:
            ExaminerFeedbackStageView(viewModel: viewModel)
        }
    }
}

// MARK: - Stage 1: Introduction

private struct IntroductionStageView: View {
    let viewModel: VirtualLabWorkflowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(viewModel.experiment.title)
                .font(.largeTitle.bold())

            labelledSection(title: "Aim", text: viewModel.experiment.aim)
            labelledSection(title: "Theory", text: viewModel.experiment.theory)
            labelledSection(title: "Learning outcome", text: viewModel.experiment.learningOutcome)

            Button("Start Experiment") { viewModel.startExperiment() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        }
    }

    private func labelledSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(text).font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Stage 2: Collect Apparatus

/// Real drag-and-drop onto a bench zone, with a genuine ordering rule (the
/// apparatus list's own order) rather than every drop always "succeeding" —
/// dropping out of order surfaces that item's `placementHint` instead of
/// placing it, matching the spec's "do not immediately reveal the answer."
private struct CollectApparatusStageView: View {
    @Bindable var viewModel: VirtualLabWorkflowViewModel
    @State private var benchFrame: CGRect = .zero

    private var nextExpectedItem: LabApparatusItem? {
        viewModel.experiment.apparatusItems.first { !viewModel.placedApparatus.contains($0.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Drag each item onto the bench, in the order you'd actually collect it for this practical.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let hint = viewModel.apparatusHint {
                Label(hint, systemImage: "lightbulb.fill")
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            benchZone

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(viewModel.experiment.apparatusItems) { item in
                    ApparatusCard(
                        item: item,
                        isPlaced: viewModel.placedApparatus.contains(item.id),
                        benchFrame: benchFrame,
                        onDrop: { location in
                            let isCorrect = item.id == nextExpectedItem?.id
                            viewModel.placeApparatus(item, isCorrectDrop: isCorrect)
                        }
                    )
                }
            }

            if viewModel.allApparatusPlaced {
                Button("Proceed to Set Up") { viewModel.proceedToSetUp() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var benchZone: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground))
            .frame(height: 90)
            .overlay {
                VStack(spacing: 4) {
                    Image(systemName: "tray.and.arrow.down.fill").font(.title3).foregroundStyle(.secondary)
                    Text("Lab bench \u{2014} \(viewModel.placedApparatus.count)/\(viewModel.experiment.apparatusItems.count) placed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear { benchFrame = geo.frame(in: .global) }
                        .onChange(of: geo.size) { _, _ in benchFrame = geo.frame(in: .global) }
                }
            )
    }
}

private struct ApparatusCard: View {
    let item: LabApparatusItem
    let isPlaced: Bool
    let benchFrame: CGRect
    let onDrop: (CGPoint) -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var cardFrame: CGRect = .zero

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: item.systemImage)
                .font(.title2)
                .foregroundStyle(isPlaced ? Color.green : Color.accentColor)
            Text(item.name)
                .font(.caption.weight(.medium))
                .multilineTextAlignment(.center)
            if isPlaced {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .opacity(isPlaced ? 0.5 : 1)
        .offset(dragOffset)
        .background(
            GeometryReader { geo in
                Color.clear.onAppear { cardFrame = geo.frame(in: .global) }
            }
        )
        .highPriorityGesture(
            DragGesture(coordinateSpace: .global)
                .onChanged { value in
                    guard !isPlaced else { return }
                    dragOffset = value.translation
                }
                .onEnded { value in
                    guard !isPlaced else { return }
                    let dropPoint = CGPoint(x: cardFrame.midX + value.translation.width, y: cardFrame.midY + value.translation.height)
                    if benchFrame.contains(dropPoint) {
                        onDrop(dropPoint)
                    }
                    withAnimation(.spring(response: 0.3)) {
                        dragOffset = .zero
                    }
                }
        )
        .allowsHitTesting(!isPlaced)
    }
}

// MARK: - Stage 3: Set Up

private struct SetUpStageView: View {
    @Bindable var viewModel: VirtualLabWorkflowViewModel
    @State private var confirmedSteps: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Assemble the apparatus in order. Tap each step once you've done it.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(viewModel.experiment.apparatusItems) { item in
                Button {
                    confirmedSteps.insert(item.id)
                } label: {
                    HStack {
                        Image(systemName: confirmedSteps.contains(item.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(confirmedSteps.contains(item.id) ? .green : .secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name).font(.subheadline.weight(.medium))
                            Text(item.setUpInstruction).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            if confirmedSteps.count == viewModel.experiment.apparatusItems.count {
                Button("Begin Experiment") { viewModel.proceedToCoreExperiment() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Stage 8: Practical Questions

private struct PracticalQuestionsStageView: View {
    @Bindable var viewModel: VirtualLabWorkflowViewModel
    @State private var answers: [String: String] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Answer each question the way you would on the real exam paper.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(viewModel.experiment.practicalQuestions) { question in
                VStack(alignment: .leading, spacing: 8) {
                    Text(question.prompt).font(.subheadline.weight(.medium))
                    TextField("Your answer", text: Binding(
                        get: { answers[question.id] ?? "" },
                        set: { answers[question.id] = $0; viewModel.recordAnswer(for: question, text: $0) }
                    ), axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    Text("\(question.marks) mark\(question.marks == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button("Continue to Conclusion") { viewModel.proceedToConclusion() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Stage 9: Conclusion

private struct ConclusionStageView: View {
    @Bindable var viewModel: VirtualLabWorkflowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select the conclusion that best matches your results.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(Array(viewModel.experiment.conclusionOptions.enumerated()), id: \.offset) { index, option in
                Button {
                    viewModel.selectConclusion(index)
                } label: {
                    HStack {
                        Image(systemName: viewModel.conclusionSelection == index ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(viewModel.conclusionSelection == index ? Color.accentColor : Color.secondary)
                        Text(option).font(.subheadline)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Button("Finish Experiment") { viewModel.finishExperiment() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(viewModel.conclusionSelection == nil)
        }
    }
}

// MARK: - Stage 10: Results

private struct ResultsStageView: View {
    let viewModel: VirtualLabWorkflowViewModel

    private var totalScore: Int { viewModel.sectionScores.reduce(0) { $0 + $1.score } }
    private var totalMax: Int { viewModel.sectionScores.reduce(0) { $0 + $1.maxScore } }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Examiner Report").font(.title2.bold())

            VStack(spacing: 0) {
                ForEach(viewModel.sectionScores) { section in
                    HStack {
                        Text(section.section).font(.subheadline)
                        Spacer()
                        Text("\(section.score)/\(section.maxScore)").font(.subheadline.weight(.semibold))
                    }
                    .padding(.vertical, 10)
                    if section.id != viewModel.sectionScores.last?.id {
                        Divider()
                    }
                }
                Divider()
                HStack {
                    Text("Total").font(.headline)
                    Spacer()
                    Text("\(totalScore)/\(totalMax)").font(.headline)
                }
                .padding(.top, 10)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Button("View examiner feedback") { viewModel.viewExaminerFeedback() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Stage 11: Examiner Feedback

private struct ExaminerFeedbackStageView: View {
    let viewModel: VirtualLabWorkflowViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Examiner Feedback").font(.title2.bold())

            ForEach(viewModel.examinerNotes) { note in
                Label(note.text, systemImage: note.isPositive ? "checkmark.circle.fill" : "arrow.up.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(note.isPositive ? .green : .orange)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        (note.isPositive ? Color.green : Color.orange).opacity(0.1),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
            }

            Button("New attempt") { viewModel.restart() }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
        }
    }
}
