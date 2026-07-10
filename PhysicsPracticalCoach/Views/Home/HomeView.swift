//
//  HomeView.swift
//  PhysicsPracticalCoach
//
//  Replaces `HomeFragment` / `fragment_home.xml`. Shows the curriculum
//  headline, quick stats, a "Continue learning" card resolved via
//  `ContinueLearningResolver`, and quick-action entry points into each mode.
//

import SwiftUI

/// Destination for the "Random Practice" quick action, which on Android
/// picks uniformly at random among: a random apparatus, a random graph
/// type, or the ACE list — re-rolled fresh each tap.
enum RandomPracticeDestination: Hashable {
    case apparatus(ApparatusType)
    case graph(GraphCoachType)
    case aceList
}

struct HomeView: View {
    @Bindable var homeViewModel: HomeViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var randomDestination: RandomPracticeDestination?

    private var profile: CurriculumProfile { CurriculumProfiles.forCurriculum(homeViewModel.curriculum) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                ContinueLearningCard(homeViewModel: homeViewModel, profile: profile)

                statsRow

                quickActionsRow

                Text("Quick actions")
                    .font(.title3.bold())
                    .padding(.top, 4)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    NavigationLink {
                        ApparatusListView(profile: profile)
                    } label: {
                        QuickActionCard(title: "Apparatus", subtitle: "\(profile.apparatus.count) instruments", systemImage: "ruler.fill", tint: .blue)
                    }
                    NavigationLink {
                        GraphCoachListView(profile: profile)
                    } label: {
                        QuickActionCard(title: "Graph Coach", subtitle: "\(profile.graphTypes.count) graph types", systemImage: "chart.xyaxis.line", tint: .purple)
                    }
                    NavigationLink {
                        SimulationListView(profile: profile)
                    } label: {
                        QuickActionCard(title: "Simulations", subtitle: "\(profile.simulations.count) experiments", systemImage: "flask.fill", tint: .teal)
                    }
                    NavigationLink {
                        AceListView(curriculum: homeViewModel.curriculum)
                    } label: {
                        QuickActionCard(title: "ACE Practice", subtitle: "Exam technique", systemImage: "checkmark.seal.fill", tint: .orange)
                    }
                }

                curriculumSummary
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { homeViewModel.refreshStats() }
        .navigationDestination(item: $randomDestination) { destination in
            switch destination {
            case .apparatus(let type):
                ApparatusPracticeContainerView(apparatusType: type, curriculum: homeViewModel.curriculum)
            case .graph(let type):
                GraphCoachPracticeContainerView(graphType: type, curriculum: homeViewModel.curriculum)
            case .aceList:
                AceListView(curriculum: homeViewModel.curriculum)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(profile.homeHeadlineLine1)
                .font(.largeTitle.bold())
            Text(profile.homeHeadlineLine2)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var statsRow: some View {
        let stats = homeViewModel.userStats
        return HStack(spacing: 12) {
            StatPill(value: "\(stats.streakDays)", label: "Day streak", systemImage: "flame.fill")
            StatPill(value: "\(stats.totalPoints)", label: "Points", systemImage: "star.fill")
            StatPill(value: "\(stats.accuracyPercent)%", label: "Accuracy", systemImage: "target")
        }
    }

    /// Mirrors Android's Home top-row action cards: Random Practice (rolls a
    /// fresh random apparatus/graph/ACE destination each tap) and Mock Exam
    /// (jumps straight into a timed ACE session sized to this curriculum's
    /// paper duration). "Last Experiment" is covered by `ContinueLearningCard`
    /// above rather than duplicated here.
    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            Button {
                randomDestination = rollRandomPracticeDestination()
            } label: {
                QuickActionCard(title: "Random\nPractice", subtitle: "", systemImage: "die.face.5.fill", tint: Color(hex: "#0F5A4F"))
            }
            .buttonStyle(.plain)

            NavigationLink {
                AcePracticeSessionView(
                    repository: AttemptRepository(modelContext: modelContext),
                    curriculum: homeViewModel.curriculum, filterTopic: nil, filterSkill: nil,
                    isMockExam: true, mockExamMinutes: profile.durationMinutes
                )
            } label: {
                QuickActionCard(title: "Mock\nExam", subtitle: "\(profile.durationMinutes) min timed", systemImage: "timer", tint: Color(hex: "#9B51E0"))
            }
        }
    }

    private func rollRandomPracticeDestination() -> RandomPracticeDestination {
        var options: [() -> RandomPracticeDestination] = []
        if !profile.apparatus.isEmpty {
            options.append { .apparatus(profile.apparatus.randomElement()!) }
        }
        if !profile.graphTypes.isEmpty {
            options.append { .graph(profile.graphTypes.randomElement()!) }
        }
        options.append { .aceList }
        return options.randomElement()!()
    }

    private var curriculumSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(profile.examBoard) \u{00B7} \(profile.paperName)")
                .font(.headline)
            Text(profile.markingScheme)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(profile.toleranceNote)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ContinueLearningCard: View {
    let homeViewModel: HomeViewModel
    let profile: CurriculumProfile
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        let target = ContinueLearningResolver.resolve(homeViewModel.userStats.lastAttempt)
        let label = ContinueLearningResolver.label(homeViewModel.userStats.lastAttempt)

        Group {
            switch target {
            case .apparatus(let type):
                NavigationLink {
                    ApparatusPracticeView(
                        apparatusType: type, curriculum: homeViewModel.curriculum,
                        repository: AttemptRepository(modelContext: modelContext),
                        onSaved: { homeViewModel.refreshStats() }
                    )
                } label: {
                    ContinueCardBody(title: "Continue: \(label)", systemImage: "arrow.forward.circle.fill")
                }
            case .graph(let type):
                NavigationLink {
                    GraphCoachPracticeView(
                        graphType: type, curriculum: homeViewModel.curriculum,
                        repository: AttemptRepository(modelContext: modelContext),
                        onSaved: { homeViewModel.refreshStats() }
                    )
                } label: {
                    ContinueCardBody(title: "Continue: \(label)", systemImage: "arrow.forward.circle.fill")
                }
            case .acePractice:
                NavigationLink {
                    AceListView(curriculum: homeViewModel.curriculum)
                } label: {
                    ContinueCardBody(title: "Continue ACE practice", systemImage: "arrow.forward.circle.fill")
                }
            case .simulationLab(let type):
                NavigationLink {
                    labDestination(for: type)
                } label: {
                    ContinueCardBody(title: "Continue: \(label)", systemImage: "arrow.forward.circle.fill")
                }
            case .none:
                NavigationLink {
                    ApparatusListView(profile: profile)
                } label: {
                    ContinueCardBody(title: label, systemImage: "sparkles")
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func labDestination(for type: SimulationType) -> some View {
        let repository = AttemptRepository(modelContext: modelContext)
        switch type {
        case .pendulum:
            PendulumLabView(curriculum: homeViewModel.curriculum, repository: repository)
        case .springExtension:
            SpringLabView(curriculum: homeViewModel.curriculum, repository: repository)
        case .ohmsLaw:
            OhmsLawLabView(curriculum: homeViewModel.curriculum, repository: repository)
        case .densityDisplacement:
            DensityLabView(curriculum: homeViewModel.curriculum, repository: repository)
        case .moments:
            MomentsLabView(curriculum: homeViewModel.curriculum, repository: repository)
        default:
            SimulationListView(profile: profile)
        }
    }
}

private struct ContinueCardBody: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text("Tap to jump back in").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .padding(16)
        .foregroundStyle(.white)
        .background(LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .foregroundStyle(.white)
    }
}

private struct StatPill: View {
    let value: String
    let label: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage).foregroundStyle(.orange)
            Text(value).font(.title3.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(tint)
            Text(title).font(.headline).foregroundStyle(.primary)
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
