//
//  LabComponents.swift
//  PhysicsPracticalCoach
//
//  The reusable UI shell every lab experiment plugs into, plus the shared
//  building blocks (data table, feedback card, instruction banner) so a new
//  experiment only has to write its own apparatus Canvas/DragGesture view
//  and its own grading logic — never a new screen layout from scratch.
//
//  ANDROID PORTING NOTE: `LabScaffoldView` corresponds to a Compose
//  `@Composable fun LabScaffold(title, instructionText, apparatus: @Composable
//  () -> Unit, controls: @Composable () -> Unit, readings, result)` with the
//  exact same slot structure. Keeping the slot order (apparatus -> controls
//  -> data table -> feedback) identical on both platforms means a student
//  moving between a Kotlin and Swift build of the same experiment sees the
//  same screen shape.
//

import SwiftUI

/// The standard screen shape for every lab experiment: apparatus area,
/// contextual controls, a growing data table of recorded trials, and a
/// feedback card once graded. Concrete experiments supply the apparatus and
/// controls as view builders; everything else (layout, spacing, background,
/// nav title) is handled once, here.
struct LabScaffoldView<Apparatus: View, Controls: View>: View {
    let title: String
    let instructionText: String
    let apparatusHeight: CGFloat
    @ViewBuilder var apparatus: () -> Apparatus
    @ViewBuilder var controls: () -> Controls
    var readings: [LabReading] = []
    var result: LabRunResult? = nil

    init(
        title: String,
        instructionText: String,
        apparatusHeight: CGFloat = 340,
        readings: [LabReading] = [],
        result: LabRunResult? = nil,
        @ViewBuilder apparatus: @escaping () -> Apparatus,
        @ViewBuilder controls: @escaping () -> Controls
    ) {
        self.title = title
        self.instructionText = instructionText
        self.apparatusHeight = apparatusHeight
        self.readings = readings
        self.result = result
        self.apparatus = apparatus
        self.controls = controls
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                LabInstructionBanner(text: instructionText)

                ZoomableApparatusView(height: apparatusHeight, content: apparatus)
                    .frame(maxWidth: .infinity)

                controls()

                if !readings.isEmpty {
                    LabDataTableView(readings: readings)
                }

                if let result {
                    LabFeedbackCard(result: result)
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Wraps any apparatus canvas with a zoom toggle: a button below it
/// expands the exact same content into a larger, scrollable frame so
/// students can zoom in to read dials, rulers, and scales precisely, then
/// zoom back out. Added once here so every lab experiment gets it for
/// free, rather than touching each lab file individually.
///
/// Deliberately a toggle-into-a-bigger-scrollable-frame, not a pinch
/// gesture — several labs already have their own drag interactions on
/// this same canvas (rheostat sliders, jockey contacts, angle-setting
/// drags), and layering a pinch/pan gesture on top would risk fighting
/// with those for the same touch. This approach changes nothing about
/// those gestures; it just makes the canvas itself bigger to scroll
/// around in. Those gestures were promoted to `.highPriorityGesture` so
/// they keep priority over the ScrollView's own pan gesture once zoomed.
private struct ZoomableApparatusView<Content: View>: View {
    let height: CGFloat
    @ViewBuilder var content: () -> Content
    @State private var isZoomed = false

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { outerGeo in
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    content()
                        .frame(
                            width: outerGeo.size.width * (isZoomed ? 1.8 : 1),
                            height: outerGeo.size.height * (isZoomed ? 1.8 : 1)
                        )
                }
                .scrollDisabled(!isZoomed)
            }
            .frame(height: height)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isZoomed.toggle() }
            } label: {
                Label(isZoomed ? "Zoom out" : "Zoom in to take readings", systemImage: isZoomed ? "minus.magnifyingglass" : "plus.magnifyingglass")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.bordered)
        }
    }
}

/// Subheadline instruction text shown above the apparatus — every
/// experiment's phase/step instructions render through this, so styling
/// only needs to change in one place.
struct LabInstructionBanner: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
}

/// Generic recorded-trials table. Renders trial number, label, value+unit,
/// and (if present) a derived column — e.g. raw oscillation time next to
/// the period it implies. Every experiment's readings render through this
/// unchanged; only the `LabReading` values differ.
struct LabDataTableView: View {
    let readings: [LabReading]

    private var hasDerivedColumn: Bool { readings.contains { $0.derivedValue != nil } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recorded trials")
                .font(.subheadline.weight(.semibold))
                .padding(.bottom, 8)

            headerRow

            ForEach(readings) { reading in
                dataRow(reading)
                if reading.id != readings.last?.id {
                    Divider()
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var headerRow: some View {
        HStack {
            Text("Trial").font(.caption.weight(.semibold)).frame(width: 44, alignment: .leading)
            Text("Reading").font(.caption.weight(.semibold)).frame(maxWidth: .infinity, alignment: .leading)
            if hasDerivedColumn {
                Text("Derived").font(.caption.weight(.semibold)).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .foregroundStyle(.secondary)
        .padding(.bottom, 6)
    }

    private func dataRow(_ reading: LabReading) -> some View {
        HStack(alignment: .top) {
            Text("\(reading.trialNumber)").frame(width: 44, alignment: .leading)
            VStack(alignment: .leading, spacing: 1) {
                Text(reading.label).font(.caption2).foregroundStyle(.secondary)
                Text(String(format: "%.2f %@", reading.value, reading.unit))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if hasDerivedColumn {
                if let derived = reading.derivedValue, let unit = reading.derivedUnit {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(reading.derivedLabel ?? "").font(.caption2).foregroundStyle(.secondary)
                        Text(String(format: "%.3f %@", derived, unit))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("\u{2014}").frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .font(.subheadline)
        .padding(.vertical, 4)
    }
}

/// Small "Trial 1 ✓ Trial 2 ✓ ... Trial 5" checklist so the student always
/// knows how many readings are left before the recommended minimum, rather
/// than only finding out from the readings table or the final feedback.
/// Shared across labs (first used by Refraction, now Resistance Wire too)
/// since it's generic trial-tracking UI, not lab-specific physics — unlike
/// each lab's own `DialGaugeView` copy, which stays lab-local by design.
struct TrialProgressView: View {
    let completed: Int
    let target: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...target, id: \.self) { trial in
                HStack(spacing: 3) {
                    Image(systemName: trial <= completed ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(trial <= completed ? Color(hex: "#2E7D32") : .secondary)
                    Text("\(trial)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .font(.caption)
    }
}

/// Pass/fail feedback card — visually identical to the cards used in
/// Apparatus and Graph Coach practice, so grading always looks the same
/// regardless of which mode produced it.
struct LabFeedbackCard: View {
    let result: LabRunResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(
                result.correct ? "Within tolerance" : "Outside tolerance",
                systemImage: result.correct ? "checkmark.circle.fill" : "xmark.circle.fill"
            )
            .font(.headline)
            .foregroundStyle(result.correct ? .green : .red)

            ForEach(result.feedback, id: \.self) { line in
                Text(line).font(.footnote)
            }

            Divider()
            Text("Exam tip: \(result.examTip)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((result.correct ? Color.green : Color.red).opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
