//
//  HomeViewModel.swift
//  PhysicsPracticalCoach
//
//  Port of `ui.viewmodel.HomeViewModel.kt`. Uses the `@Observable` macro
//  (Swift Observation framework) instead of `StateFlow` — the idiomatic
//  SwiftUI replacement that still gives every view a single source of
//  truth without manual Combine plumbing.
//

import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    private let preferences: UserPreferences
    private let attemptRepository: AttemptRepository

    var curriculum: Curriculum = .general
    var onboardingComplete: Bool?
    private(set) var attempts: [Attempt] = []

    /// Every number here is computed live from `attempts`, refreshed via `refreshStats()`.
    var userStats: UserStats {
        UserStatsCalculator.compute(attempts: attempts, profile: CurriculumProfiles.forCurriculum(curriculum))
    }

    /// Snapshot of just today's activity for the Home screen's
    /// "Today's Progress" card.
    var todayProgress: TodayProgress {
        UserStatsCalculator.computeTodayProgress(attempts: attempts)
    }

    /// Today's featured experiment for the Daily Practical Challenge banner.
    /// Deterministic per calendar day (same challenge all day, changes daily)
    /// so it isn't re-rolled on every Home screen visit.
    var dailyChallenge: SimulationType? {
        let profile = CurriculumProfiles.forCurriculum(curriculum)
        guard !profile.simulations.isEmpty else { return nil }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return profile.simulations[dayOfYear % profile.simulations.count]
    }

    init(preferences: UserPreferences, attemptRepository: AttemptRepository) {
        self.preferences = preferences
        self.attemptRepository = attemptRepository
        self.curriculum = preferences.selectedCurriculum ?? .general
        self.onboardingComplete = preferences.hasCompletedOnboarding
        refreshStats()
    }

    /// HomeViewModel outlives individual visits to the Home tab, so call this
    /// whenever Home becomes visible again to pick up attempts recorded
    /// elsewhere (matches the Android `onResume` refresh pattern).
    func refreshStats() {
        attempts = attemptRepository.fetchAttempts()
    }

    func saveCurriculum(_ curriculum: Curriculum, onSaved: () -> Void) {
        preferences.saveCurriculum(curriculum)
        self.curriculum = curriculum
        self.onboardingComplete = true
        onSaved()
    }
}
