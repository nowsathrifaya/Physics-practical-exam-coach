//
//  StudyNotesView.swift
//  PhysicsPracticalCoach
//
//  Partial port of `core.model.StudyNote.kt` + `domain.notes.StudyNotesBank.kt`
//  (the Android bank has ~40 notes across 9 categories; this ships the
//  category structure plus a representative note per category so the Learn
//  tab is fully functional now, with the remaining note bodies to follow —
//  see project status notes).
//

import SwiftUI

enum StudyNoteCategory: String, CaseIterable, Identifiable {
    case instrumentPrecision, sigFigs, tabulation, graphPlotting, gradient, precautions, conclusions, planning, examFormat

    var id: String { rawValue }

    var label: String {
        switch self {
        case .instrumentPrecision: return "Instrument Precision"
        case .sigFigs: return "Significant Figures"
        case .tabulation: return "Data Tabulation"
        case .graphPlotting: return "Graph Plotting"
        case .gradient: return "Finding Gradients"
        case .precautions: return "Precautions"
        case .conclusions: return "Conclusions & Errors"
        case .planning: return "Planning Experiments"
        case .examFormat: return "Exam Format & Marking"
        }
    }

    var emoji: String {
        switch self {
        case .instrumentPrecision: return "\u{1F52C}"
        case .sigFigs: return "\u{1F522}"
        case .tabulation: return "\u{1F4CB}"
        case .graphPlotting: return "\u{1F4C8}"
        case .gradient: return "\u{1F4D0}"
        case .precautions: return "\u{26A0}\u{FE0F}"
        case .conclusions: return "\u{270D}\u{FE0F}"
        case .planning: return "\u{1F5C2}\u{FE0F}"
        case .examFormat: return "\u{1F5D2}\u{FE0F}"
        }
    }
}

struct StudyNote: Identifiable {
    let id: String
    let category: StudyNoteCategory
    let title: String
    let rule: String
    let examples: String
    let doNotDo: String
    let tip: String
}

enum StudyNotesBank {
    /// Representative note per category ported directly from the ACE
    /// "skillset document" questions bank (`sk_*` entries), which carry the
    /// same underlying rules. Full 1:1 parity with the ~40-note Android bank
    /// is tracked as a follow-up.
    static let all: [StudyNote] = [
        StudyNote(
            id: "note_precision", category: .instrumentPrecision, title: "Recording to the right precision",
            rule: "Record to the instrument's smallest division (rulers) or half the smallest division (scaled meters).",
            examples: "Metre rule (0.1 cm divisions) \u{2192} 2.0 cm, not 2 cm.\nAmmeter f.s.d. 1 A, 100 divisions \u{2192} 0.44 A, not 0.4 A.",
            doNotDo: "Dropping trailing zeros, or over-claiming precision the instrument can't give.",
            tip: "Count decimal places, not significant figures, when judging instrument precision."
        ),
        StudyNote(
            id: "note_sigfigs", category: .sigFigs, title: "Significant figures in calculations",
            rule: "A calculated answer should have the same number of significant figures as the least precise input measurement.",
            examples: "m = 120.45 g (5 s.f.), V = 45.8 cm\u{00B3} (3 s.f.) \u{2192} density quoted to 3 s.f.: 2.63 g/cm\u{00B3}.",
            doNotDo: "Copying every digit from a calculator display.",
            tip: "Find the input with the fewest s.f. first \u{2014} that sets your answer's precision."
        ),
        StudyNote(
            id: "note_tabulation", category: .tabulation, title: "Column headings use a solidus, not brackets",
            rule: "Table and axis headings are written as quantity / unit, e.g. t / s \u{2014} never t (s).",
            examples: "t / s, T\u{00B2} / s\u{00B2}, V / V, I / A",
            doNotDo: "'Time (s)' or 't(s)' \u{2014} brackets are not accepted in SEAB/Cambridge/WAEC marking.",
            tip: "Think of it as algebra: if t = 23.4 s, then t / s = 23.4, a pure number \u{2014} exactly what belongs in a data cell."
        ),
        StudyNote(
            id: "note_graphplot", category: .graphPlotting, title: "Four marks in every graph question",
            rule: "Graph marks are checked independently across four areas: best-fit line, labelled axes, correct plotting, and appropriate scale.",
            examples: "A thin best-fit line balancing points above/below; solidus-notation axis labels; neat crosses (\u{00D7}); scales in multiples of 2 or 5 spanning most of the grid.",
            doNotDo: "Joining points dot-to-dot; using scale intervals of 3 or 7; plotting dots instead of crosses.",
            tip: "You can still score 3 of 4 marks even if your line isn't perfect, as long as the other three areas are correct."
        ),
        StudyNote(
            id: "note_gradient", category: .gradient, title: "Measuring a gradient correctly",
            rule: "Pick two points ON the best-fit line (not data points), as far apart as possible, and draw a large right-angled triangle.",
            examples: "gradient = (y\u{2082} \u{2212} y\u{2081}) / (x\u{2082} \u{2212} x\u{2081}), always quoted with units.",
            doNotDo: "Using two table values instead of points on the line; a triangle spanning less than half the line.",
            tip: "Show your triangle and coordinates on the graph \u{2014} examiners look for this explicitly."
        ),
        StudyNote(
            id: "note_precautions", category: .precautions, title: "Precautions must be specific",
            rule: "State the specific action and why it improves the result \u{2014} not a generic 'be careful'.",
            examples: "'Displace the pendulum bob by a small angle (< 10\u{00B0}) to maintain simple harmonic motion.'",
            doNotDo: "'Be careful', 'take accurate readings', 'repeat the experiment' with no detail.",
            tip: "Ask yourself: does this sentence tell someone exactly what to do differently?"
        ),
        StudyNote(
            id: "note_conclusions", category: .conclusions, title: "'Proportional' has a strict meaning",
            rule: "Only say 'directly proportional' when the best-fit line is straight AND passes through the origin.",
            examples: "Straight line, non-zero y-intercept \u{2192} 'varies linearly with', not 'is proportional to'.",
            doNotDo: "Claiming proportionality just because a graph looks like a line.",
            tip: "If the origin isn't shown on the axes, you can't confirm proportionality at all."
        ),
        StudyNote(
            id: "note_planning", category: .planning, title: "Independent, dependent, controlled",
            rule: "Independent = what you deliberately change. Dependent = what you measure as a result. Controlled = everything else kept constant.",
            examples: "Spring experiment: independent = load; dependent = extension; controlled = same spring, same starting position.",
            doNotDo: "Confusing independent/dependent, or listing 'time' as a controlled variable when it isn't relevant.",
            tip: "Independent is what YOU set on purpose before each reading."
        ),
        StudyNote(
            id: "note_examformat", category: .examFormat, title: "Know your paper's mark distribution",
            rule: "Each board splits marks differently across Planning, Measurement, Data Presentation, and Analysis/Evaluation \u{2014} check your curriculum's marking scheme on the Home tab.",
            examples: "SEAB 6091: P ~6, MMO ~14, PDO ~10, ACE ~10 (40 total). WAEC/NECO: ~16-17 marks per experiment across 3 experiments.",
            doNotDo: "Spending equal time on every section regardless of its mark weight.",
            tip: "Budget your exam time roughly in proportion to each section's marks."
        )
    ]

    static func forCategory(_ category: StudyNoteCategory) -> [StudyNote] {
        all.filter { $0.category == category }
    }
}

struct StudyNotesListView: View {
    let curriculum: Curriculum

    var body: some View {
        List(StudyNoteCategory.allCases) { category in
            NavigationLink {
                StudyNoteCategoryDetailView(category: category)
            } label: {
                HStack(spacing: 12) {
                    Text(category.emoji).font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.label).font(.headline)
                        Text("\(StudyNotesBank.forCategory(category).count) note(s)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Study Notes")
    }
}

struct StudyNoteCategoryDetailView: View {
    let category: StudyNoteCategory

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(StudyNotesBank.forCategory(category)) { note in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(note.title).font(.title3.bold())
                        Text(note.rule).font(.body)
                        NoteBlock(label: "Examples", text: note.examples, tint: .blue)
                        if !note.doNotDo.isEmpty {
                            NoteBlock(label: "Don't do this", text: note.doNotDo, tint: .red)
                        }
                        if !note.tip.isEmpty {
                            NoteBlock(label: "Tip", text: note.tip, tint: .teal)
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(category.label)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct NoteBlock: View {
    let label: String
    let text: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(tint)
            Text(text).font(.footnote)
        }
    }
}
