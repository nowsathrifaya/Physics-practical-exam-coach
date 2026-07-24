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

                apparatus()
                    .frame(height: apparatusHeight)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

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
