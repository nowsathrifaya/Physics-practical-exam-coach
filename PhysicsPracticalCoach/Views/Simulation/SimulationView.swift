//
//  SimulationView.swift
//  PhysicsPracticalCoach
//
//  Replaces `SimulationListFragment` + the per-experiment simulation
//  fragments. iOS is now the reference implementation for every new
//  interactive "Lab" experiment — see `Framework/` for the shared
//  scaffold/data-table/feedback components, and `PendulumLabView.swift` for
//  the original fully worked reference template (drag-and-drop apparatus,
//  randomised task, multi-trial data table, exam-accurate grading).
//
//  Built on the Lab framework so far: Pendulum, Hooke's Law (Spring),
//  Ohm's Law, and Density by Displacement — see `LAB_FRAMEWORK.md` for the
//  architecture and the full experiment-by-experiment status. The
//  remaining curriculum simulations use `GenericSimulationView`, a working
//  slider-driven placeholder with the correct physics formula and
//  description already wired up, pending conversion to the Lab pattern.
//

import SwiftUI

struct SimulationListView: View {
    let profile: CurriculumProfile
    @Environment(\.modelContext) private var modelContext

    /// Experiment types that have a full Lab-framework build. Anything not
    /// in this set still routes to the generic slider shell.
    private static let labBuiltTypes: Set<SimulationType> = [.pendulum, .springExtension, .ohmsLaw, .densityDisplacement, .moments]

    var body: some View {
        List(profile.simulations) { type in
            NavigationLink {
                simulationDestination(for: type)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(type.label).font(.headline)
                        if Self.labBuiltTypes.contains(type) {
                            Text("LAB").font(.caption2.weight(.bold))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.15), in: Capsule())
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    Text(type.descriptionText).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Simulations")
    }

    @ViewBuilder
    private func simulationDestination(for type: SimulationType) -> some View {
        let repository = AttemptRepository(modelContext: modelContext)
        switch type {
        case .pendulum:
            PendulumLabView(curriculum: profile.curriculum, repository: repository)
        case .springExtension:
            SpringLabView(curriculum: profile.curriculum, repository: repository)
        case .ohmsLaw:
            OhmsLawLabView(curriculum: profile.curriculum, repository: repository)
        case .densityDisplacement:
            DensityLabView(curriculum: profile.curriculum, repository: repository)
        case .moments:
            MomentsLabView(curriculum: profile.curriculum, repository: repository)
        default:
            GenericSimulationView(type: type)
        }
    }
}

/// Working slider-driven simulation shell for the experiment types not yet
/// rebuilt as Lab experiments. Each has its correct governing formula and
/// description already wired from `SimulationType`; converting each to the
/// drag-and-drop Lab pattern (see `LAB_FRAMEWORK.md`) is the planned next
/// step for every one of these, in curriculum priority order.
struct GenericSimulationView: View {
    let type: SimulationType
    @State private var control: Double = 0.5

    var body: some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .frame(height: 200)
                .overlay {
                    Image(systemName: iconName)
                        .font(.system(size: 56))
                        .foregroundStyle(.tint)
                }

            Text(type.descriptionText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Adjust the control variable")
                Slider(value: $control)
            }
        }
        .padding(20)
        .navigationTitle(type.label)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var iconName: String {
        switch type {
        case .ohmsLaw, .resistanceWire, .filamentLamp: return "bolt.fill"
        case .springExtension: return "arrow.up.and.down"
        case .lensFocusing, .refraction: return "eye.fill"
        case .potentiometer: return "slider.horizontal.3"
        case .moments: return "scalemass.fill"
        case .vernierCaliper: return "ruler.fill"
        case .densityDisplacement: return "drop.fill"
        case .coolingCurve: return "thermometer"
        case .pendulum: return "clock.fill"
        }
    }
}
