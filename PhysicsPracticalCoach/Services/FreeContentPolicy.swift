//
//  FreeContentPolicy.swift
//  PhysicsPracticalCoach
//
//  Single source of truth for what's free vs. gated behind Full Access.
//  Deliberately centralized rather than scattered `isPro` checks, so the
//  free/paid boundary is one place to read and change, not something you
//  have to hunt for across a dozen files.
//
//  Free: Vernier Caliper and Spring (this session's most-polished labs,
//  showcasing full quality with nothing held back), Apparatus Trainer
//  (reference tool, good top-of-funnel), and Last Minute Revision (cheap
//  to give away, brings students back right before their exam — exactly
//  when they're likeliest to convert).
//
//  Everything else — the other 10 Virtual Labs, Graph Coach, ACE
//  Practice, Answering Techniques, and all Study Notes categories beyond
//  Instrument Precision — requires Full Access.
//

import Foundation

enum FreeContentPolicy {
    static let freeSimulationTypes: Set<SimulationType> = [.vernierCaliper, .springExtension]

    static let freeStudyNoteCategories: Set<StudyNoteCategory> = [.instrumentPrecision]

    static func isSimulationFree(_ type: SimulationType) -> Bool {
        freeSimulationTypes.contains(type)
    }

    static func isStudyNoteCategoryFree(_ category: StudyNoteCategory) -> Bool {
        freeStudyNoteCategories.contains(category)
    }

    /// Apparatus Trainer and Last Minute Revision are unconditionally
    /// free — no per-item check needed, they just never gate at all.
}
