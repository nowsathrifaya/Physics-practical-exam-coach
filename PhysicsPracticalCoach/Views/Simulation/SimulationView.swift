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
//  Built on the Lab framework: Pendulum, Hooke's Law (Spring), Ohm's Law,
//  Density by Displacement, Moments, Potentiometer, Lens, Refraction,
//  Resistance Wire, Vernier Caliper, Cooling Curve, and Filament Lamp —
//  every curriculum simulation type now has a full Lab build. See
//  `LAB_FRAMEWORK.md` for the architecture and the full
//  experiment-by-experiment history. `GenericSimulationView` (the
//  slider-driven placeholder below) is kept as a safety-net fallback for
//  any future simulation type added without an immediate Lab build, not
//  because anything currently routes to it.
//

import SwiftUI

struct SimulationListView: View {
    let profile: CurriculumProfile
    @Environment(\.modelContext) private var modelContext

    /// Experiment types that have a full Lab-framework build — derived
    /// from the same registry `SimulationDestinationView` routes through,
    /// so this list and the actual routing can never drift out of sync
    /// the way two independently-maintained lists could.
    private static var labBuiltTypes: Set<SimulationType> { Set(SimulationDestinationView.registry.keys) }

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
        .navigationTitle("\u{1F9EA} Virtual Lab Experiments")
    }

    @ViewBuilder
    private func simulationDestination(for type: SimulationType) -> some View {
        SimulationDestinationView(type: type, curriculum: profile.curriculum)
    }
}

/// Resolves a `SimulationType` to its concrete lab view. Shared by
/// `SimulationListView`, the Home screen's Continue-Learning card, Random
/// Experiment quick action, and the Daily Practical Challenge banner, so
/// there's exactly one place that maps experiment types to their views.
///
/// Routes through a static registry rather than a `switch` — adding a new
/// Lab experiment is now one line in `registry` below, rather than a new
/// `case` here *and* a separate entry in `SimulationListView`'s old
/// `labBuiltTypes` set (that duplication is what actually motivated this
/// change: the two lists could silently drift out of sync).
struct SimulationDestinationView: View {
    let type: SimulationType
    let curriculum: Curriculum
    @Environment(\.modelContext) private var modelContext

    /// Every experiment type with a full Lab-framework build, mapped to a
    /// factory that constructs its concrete view. Every `XxxVirtualLabView`
    /// already shares the exact same `init(curriculum:repository:)` shape,
    /// so this is a straightforward type-erased lookup table — no new
    /// protocol needed, and none of the 12 existing view files change.
    static let registry: [SimulationType: (Curriculum, AttemptRepository) -> AnyView] = [
        .pendulum: { curriculum, repository in AnyView(PendulumVirtualLabView(curriculum: curriculum, repository: repository)) },
        .springExtension: { curriculum, repository in AnyView(SpringVirtualLabView(curriculum: curriculum, repository: repository)) },
        .ohmsLaw: { curriculum, repository in AnyView(OhmsLawVirtualLabView(curriculum: curriculum, repository: repository)) },
        .densityDisplacement: { curriculum, repository in AnyView(DensityVirtualLabView(curriculum: curriculum, repository: repository)) },
        .moments: { curriculum, repository in AnyView(MomentsVirtualLabView(curriculum: curriculum, repository: repository)) },
        .potentiometer: { curriculum, repository in AnyView(PotentiometerVirtualLabView(curriculum: curriculum, repository: repository)) },
        .lensFocusing: { curriculum, repository in AnyView(LensVirtualLabView(curriculum: curriculum, repository: repository)) },
        .refraction: { curriculum, repository in AnyView(RefractionVirtualLabView(curriculum: curriculum, repository: repository)) },
        .resistanceWire: { curriculum, repository in AnyView(ResistanceWireVirtualLabView(curriculum: curriculum, repository: repository)) },
        .vernierCaliper: { curriculum, repository in AnyView(VernierCaliperVirtualLabView(curriculum: curriculum, repository: repository)) },
        .coolingCurve: { curriculum, repository in AnyView(CoolingCurveVirtualLabView(curriculum: curriculum, repository: repository)) },
        .filamentLamp: { curriculum, repository in AnyView(FilamentLampVirtualLabView(curriculum: curriculum, repository: repository)) },
    ]

    var body: some View {
        let repository = AttemptRepository(modelContext: modelContext)
        if let factory = Self.registry[type] {
            factory(curriculum, repository)
        } else {
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
