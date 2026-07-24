//
//  LastMinuteRevisionView.swift
//  PhysicsPracticalCoach
//
//  "Last Minute Revision" — the night-before/morning-of cram screen: every
//  formula used across the practical syllabus in one place, plus the
//  highest-yield rules condensed to one line each. Complements (rather
//  than duplicates) the full `StudyNotesView`, which covers the same
//  ground in worked-example depth.
//

import SwiftUI

struct RevisionFormula: Identifiable {
    let id = UUID()
    let topic: String
    let formula: String
    let variables: String
    let notes: String
}

enum LastMinuteRevisionBank {

    static let formulas: [RevisionFormula] = [
        RevisionFormula(
            topic: "Pendulum (SHM)",
            formula: "T = 2\u{03C0}\u{221A}(L/g)   \u{2192}   T\u{00B2} = (4\u{03C0}\u{00B2}/g)\u{00D7}L",
            variables: "T = period (s), L = length (m), g = 9.81 m s\u{207B}\u{00B2}",
            notes: "Plot T\u{00B2} against L \u{2014} gradient = 4\u{03C0}\u{00B2}/g, so g = 4\u{03C0}\u{00B2} / gradient. Always time \u{2265} 20 oscillations and divide."
        ),
        RevisionFormula(
            topic: "Hooke's Law (Spring)",
            formula: "F = kx",
            variables: "F = force (N), k = spring constant (N m\u{207B}\u{00B9}), x = extension (m)",
            notes: "Extension x = stretched length \u{2212} natural length. Gradient of F vs x graph = k. Stop adding mass once the line curves (elastic limit exceeded)."
        ),
        RevisionFormula(
            topic: "Ohm's Law",
            formula: "V = IR   \u{2192}   R = V/I",
            variables: "V = voltage (V), I = current (A), R = resistance (\u{03A9})",
            notes: "Plot V (y) vs I (x); gradient = R. A curving I\u{2013}V graph (e.g. filament lamp) means resistance changes with current \u{2014} gradient at a point, not overall, gives R there."
        ),
        RevisionFormula(
            topic: "Resistance of a wire",
            formula: "R = \u{03C1}L/A",
            variables: "\u{03C1} = resistivity (\u{03A9} m), L = length (m), A = cross-sectional area (m\u{00B2})",
            notes: "Plot R vs L \u{2014} gradient = \u{03C1}/A. Measure wire diameter with a micrometer at several points and average, since A = \u{03C0}(d/2)\u{00B2} is very sensitive to diameter error."
        ),
        RevisionFormula(
            topic: "Potentiometer / potential gradient",
            formula: "K = V/l = I\u{00D7}r",
            variables: "K = potential gradient (V m\u{207B}\u{00B9}), l = length of wire (m), r = resistance per unit length",
            notes: "Plot V vs l for the jockey position \u{2014} gradient = K, the potential gradient along the wire."
        ),
        RevisionFormula(
            topic: "Refraction (glass block)",
            formula: "n = sin i / sin r",
            variables: "n = refractive index, i = angle of incidence, r = angle of refraction",
            notes: "Plot sin i (y) vs sin r (x) \u{2014} gradient = n. Always measure angles from the NORMAL, not from the surface of the block."
        ),
        RevisionFormula(
            topic: "Converging lens",
            formula: "1/f = 1/u + 1/v",
            variables: "f = focal length (m), u = object distance (m), v = image distance (m)",
            notes: "Locate the image position where it is sharpest on the screen \u{2014} move the screen, not just your eye, to judge best focus. Repeat for several u values."
        ),
        RevisionFormula(
            topic: "Principle of moments",
            formula: "Sum of clockwise moments = Sum of anticlockwise moments;  moment = F \u{00D7} d",
            variables: "F = force (N), d = perpendicular distance from pivot (m)",
            notes: "Distance is always measured perpendicular to the force, from the pivot \u{2014} not along the beam if the force is angled."
        ),
        RevisionFormula(
            topic: "Density",
            formula: "\u{03C1} = m/V",
            variables: "\u{03C1} = density (g cm\u{207B}\u{00B3} or kg m\u{207B}\u{00B3}), m = mass (g or kg), V = volume (cm\u{00B3} or m\u{00B3})",
            notes: "For an irregular solid, V = volume of water displaced (final cylinder reading \u{2212} initial reading). Lower the object in gently, at an angle, to avoid splashing and trapped air bubbles."
        ),
        RevisionFormula(
            topic: "Speed / motion",
            formula: "v = d/t   (average speed);  a = \u{0394}v/\u{0394}t",
            variables: "v = speed (m s\u{207B}\u{00B9}), d = distance (m), t = time (s), a = acceleration (m s\u{207B}\u{00B2})",
            notes: "For a distance\u{2013}time graph, gradient = speed. For a curving graph, draw a tangent at the point to get instantaneous speed."
        )
    ]

    /// One-line, highest-yield rules — condensed reminders, not full
    /// explanations (see Study Notes for the worked-example version).
    static let highYieldNotes: [String] = [
        "Scaled instruments (ammeter, voltmeter, thermometer) \u{2192} record to HALF the smallest division. Length instruments (ruler, vernier, micrometer) \u{2192} record to the SMALLEST division.",
        "A calculated mean can never have more significant figures than your raw readings.",
        "Every table column header needs a quantity AND a unit, e.g. \u{201C}l / cm\u{201D} \u{2014} never just \u{201C}l\u{201D} or \u{201C}cm\u{201D} alone.",
        "Plot points so they fill at least half the grid in both directions \u{2014} a cramped graph loses the scale mark even if every point is correct.",
        "Use a large triangle (spanning more than half the line) to calculate gradient \u{2014} a small triangle is heavily penalised for reduced precision.",
        "State ONE specific error and ONE specific, workable improvement in evaluations \u{2014} \u{201C}human error\u{201D} or \u{201C}be more careful\u{201D} score zero.",
        "Always show the zero-error correction as an explicit line of working for vernier calipers and micrometers, even if the zero error is 0.00.",
        "Convert a stopwatch's mm:ss.t display to total seconds before using it in any calculation.",
        "Time multiple oscillations (\u{2265}20) and divide, rather than timing one, to shrink the effect of your reaction time.",
        "A burette reads 0 at the TOP and 50 at the BOTTOM \u{2014} the opposite way round to a measuring cylinder.",
        "Read any meniscus at eye level, from its lowest point for water-based liquids, to avoid parallax."
    ]

    /// A final, ultra-compressed page meant to be re-read many times in
    /// the last minutes before the exam — distinct from `highYieldNotes`
    /// above (which explain *why*), this is pure checklist recall.
    static let top20: [String] = [
        "Always use pencil for graphs and diagrams.",
        "Circle any anomalous point clearly.",
        "Use a ruler for the best-fit line \u{2014} never freehand.",
        "Units go in table/axis headings only, never repeated in the data.",
        "Draw the gradient triangle as large as the line allows.",
        "Read every scale at eye level to avoid parallax.",
        "Take repeat readings and average them.",
        "Gradient comes from TWO POINTS ON THE BEST-FIT LINE \u{2014} never from two plotted data points.",
        "State and apply the zero error before writing your final reading.",
        "Record to the precision the instrument allows \u{2014} never round early.",
        "A suitable scale fills more than half the grid in both directions.",
        "Join points with one best-fit line or smooth curve \u{2014} never point-to-point.",
        "Take at least 6 sets of readings across a sensible range.",
        "Match significant figures to your least precise measurement.",
        "Keep every other variable constant except the one being investigated.",
        "Give a precaution specific to this experiment, not \u{201C}be careful.\u{201D}",
        "Convert stopwatch mm:ss.t readings to total seconds before calculating.",
        "Write conclusions as a relationship statement, not just \u{201C}it worked.\u{201D}",
        "Double-check the range on a dual-range meter before reading it.",
        "Let thermometers and liquids reach equilibrium before reading."
    ]
}

struct LastMinuteRevisionView: View {
    @Environment(\.dismiss) private var dismiss

    private let formulas = LastMinuteRevisionBank.formulas
    private let noteChunks = LastMinuteRevisionBank.highYieldNotes.chunked(into: 3)

    /// +1 for the final "Top 20 Things to Remember" page.
    private var totalPages: Int { formulas.count + noteChunks.count + 1 }

    var body: some View {
        PagedReaderView(
            pageCount: totalPages,
            pageLabel: { i in
                if i < formulas.count {
                    return "Formula \(i + 1) of \(formulas.count)"
                } else if i < formulas.count + noteChunks.count {
                    let chunkIndex = i - formulas.count
                    return "High-Yield Rules \(chunkIndex + 1) of \(noteChunks.count)"
                } else {
                    return "Top 20 Things to Remember"
                }
            },
            page: { i in
                if i < formulas.count {
                    FormulaPage(item: formulas[i])
                } else if i < formulas.count + noteChunks.count {
                    HighYieldPage(notes: noteChunks[i - formulas.count])
                } else {
                    Top20Page()
                }
            },
            onFinished: { dismiss() },
            finishedLabel: "Done"
        )
        .navigationTitle("Last Minute Revision")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct Top20Page: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Top 20 Things to Remember").font(.title2.bold())
            Text("The last page to check before you walk in.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(LastMinuteRevisionBank.top20.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\u{2705}").font(.subheadline)
                        Text(item).font(.subheadline)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

private struct FormulaPage: View {
    let item: RevisionFormula

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("FORMULA SHEET")
                .font(.caption.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(.secondary)

            Text(item.topic).font(.title2.bold())

            Text(item.formula)
                .font(.title.weight(.bold).monospaced())
                .foregroundStyle(.blue)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text("Variables").font(.headline).foregroundStyle(.secondary)
                Text(item.variables).font(.title3)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Notes").font(.headline).foregroundStyle(.secondary)
                Text(item.notes).font(.title3)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct HighYieldPage: View {
    let notes: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("HIGH-YIELD RULES")
                .font(.caption.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(.secondary)
            Text("The rules that cost the most marks when forgotten.")
                .font(.title3.weight(.semibold))

            VStack(alignment: .leading, spacing: 18) {
                ForEach(Array(notes.enumerated()), id: \.offset) { index, note in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Image(systemName: "star.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                        Text(note).font(.title3)
                    }
                    if index < notes.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
