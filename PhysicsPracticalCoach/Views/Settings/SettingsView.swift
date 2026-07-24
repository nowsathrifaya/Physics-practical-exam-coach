//
//  SettingsView.swift
//  PhysicsPracticalCoach
//
//  Replaces `SettingsFragment`. Curriculum switcher, reset-progress action,
//  and app info — laid out as a native grouped Settings-style list.
//

import SwiftUI

struct SettingsView: View {
    let homeViewModel: HomeViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showResetConfirmation = false
    @State private var soundEffectsEnabled = true
    @State private var examDate: Date?
    @State private var isEditingExamDate = false

    var body: some View {
        List {
            Section("Curriculum") {
                NavigationLink {
                    CurriculumPickerView(homeViewModel: homeViewModel, isOnboarding: false)
                } label: {
                    HStack {
                        Text("Current curriculum")
                        Spacer()
                        Text(CurriculumProfiles.forCurriculum(homeViewModel.curriculum).homeHeadlineLine1)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                if isEditingExamDate {
                    DatePicker(
                        "Exam date",
                        selection: Binding(get: { examDate ?? Date() }, set: { examDate = $0 }),
                        in: Date()...,
                        displayedComponents: .date
                    )
                    HStack {
                        Button("Cancel") { isEditingExamDate = false; examDate = ExamDateStore.get() }
                        Spacer()
                        Button("Save") {
                            ExamDateStore.set(examDate)
                            isEditingExamDate = false
                        }
                        .fontWeight(.semibold)
                    }
                } else if let examDate {
                    HStack {
                        Text("Exam date")
                        Spacer()
                        Text(examDate.formatted(date: .abbreviated, time: .omitted)).foregroundStyle(.secondary)
                    }
                    .onTapGesture { isEditingExamDate = true }
                    Button("Clear exam date", role: .destructive) {
                        ExamDateStore.set(nil)
                        self.examDate = nil
                    }
                } else {
                    Button("Set exam date") {
                        examDate = Date()
                        isEditingExamDate = true
                    }
                }
            } header: {
                Text("Exam Countdown")
            } footer: {
                Text("Set this once and Home will show how many days you have left to prepare.")
            }

            Section("Feedback") {
                Toggle("Sound effects", isOn: $soundEffectsEnabled)
                    .onChange(of: soundEffectsEnabled) { _, newValue in
                        SoundManager.shared.isEnabled = newValue
                        if newValue {
                            SoundManager.shared.play(.tap)
                        }
                    }
            }

            Section("Data") {
                Button("Reset all progress", role: .destructive) {
                    showResetConfirmation = true
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.appVersionString).foregroundStyle(.secondary)
                }
                Text("All practice questions and simulations are generated on-device \u{2014} no account or internet connection required.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            soundEffectsEnabled = SoundManager.shared.isEnabled
            examDate = ExamDateStore.get()
        }
        .alert("Reset all progress?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                AttemptRepository(modelContext: modelContext).resetAllProgress()
                homeViewModel.refreshStats()
            }
        } message: {
            Text("This deletes every recorded attempt. This action cannot be undone.")
        }
    }
}

extension Bundle {
    var appVersionString: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
