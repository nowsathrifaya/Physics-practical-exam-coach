//
//  PhysicsPracticalCoachApp.swift
//  PhysicsPracticalCoach
//
//  App entry point. Replaces `PhysicsCoachApplication.kt` + `MainActivity.kt`.
//  Wires up the SwiftData `ModelContainer` (replacing Room's
//  `PhysicsCoachDatabase.get(context)` singleton) and the shared
//  `UserPreferencesStore` (replacing the DataStore singleton), then hands
//  both down through the environment the way `AppContainer.kt` handed them
//  to Android ViewModel factories.
//

import SwiftUI
import SwiftData

@main
struct PhysicsPracticalCoachApp: App {
    let modelContainer: ModelContainer
    @State private var preferencesStore = UserPreferencesStore()

    init() {
        do {
            modelContainer = try ModelContainer(for: Attempt.self)
        } catch {
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.userPreferences, preferencesStore)
        }
        .modelContainer(modelContainer)
    }
}

// MARK: - Environment plumbing for UserPreferences

private struct UserPreferencesKey: EnvironmentKey {
    static let defaultValue: UserPreferences = UserPreferencesStore()
}

extension EnvironmentValues {
    var userPreferences: UserPreferences {
        get { self[UserPreferencesKey.self] }
        set { self[UserPreferencesKey.self] = newValue }
    }
}
