//
//  LabAttemptRecorder.swift
//  PhysicsPracticalCoach
//
//  Thin, deliberately dumb wrapper around `AttemptRepository` so every lab
//  experiment records its result the same way, with the same `.simulationLab`
//  mode — this is what makes finished lab sessions show up in the Progress
//  tab's stats/streak/badges/history alongside Apparatus, Graph, and ACE
//  attempts, instead of vanishing like the old ungraded simulations did.
//
//  ANDROID PORTING NOTE: this maps directly onto a Kotlin
//  `LabAttemptRecorder(private val repository: AttemptRepository, private val
//  curriculum: Curriculum)` with one `record(...)` function — no
//  framework-specific concepts here at all.
//

import Foundation

@MainActor
struct LabAttemptRecorder {
    let repository: AttemptRepository
    let curriculum: Curriculum

    func record(experimentTitle: String, result: LabRunResult, maxScore: Int = 100) {
        repository.save(
            curriculum: curriculum,
            mode: .simulationLab,
            target: experimentTitle,
            score: result.score,
            maxScore: maxScore,
            feedback: result.feedback
        )
    }
}
