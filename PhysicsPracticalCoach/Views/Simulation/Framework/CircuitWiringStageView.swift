//
//  CircuitWiringStageView.swift
//  PhysicsPracticalCoach
//
//  Stage 3 for circuit-based experiments (Ohm's Law, Filament Lamp, and
//  later Resistance Wire/Potentiometer): the student drags each component
//  onto the correct position on a schematic loop, instead of the generic
//  "tap each apparatus item to confirm" checklist. Getting the ammeter or
//  voltmeter wrong shows the specific teaching message, but — per product
//  decision — a mistake doesn't block starting the experiment; it's a
//  flagged learning moment, not a hard gate.
//

import SwiftUI

struct CircuitWiringStageView: View {
    let viewModel: VirtualLabWorkflowViewModel

    /// slotID -> componentID
    @State private var placements: [String: String] = [:]
    @State private var selectedComponentID: String?
    @State private var feedbackBySlot: [String: (message: String, isCorrect: Bool)] = [:]

    private var task: CircuitWiringTask { viewModel.experiment.circuitWiringTask! }
    private var unplacedComponents: [CircuitComponent] {
        task.components.filter { component in !placements.values.contains(component.id) }
    }
    private var allSlotsFilled: Bool { placements.count == task.slots.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                LabCoachAvatar(size: 44)
                WhiteboardCard(
                    eyebrow: "Step \(LabExperimentStage.setUp.rawValue + 1)",
                    text: "Tap a component below, then tap its position on the circuit to place it."
                )
            }

            if !unplacedComponents.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(unplacedComponents) { component in
                            CircuitComponentChip(
                                component: component,
                                isSelected: selectedComponentID == component.id,
                                onTap: {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                        selectedComponentID = (selectedComponentID == component.id) ? nil : component.id
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }

            CircuitSchematicView(
                task: task,
                placements: placements,
                feedbackBySlot: feedbackBySlot,
                selectedComponentID: selectedComponentID,
                onTapSlot: { slot in handleTap(on: slot) }
            )
            .frame(height: 280)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            if !feedbackBySlot.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(task.slots.filter { feedbackBySlot[$0.id] != nil }) { slot in
                        if let note = feedbackBySlot[slot.id] {
                            Label(note.message, systemImage: note.isCorrect ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(note.isCorrect ? .green : .orange)
                        }
                    }
                }
            }

            if allSlotsFilled {
                Button("Begin Experiment") { viewModel.proceedToCoreExperiment() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            } else {
                Text("\(placements.count) of \(task.slots.count) components placed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: placements)
    }

    private func handleTap(on slot: CircuitSlot) {
        if let existingComponentID = placements[slot.id] {
            // Tapping a filled slot removes it, so a student can retry
            // after seeing the feedback, rather than being stuck once wrong.
            withAnimation {
                placements.removeValue(forKey: slot.id)
                feedbackBySlot.removeValue(forKey: slot.id)
                selectedComponentID = existingComponentID
            }
            return
        }
        guard let componentID = selectedComponentID else { return }
        let result = task.feedback(forPlacing: componentID, into: slot)
        withAnimation {
            placements[slot.id] = componentID
            feedbackBySlot[slot.id] = result
            selectedComponentID = nil
        }
        SoundManager.shared.play(result.isCorrect ? .success : .measurement)
    }
}

private struct CircuitComponentChip: View {
    let component: CircuitComponent
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: component.systemImage)
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Color.white : Color.accentColor)
                    .frame(width: 48, height: 48)
                    .background(isSelected ? Color.accentColor : Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text(component.name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 64)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Draws the schematic loop (plus the voltmeter's parallel branch stub)
/// and hosts a tappable marker at every slot position. Wire geometry and
/// slot positions are both expressed as unit-square fractions on
/// `CircuitSlot.position`, so this same view works for any circuit shape
/// a future experiment supplies.
private struct CircuitSchematicView: View {
    let task: CircuitWiringTask
    let placements: [String: String]
    let feedbackBySlot: [String: (message: String, isCorrect: Bool)]
    let selectedComponentID: String?
    let onTapSlot: (CircuitSlot) -> Void

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                Canvas { context, _ in
                    // Main loop: rounded rectangle connecting all series
                    // slot positions in order, closing back to the start.
                    let seriesSlots = task.slots.filter { $0.kind == .series }
                    if seriesSlots.count > 1 {
                        var loop = Path()
                        let points = seriesSlots.map { CGPoint(x: $0.position.x * size.width, y: $0.position.y * size.height) }
                        loop.move(to: points[0])
                        for p in points.dropFirst() { loop.addLine(to: p) }
                        loop.addLine(to: points[0])
                        context.stroke(loop, with: .color(Color(hex: "#8B9997")), lineWidth: 3)
                    }
                    // Parallel branch stub(s): a short line from the branch
                    // slot straight down to the main loop, representing the
                    // wire connecting the voltmeter across a component.
                    for slot in task.slots where slot.kind == .parallel {
                        guard let acrossID = slot.parallelAcrossSlotID,
                              let acrossSlot = task.slots.first(where: { $0.id == acrossID }) else { continue }
                        let from = CGPoint(x: slot.position.x * size.width, y: slot.position.y * size.height)
                        let to = CGPoint(x: acrossSlot.position.x * size.width, y: acrossSlot.position.y * size.height)
                        var stub = Path()
                        stub.move(to: from)
                        stub.addLine(to: to)
                        context.stroke(stub, with: .color(Color(hex: "#8B9997").opacity(0.6)), style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
                    }
                }

                ForEach(task.slots) { slot in
                    CircuitSlotMarker(
                        slot: slot,
                        placedComponent: placements[slot.id].flatMap { id in task.components.first { $0.id == id } },
                        feedback: feedbackBySlot[slot.id],
                        canAcceptTap: selectedComponentID != nil || placements[slot.id] != nil
                    )
                    .position(x: slot.position.x * size.width, y: slot.position.y * size.height)
                    .onTapGesture { onTapSlot(slot) }
                }
            }
        }
    }
}

private struct CircuitSlotMarker: View {
    let slot: CircuitSlot
    let placedComponent: CircuitComponent?
    let feedback: (message: String, isCorrect: Bool)?
    let canAcceptTap: Bool

    private var borderColor: Color {
        guard let feedback else { return canAcceptTap ? .accentColor : Color(.tertiaryLabel) }
        return feedback.isCorrect ? .green : .orange
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.systemBackground))
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(borderColor, style: StrokeStyle(lineWidth: 2, dash: placedComponent == nil ? [4, 3] : []))
                )

            if let placedComponent {
                Image(systemName: placedComponent.systemImage)
                    .font(.system(size: 18))
                    .foregroundStyle(feedback?.isCorrect == false ? .orange : .primary)
            } else {
                Image(systemName: "plus")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
