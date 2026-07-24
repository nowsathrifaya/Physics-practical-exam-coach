//
//  PracticeHubView.swift
//  PhysicsPracticalCoach
//
//  Replaces `PracticeHubFragment`. The "Practice" tab: a single screen that
//  fans out into every gradeable mode (apparatus, graph coach, ACE) plus a
//  shortcut into simulations for exploratory practice.
//

import SwiftUI

struct PracticeHubView: View {
    let homeViewModel: HomeViewModel
    private var profile: CurriculumProfile { CurriculumProfiles.forCurriculum(homeViewModel.curriculum) }

    var body: some View {
        List {
            Section("Graded practice") {
                NavigationLink {
                    ApparatusListView(profile: profile)
                } label: {
                    Label("Apparatus reading", systemImage: "ruler.fill")
                }
                NavigationLink {
                    GraphCoachListView(profile: profile)
                } label: {
                    Label("Graph Coach", systemImage: "chart.xyaxis.line")
                }
                NavigationLink {
                    AceListView(curriculum: homeViewModel.curriculum)
                } label: {
                    Label("ACE written practice", systemImage: "checkmark.seal.fill")
                }
            }

            Section("Exploratory") {
                NavigationLink {
                    SimulationListView(profile: profile)
                } label: {
                    Label("Interactive simulations", systemImage: "flask.fill")
                }
            }
        }
        .navigationTitle("Practice")
    }
}
