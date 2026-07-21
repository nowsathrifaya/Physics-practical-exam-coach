//
//  AnsweringTechniquesView.swift
//  PhysicsPracticalCoach
//
//  "Answering Techniques" — a apparatus-by-apparatus reference distinct
//  from `StudyNotesView`. Where Study Notes covers general skills (sig
//  figs, tabulation, graphs), this screen drills into exactly how to read
//  each instrument, the specific errors examiners penalise for it, how to
//  fix each one, and the exact phrasing that scores the answer mark.
//

import SwiftUI

struct ApparatusError: Identifiable, Hashable {
    var id: String { error }
    let error: String
    let fix: String
    /// How many marks this mistake typically costs on the real mark
    /// scheme — shown as a star rating so a student can triage which
    /// mistakes matter most, rather than treating every error as equal.
    var marksLost: Int = 1
    /// The specific corrected value/phrasing, shown separately from
    /// `fix` (which becomes the *reason* once this is set) — e.g.
    /// error: "0.5 A", correctAnswer: "0.50 A", fix (now the reason):
    /// "Missing trailing zero loses the precision mark." When nil, the
    /// display falls back to showing just `fix` as before.
    var correctAnswer: String? = nil
}

struct AnsweringTechnique: Identifiable {
    let id: String
    let apparatus: ApparatusType
    /// The precision rule: what decimal place / division to record to, and why.
    let precision: String
    /// Step-by-step technique for taking a correct reading.
    let howToRead: [String]
    /// Specific errors examiners penalise for this instrument, each paired
    /// with how to avoid or correct it.
    let errors: [ApparatusError]
    /// The exact sentence pattern / working that scores the mark on paper.
    let howToAnswer: String
}

enum AnsweringTechniquesBank {

    static let all: [AnsweringTechnique] = [
        AnsweringTechnique(
            id: "ans_vernier", apparatus: .vernierCaliper,
            precision: "Record to 0.01 cm (2 d.p.) — the vernier scale's smallest division.",
            howToRead: [
                "Close the jaws gently on the object; don't over-tighten.",
                "Read the main scale — the whole number just before the vernier's zero mark.",
                "Find the ONE vernier line that lines up exactly with a main-scale line.",
                "That vernier line number × 0.01 cm is the fractional part — add it to the main-scale reading.",
                "Check for zero error: close the jaws fully with nothing inside and read the vernier zero position."
            ],
            errors: [
                ApparatusError(error: "Picking the wrong vernier coincidence line", fix: "Only one line ever aligns exactly — scan the whole vernier scale, don't stop at the first close match.", marksLost: 2),
                ApparatusError(error: "Ignoring zero error", fix: "This is one of the most heavily penalised mistakes on the whole paper — the examiner can't award the measurement mark at all without the correction shown.", marksLost: 4, correctAnswer: "Subtract a positive zero error (or add if negative) from every reading before you write your final answer"),
                ApparatusError(error: "2.3 cm", fix: "Vernier readings always need 2 d.p. — dropping the second digit loses the precision mark even if the first digit is right.", marksLost: 1, correctAnswer: "2.34 cm")
            ],
            howToAnswer: "Diameter = (main scale + vernier scale) − zero error = 2.40 + 0.04 − (−0.02) = 2.46 cm. Always show the subtraction of zero error explicitly — examiners award a mark just for showing that step."
        ),
        AnsweringTechnique(
            id: "ans_micrometer", apparatus: .micrometer,
            precision: "Record to 0.01 mm (2 d.p.) — the thimble's smallest division.",
            howToRead: [
                "Use the ratchet (not the thimble) to close the jaws — this avoids over-tightening the spring.",
                "Read the sleeve scale: the last fully-visible mm mark, plus 0.5 mm if that extra half-mark is visible.",
                "Read the thimble scale where it lines up with the sleeve's horizontal datum line — each division is 0.01 mm.",
                "Add sleeve + thimble reading for the total.",
                "Check zero error with the jaws fully closed on nothing."
            ],
            errors: [
                ApparatusError(error: "Missing the 0.5 mm sleeve mark", fix: "Always check whether the lower half-mm line is visible before adding the thimble reading — skipping it under-reads by exactly 0.5 mm."),
                ApparatusError(error: "Over-tightening with the thimble", fix: "Always use the ratchet stop to close the jaws — it slips at a fixed, repeatable force so you don't compress the object being measured."),
                ApparatusError(error: "Ignoring zero error", fix: "State and apply the closed-jaw zero reading before giving your final answer, exactly as with the vernier caliper.")
            ],
            howToAnswer: "Diameter = sleeve reading + thimble reading − zero error = 5.5 + 0.32 − (+0.02) = 5.80 mm. Show sleeve and thimble as two separate numbers before combining them — this is what the mark scheme checks for."
        ),
        AnsweringTechnique(
            id: "ans_ammeter", apparatus: .ammeter,
            precision: "Record to HALF the smallest division (e.g. 0.02 A divisions → record to 0.01 A).",
            howToRead: [
                "Identify the full-scale deflection (f.s.d.) and count the divisions to find what each one is worth.",
                "Position your eye directly above the pointer, perpendicular to the scale, to avoid parallax.",
                "If the meter has a mirror strip, line the pointer up with its own reflection first.",
                "Interpolate between divisions to the correct precision — don't just round to the nearest marked line.",
                "Double-check you're reading the correct range if the meter has more than one scale."
            ],
            errors: [
                ApparatusError(error: "Parallax error", fix: "View the pointer square-on, not from an angle — use the mirror strip if the meter has one.", marksLost: 2),
                ApparatusError(error: "Wrong scale range read", fix: "Confirm which f.s.d. (e.g. 0–1 A vs 0–5 A) the circuit is actually using before you read off the number.", marksLost: 2),
                ApparatusError(error: "0.5 A", fix: "Missing trailing zero loses the precision mark.", marksLost: 1, correctAnswer: "0.50 A")
            ],
            howToAnswer: "I = 0.44 A. State the reading with the trailing decimal place that matches the instrument's precision, and note the range used if the question asks for it (e.g. 'read on the 0–1 A scale')."
        ),
        AnsweringTechnique(
            id: "ans_voltmeter", apparatus: .voltmeter,
            precision: "Record to HALF the smallest division (e.g. 0.1 V divisions → record to 0.05 V).",
            howToRead: [
                "Check which of the meter's scales (e.g. 3 V or 5 V range) is being used for this reading.",
                "Line your eye up perpendicular to the pointer to avoid parallax.",
                "Interpolate between the marked divisions to half a division's precision.",
                "Cross-check the reading makes physical sense against the circuit's supply voltage."
            ],
            errors: [
                ApparatusError(error: "Reading the wrong dual scale", fix: "Dual-range voltmeters (3 V/5 V) look almost identical — always confirm which range the selector switch is set to before reading.", marksLost: 3),
                ApparatusError(error: "Parallax error", fix: "Keep your eye level with, and directly in front of, the pointer.", marksLost: 2),
                ApparatusError(error: "1.2 V", fix: "The extra digit shows the correct precision of the instrument — a smallest division of 0.1 V means the answer must be recorded to 0.05 V.", marksLost: 1, correctAnswer: "1.20 V")
            ],
            howToAnswer: "V = 1.20 V. If the question gives both current and voltage, show R = V/I as a separate working line — many mark schemes give a mark just for showing the substitution, not only the final number."
        ),
        AnsweringTechnique(
            id: "ans_newton", apparatus: .newtonMeter,
            precision: "Record to 0.1 N (1 d.p.) unless the scale shows finer divisions.",
            howToRead: [
                "Check the pointer reads exactly zero before hanging anything — adjust the zero-set screw if it doesn't.",
                "Always hold the newton-meter vertically, never horizontally.",
                "Let the reading settle before recording it — don't read while the mass is still swinging.",
                "Read at eye level, perpendicular to the scale."
            ],
            errors: [
                ApparatusError(error: "Not zeroed before use", fix: "State explicitly that you checked/adjusted the zero before taking readings — this is often a dedicated method mark."),
                ApparatusError(error: "Held horizontally", fix: "Always use the newton-meter hanging vertically; horizontal use introduces friction against the internal spring guide and under-reads the force."),
                ApparatusError(error: "Reading while swinging", fix: "Steady the mass with your hand first, then release and wait for the pointer to settle before reading.")
            ],
            howToAnswer: "Weight = 2.4 N. If asked for a precaution, write the specific one that applies here: 'ensure the newton-meter hangs vertically and is zeroed before each reading' — generic answers like 'be careful' score zero."
        ),
        AnsweringTechnique(
            id: "ans_stopwatch", apparatus: .stopwatch,
            precision: "Record to 0.1 s (fast single events) or the display's finest digit for longer/multiple oscillations.",
            howToRead: [
                "Start timing exactly as the event begins (e.g. the pendulum passes the fixed reference point).",
                "Time multiple oscillations (e.g. 20) rather than just one, then divide, to reduce the effect of your reaction-time error.",
                "Always convert the mm:ss.t display to total seconds before using the number in a calculation.",
                "Repeat each timing at least twice and average."
            ],
            errors: [
                ApparatusError(error: "Not converting mm:ss.t to seconds", fix: "1:23.4 on the display means 83.4 s, not 123.4 s — always convert minutes × 60 + seconds before writing your final value."),
                ApparatusError(error: "Timing only one oscillation", fix: "Time a larger number of oscillations (commonly 20) and divide, so your reaction-time error is spread across many cycles instead of dominating a single one."),
                ApparatusError(error: "Different starting/stopping references each trial", fix: "Always start and stop at the same visual reference point (e.g. the pendulum passing the centre) for every repeat.")
            ],
            howToAnswer: "t₂₀ = 23.2 s → T = 23.2 / 20 = 1.16 s. Show the raw stopwatch time AND the divided period as two separate lines — the division step itself often carries its own mark."
        ),
        AnsweringTechnique(
            id: "ans_thermometer", apparatus: .thermometer,
            precision: "Record to 0.5 °C or 0.1 °C (1 d.p.) depending on the thermometer's smallest division.",
            howToRead: [
                "Position your eye level with the top of the liquid column (the meniscus) to avoid parallax.",
                "Leave the thermometer in the liquid long enough to reach thermal equilibrium before reading.",
                "Don't let the bulb touch the sides or base of the container — that reads the container's temperature, not the liquid's.",
                "Interpolate between the marked divisions to half a division."
            ],
            errors: [
                ApparatusError(error: "Parallax error", fix: "Read with your eye level with the liquid meniscus, not looking down or up at the scale."),
                ApparatusError(error: "Reading before equilibrium", fix: "Wait for the reading to stabilise — a thermometer lags behind the true temperature for several seconds after a change."),
                ApparatusError(error: "Bulb touching the container", fix: "Suspend the bulb in the middle of the liquid, away from the glass walls and the heat source.")
            ],
            howToAnswer: "θ = 37.0 °C. If asked to justify precision, state the smallest division explicitly: 'the thermometer has divisions of 1 °C, so readings are recorded to the nearest 0.5 °C.'"
        ),
        AnsweringTechnique(
            id: "ans_cylinder", apparatus: .measuringCylinder,
            precision: "Record to 0.5 cm³ (1 d.p.) — half the smallest marked division.",
            howToRead: [
                "Place the cylinder on a flat, level surface before reading.",
                "Bend down so your eye is level with the bottom of the meniscus.",
                "Read from the BASE of the curved meniscus, not the top of the curve.",
                "For an opaque or coloured liquid where the meniscus is hard to see, read at the point where the liquid surface appears flat."
            ],
            errors: [
                ApparatusError(error: "Reading the top of the meniscus", fix: "Always read from the bottom (lowest point) of the curved surface for water and most aqueous solutions."),
                ApparatusError(error: "Eye not level with the liquid", fix: "Crouch down to bring your eye level with the meniscus rather than reading from above, which causes parallax."),
                ApparatusError(error: "Rounding to the nearest whole cm³", fix: "Interpolate to the nearest half-division (0.5 cm³) instead of the nearest full marked line.")
            ],
            howToAnswer: "Volume of water displaced = 80.0 − 65.5 = 14.5 cm³. Always show both readings (before and after) and the subtraction, not just the final volume — each is checked separately."
        ),
        AnsweringTechnique(
            id: "ans_burette", apparatus: .burette,
            precision: "Record to 0.05 cm³ (nearest half-division) — burette scales are finer than a measuring cylinder's.",
            howToRead: [
                "Remember the scale runs from 0 at the TOP to 50 at the BOTTOM — the opposite way round to a measuring cylinder.",
                "Read at eye level with the bottom of the meniscus.",
                "Remove any air bubble in the tap/jet before taking the first reading.",
                "Take an initial and a final reading, then subtract, rather than trying to read a 'volume delivered' directly."
            ],
            errors: [
                ApparatusError(error: "Treating it like a measuring cylinder", fix: "A reading near the bottom of the liquid column is a LARGE number (close to 50), not small — always check which direction the scale increases."),
                ApparatusError(error: "Reading to the wrong precision", fix: "Burettes must be read to 0.05 cm³ — reporting to 0.1 or 1 cm³ loses the precision mark even if the reading itself is roughly right."),
                ApparatusError(error: "Air bubble in the tap", fix: "Run a little liquid through the tap before the first reading to clear any trapped air, which would otherwise add a false volume.")
            ],
            howToAnswer: "Volume delivered = final reading − initial reading = 32.40 − 4.20 = 28.20 cm³. Always present it as final minus initial explicitly — writing only the answer without both readings loses the working mark."
        )
    ]

    static func technique(for apparatus: ApparatusType) -> AnsweringTechnique? {
        all.first { $0.apparatus == apparatus }
    }
}

/// General 4-part answering framework shown above the per-apparatus list —
/// mirrors the SEAB/Cambridge/WAEC/NECO skill breakdown already used
/// elsewhere in the app (Planning, Measurement, Presentation, Analysis).
private let generalFramework: [(title: String, tip: String)] = [
    ("1. Read", "State the reading with the correct precision and unit. Show any zero-error correction as its own line."),
    ("2. Tabulate", "Column headers need quantity + unit, e.g. \u{201C}l / cm\u{201D}. Every raw reading keeps the same number of decimal places as the instrument."),
    ("3. Calculate", "Show substitution into the formula before the final answer, and keep the same significant figures as your raw data."),
    ("4. Evaluate", "Name ONE specific source of error and ONE specific, workable improvement — never a vague phrase like \u{201C}human error\u{201D} or \u{201C}be more careful.\u{201D}")
]

struct AnsweringTechniquesListView: View {
    let curriculum: Curriculum
    private var apparatusTypes: [ApparatusType] { CurriculumProfiles.forCurriculum(curriculum).apparatus }
    private var techniques: [AnsweringTechnique] {
        apparatusTypes.compactMap { AnsweringTechniquesBank.technique(for: $0) }
    }

    var body: some View {
        List {
            Section {
                ForEach(generalFramework, id: \.title) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title).font(.headline)
                        Text(item.tip).font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 5)
                }
            } header: {
                Text("The 4-step answering framework")
            }

            Section {
                ForEach(Array(techniques.enumerated()), id: \.element.id) { index, technique in
                    NavigationLink {
                        AnsweringTechniquesPagerView(techniques: techniques, startIndex: index * 2)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(technique.apparatus.label).font(.headline)
                            Text(technique.precision).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                        }
                        .padding(.vertical, 5)
                    }
                }
            } header: {
                Text("By apparatus")
            }
        }
        .navigationTitle("Answering Techniques")
    }
}

/// A technique's content is split into two swipeable pages — the reading
/// technique, then errors & the exam-answer phrasing — so nothing on
/// screen needs a small font or a long scroll to fit.
private enum TechniquePagePart {
    case reading, answering
}

struct AnsweringTechniquesPagerView: View {
    let techniques: [AnsweringTechnique]
    let startIndex: Int
    @Environment(\.dismiss) private var dismiss

    private var pages: [(technique: AnsweringTechnique, part: TechniquePagePart)] {
        techniques.flatMap { [($0, .reading), ($0, .answering)] }
    }

    var body: some View {
        PagedReaderView(
            pageCount: pages.count,
            initialIndex: startIndex,
            pageLabel: { i in
                let entry = pages[i]
                let partLabel = entry.part == .reading ? "How to Read" : "Errors & Answer"
                return "\(entry.technique.apparatus.label) \u{2014} \(partLabel)"
            },
            page: { i in
                let entry = pages[i]
                switch entry.part {
                case .reading:
                    ReadingTechniquePage(technique: entry.technique)
                case .answering:
                    AnsweringExamPage(technique: entry.technique)
                }
            },
            onFinished: { dismiss() },
            finishedLabel: "Done"
        )
        .navigationTitle("Answering Techniques")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Star-rated "how much does this mistake cost" indicator — lets a
/// student triage at a glance which errors are worth fixing first,
/// rather than treating a missing unit the same as a wrong reading.
private struct MarksLostBadge: View {
    let marksLost: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<4, id: \.self) { i in
                Image(systemName: i < marksLost ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundStyle(i < marksLost ? .orange : Color(.tertiaryLabel))
            }
            Text(marksLost <= 1 ? "Lose 1 mark" : "Lose up to \(marksLost) marks")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }
}

private struct ReadingTechniquePage: View {
    let technique: AnsweringTechnique

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(technique.apparatus.label).font(.title2.bold())
            Label(technique.precision, systemImage: "ruler")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.blue)

            block(title: "How to take the reading", tint: .blue) {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(technique.howToRead.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("\(index + 1).").font(.title3.weight(.bold)).foregroundStyle(.blue)
                            Text(step).font(.title3)
                        }
                    }
                }
            }

            MemoryBox(apparatusName: technique.apparatus.label, precision: technique.precision)
        }
    }

    @ViewBuilder
    private func block<Content: View>(title: String, tint: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline).foregroundStyle(tint)
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// "5-second memory box" — a short, highly compressed callout meant to be
/// re-read many times during revision, distinct from the fuller
/// step-by-step instructions above it.
private struct MemoryBox: View {
    let apparatusName: String
    let precision: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\u{1F9E0}").font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("Remember").font(.subheadline.weight(.bold))
                Text("\(apparatusName) \u{2192} \(precision)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.yellow.opacity(0.4), lineWidth: 1))
    }
}

private struct AnsweringExamPage: View {
    let technique: AnsweringTechnique

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(technique.apparatus.label).font(.title2.bold())

            block(title: "Common errors & how to fix them", tint: .red) {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(technique.errors) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline) {
                                Text("\u{2717} \(item.error)").font(.title3.weight(.semibold)).foregroundStyle(.red)
                                Spacer()
                                MarksLostBadge(marksLost: item.marksLost)
                            }
                            if let correctAnswer = item.correctAnswer {
                                Text("\u{2713} Correct: \(correctAnswer)").font(.body.weight(.semibold)).foregroundStyle(.green)
                                Text("Reason: \(item.fix)").font(.body).foregroundStyle(.secondary)
                            } else {
                                Text(item.fix).font(.body).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            block(title: "Common examiner comments", tint: .orange) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Self.commonExaminerComments, id: \.self) { comment in
                        Label(comment, systemImage: "text.bubble")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            block(title: "How to write the answer", tint: .green) {
                Text(technique.howToAnswer).font(.title3)
            }
        }
    }

    /// The same handful of comments examiners write across almost every
    /// apparatus — shown once per page as a reusable checklist rather
    /// than repeated per-instrument content.
    private static let commonExaminerComments = [
        "\u{2717} Precision incorrect",
        "\u{2717} Unit omitted",
        "\u{2717} Wrong meniscus/parallax reading",
        "\u{2717} Zero error ignored",
    ]

    @ViewBuilder
    private func block<Content: View>(title: String, tint: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline).foregroundStyle(tint)
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
