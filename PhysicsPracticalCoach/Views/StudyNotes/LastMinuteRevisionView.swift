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
            notes: "Plot T\u{00B2} against L \u2014 gradient = 4\u{03C0}\u{00B2}/g, so g = 4\u{03C0}\u{00B2} / gradient. Always time \u2265 20 oscillations and divide."
        ),
        RevisionFormula(
            topic: "Hooke's Law (Spring)",
            formula: "F = kx",
            variables: "F = force (N), k = spring constant (N m\u207B\u00B9), x = extension (m)",
            notes: "Extension x = stretched length \u2212 natural length. Gradient of F vs x graph = k. Stop adding mass once the line curves (elastic limit exceeded)."
        ),
        RevisionFormula(
            topic: "Ohm's Law",
            formula: "V = IR   \u{2192}   R = V/I",
            variables: "V = voltage (V), I = current (A), R = resistance (\u{03A9})",
            notes: "Plot V (y) vs I (x); gradient = R. A curving I\u2013V graph (e.g. filament lamp) means resistance changes with current \u2014 gradient at a point, not overall, gives R there."
        ),
        RevisionFormula(
            topic: "Resistance of a wire",
            formula: "R = \u{03C1}L/A",
            variables: "\u{03C1} = resistivity (\u{03A9} m), L = length (m), A = cross-sectional area (m\u00B2)",
            notes: "Plot R vs L \u2014 gradient = \u{03C1}/A. Measure wire diameter with a micrometer at several points and average, since A = \u{03C0}(d/2)\u00B2 is very sensitive to diameter error."
        ),
        RevisionFormula(
            topic: "Potentiometer / potential gradient",
            formula: "K = V/l = I\u{00D7}r",
            variables: "K = potential gradient (V m\u207B\u00B9), l = length of wire (m), r = resistance per unit length",
            notes: "Plot V vs l for the jockey position \u2014 gradient = K, the potential gradient along the wire."
        ),
        RevisionFormula(
            topic: "Refraction (glass block)",
            formula: "n = sin i / sin r",
            variables: "n = refractive index, i = angle of incidence, r = angle of refraction",
            notes: "Plot sin i (y) vs sin r (x) \u2014 gradient = n. Always measure angles from the NORMAL, not from the surface of the block."
        ),
        RevisionFormula(
            topic: "Converging lens",
            formula: "1/f = 1/u + 1/v",
            variables: "f = focal length (m), u = object distance (m), v = image distance (m)",
            notes: "Locate the image position where it is sharpest on the screen \u2014 move the screen, not just your eye, to judge best focus. Repeat for several u values."
        ),
        RevisionFormula(
            topic: "Principle of moments",
            formula: "Sum of clockwise moments = Sum of anticlockwise moments;  moment = F \u{00D7} d",
            variables: "F = force (N), d = perpendicular distance from pivot (m)",
            notes: "Distance is always measured perpendicular to the force, from the pivot \u2014 not along the beam if the force is angled."
        ),
        RevisionFormula(
            topic: "Density",
            formula: "\u{03C1} = m/V",
            variables: "\u{03C1} = density (g cm\u207B\u00B3 or kg m\u207B\u00B3), m = mass (g or kg), V = volume (cm\u00B3 or m\u00B3)",
            notes: "For an irregular solid, V = volume of water displaced (final cylinder reading \u2212 initial reading). Lower the object in gently, at an angle, to avoid splashing and trapped air bubbles."
        ),
        RevisionFormula(
            topic: "Speed / motion",
            formula: "v = d/t   (average speed);  a = \u{0394}v/\u{0394}t",
            variables: "v = speed (m s\u207B\u00B9), d = distance (m), t = time (s), a = acceleration (m s\u207B\u00B2)",
            notes: "For a distance\u2013time graph, gradient = speed. For a curving graph, draw a tangent at the point to get instantaneous speed."
        )
    ]

    /// One-line, highest-yield rules — condensed reminders, not full
    /// explanations (see Study Notes for the worked-example version).
    static let highYieldNotes: [String] = [
        "Scaled instruments (ammeter, voltmeter, thermometer) \u2192 record to HALF the smallest division. Length instruments (ruler, vernier, micrometer) \u2192 record to the SMALLEST division.",
        "A calculated mean can never have more significant figures than your raw readings.",
        "Every table column header needs a quantity AND a unit, e.g. \u201Cl / cm\u201D \u2014 never just \u201Cl\u201D or \u201Ccm\u201D alone.",
        "Plot points so they fill at least half the grid in both directions \u2014 a cramped graph loses the scale mark even if every point is correct.",
        "Use a large triangle (spanning more than half the line) to calculate gradient \u2014 a small triangle is heavily penalised for reduced precision.",
        "State ONE specific error and ONE specific, workable improvement in evaluations \u2014 \u201Chuman error\u201D or \u201Cbe more careful\u201D score zero.",
        "Always show the zero-error correction as an explicit line of working for vernier calipers and micrometers, even if the zero error is 0.00.",
        "Convert a stopwatch's mm:ss.t display to total seconds before using it in any calculation.",
        "Time multiple oscillations (\u226520) and divide, rather than timing one, to shrink the effect of your reaction time.",
        "A burette reads 0 at the TOP and 50 at the BOTTOM \u2014 the opposite way round to a measuring cylinder.",
        "Read any meniscus at eye level, from its lowest point for water-based liquids, to avoid parallax."
    ]
}

struct LastMinuteRevisionView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Formula Sheet").font(.title3.bold())
                    Text("Every governing equation used across the practical syllabus.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                ForEach(LastMinuteRevisionBank.formulas) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.topic).font(.subheadline.weight(.semibold))
                        Text(item.formula)
                            .font(.title3.weight(.bold).monospaced())
                            .foregroundStyle(.blue)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(item.variables).font(.caption).foregroundStyle(.secondary)
                        Text(item.notes).font(.footnote)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("High-Yield Rules").font(.title3.bold()).padding(.top, 8)
                    Text("The rules that cost the most marks when forgotten.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(LastMinuteRevisionBank.highYieldNotes.enumerated()), id: \.offset) { index, note in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Text(note).font(.subheadline)
                        }
                        if index < LastMinuteRevisionBank.highYieldNotes.count - 1 {
                            Divider()
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Last Minute Revision")
        .navigationBarTitleDisplayMode(.inline)
    }
}
