//
//  StudyNotesView.swift
//  PhysicsPracticalCoach
//
//  Full port of `core.model.StudyNote.kt` + `domain.notes.StudyNotesBank.kt`.
//  32 notes across 9 categories, 1:1 with the Android bank, including the
//  per-curriculum Exam Format cards (SEAB / Cambridge / WAEC / NECO / General).
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
        case .instrumentPrecision: return "🔬"
        case .sigFigs: return "🔢"
        case .tabulation: return "📋"
        case .graphPlotting: return "📈"
        case .gradient: return "📐"
        case .precautions: return "⚠️"
        case .conclusions: return "✍️"
        case .planning: return "🗂️"
        case .examFormat: return "🗒️"
        }
    }
}

struct StudyNote: Identifiable {
    let id: String
    let category: StudyNoteCategory
    let title: String
    /// Core rule or concept — shown prominently.
    let rule: String
    /// Worked examples or correct usage.
    let examples: String
    /// Common mistakes students make — shown in amber.
    let doNotDo: String
    /// Extra tip or memory aid — shown in teal.
    let tip: String
    /// Which curricula this note applies to. Empty set = universal (applies to all).
    let curricula: Set<Curriculum>

    init(id: String, category: StudyNoteCategory, title: String, rule: String, examples: String, doNotDo: String = "", tip: String = "", curricula: Set<Curriculum> = []) {
        self.id = id
        self.category = category
        self.title = title
        self.rule = rule
        self.examples = examples
        self.doNotDo = doNotDo
        self.tip = tip
        self.curricula = curricula
    }
}

private let SG: Set<Curriculum> = [.singapore]
private let IG: Set<Curriculum> = [.igcse]
private let NC: Set<Curriculum> = [.neco]

enum StudyNotesBank {

    static let all: [StudyNote] = [

        // ══════════════════════════════════════════════════════════════════════
        // INSTRUMENT PRECISION
        // Source: Physics Practical Revision Notes (updated), p.1
        // ══════════════════════════════════════════════════════════════════════

        StudyNote(
            id: "prec_01", category: .instrumentPrecision, title: "Rule of Thumb — Precision",
            rule: "Scaled readings (e.g. ammeter, thermometer, voltmeter)\n→ record to HALF the smallest division\n\nMeasurements (e.g. metre rule, ruler)\n→ record to the SMALLEST division",
            examples: "Ammeter with smallest div = 0.02 A → record to 0.01 A\nThermometer with smallest div = 1°C → record to 0.5°C\nMetre rule with smallest div = 0.1 cm → record to 0.1 cm",
            doNotDo: "✗ Do NOT record ammeter as 0.5 A when smallest div is 0.02 A — should be 0.50 A\n✗ Do NOT confuse 'number of decimal places' with 'significant figures' for instruments",
            tip: "💡 For instruments, always think in DECIMAL PLACES, not significant figures."
        ),
        StudyNote(
            id: "prec_02", category: .instrumentPrecision, title: "Length Instruments",
            rule: "Metre Rule: record to 0.1 cm (1 d.p.)\nVernier Caliper: record to 0.01 cm (2 d.p.)\nMicrometer Screw Gauge: record to 0.01 mm (2 d.p.)",
            examples: "Metre rule: 2.0 cm ✓  (NOT '2 cm')\nVernier: 2.34 cm ✓, 3.40 cm ✓\nMicrometer: 3.45 mm ✓",
            doNotDo: "✗ '2 cm' instead of '2.0 cm' — the trailing zero is required for metre rule readings\n✗ '3.4 cm' from a vernier — must be 2 d.p., e.g. 3.40 cm",
            tip: "💡 The trailing zero after the decimal point is NOT optional — it shows the precision of your instrument."
        ),
        StudyNote(
            id: "prec_03", category: .instrumentPrecision, title: "Electrical Instruments",
            rule: "Ammeter (0–1 A): record to 0.01 A (2 d.p.)\nVoltmeter (0–5 V): record to 0.05 V (2 d.p.)",
            examples: "Ammeter: 0.44 A ✓, 0.50 A ✓  (NOT 0.5 A)\nVoltmeter: 1.20 V ✓, 2.35 V ✓  (NOT 1.2 V)",
            doNotDo: "✗ '0.5 A' instead of '0.50 A' — drops the significant trailing zero\n✗ '1.2 V' instead of '1.20 V'",
            tip: "💡 The range of the meter determines the smallest division. An ammeter with f.s.d. 1 A has 100 divisions → smallest div = 0.01 A → record to 0.01 A."
        ),
        StudyNote(
            id: "prec_04", category: .instrumentPrecision, title: "Volume, Time, Temperature, Mass, Angle",
            rule: "Measuring Cylinder (100 cm³): record to 0.5 cm³ (1 d.p.)\nDigital Stopwatch: record to 0.1 s (1 d.p.) or 0.01 s (2 d.p.)\nThermometer (–10 to 110°C): record to 0.5°C (1 d.p.)\nSpring Balance (0–10 N): record to 0.1 N\nElectronic Balance: record to 0.1 g (1 d.p.)\nProtractor: record to 1° (whole number)",
            examples: "Cylinder: 65.5 cm³ ✓, 80.0 cm³ ✓\nStopwatch (fast motion): 3.52 s ✓\nStopwatch (20 oscillations): 23.2 s ✓\nThermometer: 37.0°C ✓, 21.5°C ✓\nProtractor: 9°, 67° ✓",
            doNotDo: "✗ '65 cm³' from a measuring cylinder — must be 1 d.p.\n✗ '37°C' from a thermometer — must be 37.0°C (1 d.p.)",
            tip: "💡 Protractor is the ONLY instrument measured to a whole number (1°). Everything else has at least 1 d.p."
        ),

        // ══════════════════════════════════════════════════════════════════════
        // SIGNIFICANT FIGURES
        // Source: Skillset 1 + Physics Practical Revision Notes p.2
        // ══════════════════════════════════════════════════════════════════════

        StudyNote(
            id: "sf_01", category: .sigFigs, title: "Finding the Mean — s.f. Rule",
            rule: "Leave the mean in the SAME number of significant figures as the raw data.\nYour calculated values cannot be more precise than the raw data.",
            examples: "d₁ = 2.34 cm, d₂ = 2.35 cm, d₃ = 2.34 cm\nMean = (2.34 + 2.35 + 2.34) / 3 = 2.3433…\nRound to 3 s.f. (same as raw data) → d = 2.34 cm ✓\n\nt₂₀ = 19.5 s (3 s.f.)\nT = 19.5 / 20 = 0.975 s (3 s.f., as 20 is a constant)",
            doNotDo: "✗ Writing d = 2.3433 cm — too many s.f.\n✗ Writing T = 0.98 s — too few s.f. if raw data is 3 s.f.",
            tip: "💡 The divisor (e.g. 20 oscillations) is a constant — ignore its s.f. when rounding."
        ),
        StudyNote(
            id: "sf_02", category: .sigFigs, title: "Calculated Quantities from Measured Values",
            rule: "Leave the answer in the LEAST number of significant figures among all measured values.\nYour answer cannot be more precise than the least precise measurement.",
            examples: "Density D = m/V\nm = 120.45 g (5 s.f.), V = 45.8 cm³ (3 s.f.)\nD = 120.45 / 45.8 = 2.629… ≈ 2.63 g/cm³  (3 s.f.) ✓",
            doNotDo: "✗ Writing D = 2.629 g/cm³ — uses 4 s.f. but least measured is 3 s.f.\n✗ Counting s.f. of the equation constant (e.g. 3.14 in πr²)",
            tip: "💡 Identify the measured value with the FEWEST significant figures — your answer matches that."
        ),
        StudyNote(
            id: "sf_03", category: .sigFigs, title: "Calculated Quantities from an Equation",
            rule: "Leave the answer in the LEAST s.f. of the measured values.\nIGNORE the s.f. of constants in the equation (π, g, 3.14, etc.).",
            examples: "A = πr², r = 5.2 cm (2 s.f.)\nIgnore π — it is a constant.\nA = 3.14 × (5.2)² = 84.9 ≈ 85 cm²  (2 s.f.) ✓\n\nF = ma, m = 12.45 kg (4 s.f.), a = 2.5 m/s² (2 s.f.)\nF = 12.45 × 2.5 = 31.125 ≈ 31 N  (2 s.f.) ✓",
            doNotDo: "✗ Using s.f. of π or g when rounding the final answer\n✗ Rounding intermediate steps — only round the FINAL answer",
            tip: "💡 Add/subtract → round to fewest DECIMAL PLACES. Multiply/divide → round to fewest SIGNIFICANT FIGURES."
        ),
        StudyNote(
            id: "sf_04", category: .sigFigs, title: "Gradient Significant Figures",
            rule: "Leave the gradient answer in the LEAST significant figures as the coordinates used.",
            examples: "Coordinates: (4.2, 6.40) and (8.5, 45.5)\nΔy = 45.5 − 6.40 = 39.1  (3 s.f.)\nΔx = 8.5 − 4.2 = 4.3  (2 s.f.)\nGradient = 39.1 / 4.3 = 9.09 ≈ 9.1  (2 s.f.) ✓",
            doNotDo: "✗ Writing gradient = 9.09 — more s.f. than the coordinates allow",
            tip: "💡 Read both coordinates carefully — the one with fewer s.f. determines your gradient's precision."
        ),

        // ══════════════════════════════════════════════════════════════════════
        // TABULATION
        // Source: Skillset 2 + Physics Practical Revision Notes p.3
        // ══════════════════════════════════════════════════════════════════════

        StudyNote(
            id: "tab_01", category: .tabulation, title: "Table Headings — Solidus Notation",
            rule: "Every column heading must show: quantity / unit\nUse a forward slash (solidus) to separate quantity from unit.\nDo NOT put units inside the data cells.",
            examples: "✓ Correct headings: h / cm  |  t₁ / s  |  T / s  |  T² / s²\n✓ Data cell shows only: 5.0  |  48.0  |  2.40  |  5.76\n\n✗ Wrong: h (cm)  |  t₁ seconds  |  T(s)",
            doNotDo: "✗ Writing units in the data cells: '5.0 cm', '48.0 s'\n✗ Using brackets: h(cm) — must be h/cm\n✗ Omitting units entirely",
            tip: "💡 Think of it as dividing: if h = 5.0 cm, then h/cm = 5.0 (a pure number). The heading explains what the numbers mean."
        ),
        StudyNote(
            id: "tab_02", category: .tabulation, title: "Table — Precision and Consistency",
            rule: "• All readings in a column must be to the same number of decimal places\n• Raw measurements: use the instrument's precision\n• Calculated values: use the least s.f. rule\n• Draw table borders with pencil and ruler",
            examples: "h/cm column: 5.0, 15.0, 25.0, 35.0, 45.0, 55.0  ✓ (all 1 d.p.)\nt/s column: 48.0, 46.4, 44.6  ✓ (all 1 d.p. matching stopwatch)\nT/s column: 2.40, 2.32, 2.23  ✓ (3 s.f., matching t/s input)",
            doNotDo: "✗ Mixing 5 and 15.0 in the same column — inconsistent d.p.\n✗ Writing T = 2.4 in the same column as T = 2.40\n✗ Leaving the table borders undrawn",
            tip: "💡 Scan down each column and ask: are all entries the same number of decimal places? If not, fix it."
        ),
        StudyNote(
            id: "tab_03", category: .tabulation, title: "Repeat Readings and Average",
            rule: "• Take at least 2 (ideally 3) repeat readings\n• Average = (reading 1 + reading 2 + …) / n\n• Round average to same s.f. as the raw readings\n• Label columns: t₁/s, t₂/s, tₐᵥₑ/s",
            examples: "t₁ = 48.04 s, t₂ = 47.96 s\ntₐᵥₑ = (48.04 + 47.96) / 2 = 48.00 s ✓\nRounded to 4 s.f. to match raw data ✓",
            doNotDo: "✗ Recording only one reading without justification\n✗ Writing tₐᵥₑ = 48 s — loses precision of raw data",
            tip: "💡 Take readings at different positions/rotations (e.g. diameter at 0°, 60°, 120°) to reduce random errors."
        ),

        // ══════════════════════════════════════════════════════════════════════
        // GRAPH PLOTTING
        // Source: Physics Practical Revision Notes p.3–5, Skillset 3
        // ══════════════════════════════════════════════════════════════════════

        StudyNote(
            id: "graph_01", category: .graphPlotting, title: "The 4 Graph Criteria [1 mark each]",
            rule: "1. BEST-FIT LINE — balanced errors, thin, continuous, not dot-to-dot\n2. LABELED AXES — quantity/unit format, same as table headings\n3. CORRECT PLOTTING — crosses (×) of reasonable size, accurately placed\n4. RIGHT SCALE — multiples of 2 or 5; data spans 5×7 or 7×5 big squares (≥ 2/3 of paper)",
            examples: "Axes: R / Ω on y-axis, V / V on x-axis ✓\nScale: if V ranges 1–5, use 0 to 6 with 1 V per big square ✓\nPoints: small × at each data point, not dots or circles ✓\nLine: single thin line with roughly equal points above and below ✓",
            doNotDo: "✗ Joining dots one by one ('connect the dots')\n✗ Zig-zag break lines on axes — not allowed\n✗ Scales using multiples of 3 or 7\n✗ Data occupying less than half the graph paper\n✗ Thick or double lines for best fit",
            tip: "💡 5 by 7 rule: between the extreme data points, the graph should span 5 big squares in one direction and 7 in the other (landscape or portrait)."
        ),
        StudyNote(
            id: "graph_02", category: .graphPlotting, title: "Axes Labels and Scale",
            rule: "• Axis label must match the table heading exactly: quantity / unit\n• Use 2 cm per big square for common scales (2 rep 1, 2 rep 2, 2 rep 5)\n• Do NOT use intervals of 3 or 7\n• If scale does not start at 0, draw the axis without a zig-zag break\n• The origin (0,0) is always labelled even if the data doesn't start there",
            examples: "✓ y-axis: T² / s²,  scale: 0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0\n✓ x-axis: h / cm,  scale: 0, 10, 20, 30, 40, 50, 60\n✓ Scale starting at 40: label 40, 45, 50, 55, 60 (no zig-zag needed)",
            doNotDo: "✗ Scale: 0, 3, 6, 9 — intervals of 3 are not allowed\n✗ Scale: 0, 7, 14, 21 — intervals of 7 are not allowed\n✗ Leaving out the '0' at the origin",
            tip: "💡 Check instruction: does the question say 'start at origin'? If yes, force (0,0). If not, choose the best scale for your data range."
        ),
        StudyNote(
            id: "graph_03", category: .graphPlotting, title: "Straight Line vs. Curve — How to Tell",
            rule: "Expect a STRAIGHT LINE if:\n• 5 to 7 readings are tabulated\n• You are asked to find the gradient of the graph\n\nExpect a CURVE if:\n• 8 or more readings are tabulated\n• You are asked for the gradient at a particular point (tangent)",
            examples: "5–7 points, asked for gradient → draw a straight best-fit line\n8+ points, asked for gradient at x = 30 → draw a smooth curve, then draw a tangent at x = 30",
            doNotDo: "✗ Drawing a straight line when data clearly curves\n✗ Forcing a curve when data falls on a straight line",
            tip: "💡 For a tangent to a curve: draw the tangent line touching the curve at exactly that point, then calculate the gradient of the tangent line, not the curve."
        ),
        StudyNote(
            id: "graph_04", category: .graphPlotting, title: "Anomalous Points",
            rule: "An anomalous point lies significantly off the best-fit line.\nSteps:\n1. Circle the anomalous point\n2. Exclude it when drawing the best-fit line\n3. Do NOT force the line toward it",
            examples: "6 points plotted; one point at (3.0, 8.9) lies far above the line\n→ Circle it; draw best-fit line through the other 5 points only\n→ Note it in your write-up as an anomaly",
            doNotDo: "✗ Including the anomalous point in the best-fit line\n✗ Drawing the line to 'average in' the outlier\n✗ Ignoring it without circling",
            tip: "💡 An anomaly suggests a measurement error at that reading. In the exam, circle it and state you excluded it."
        ),

        // ══════════════════════════════════════════════════════════════════════
        // GRADIENT
        // Source: Physics Practical Revision Notes p.5, Skillset 4
        // ══════════════════════════════════════════════════════════════════════

        StudyNote(
            id: "grad_01", category: .gradient, title: "4 Steps to Find Gradient",
            rule: "Step 1: Select two points ON the best-fit line, as far apart as possible\nStep 2: Label both points with their coordinates (x₁, y₁) and (x₂, y₂)\nStep 3: Draw a dotted right-angled triangle connecting the two points\nStep 4: Calculate gradient = (y₂ − y₁) / (x₂ − x₁), with units",
            examples: "Points: (0.110, 0.40) and (0.580, 1.86)\nΔy = 1.86 − 0.40 = 1.46\nΔx = 0.580 − 0.110 = 0.470\nGradient = 1.46 / 0.470 = 3.106… ≈ 3.1  (2 s.f.) ✓\nUnit = (y unit) / (x unit) = s² / m",
            doNotDo: "✗ Using two DATA POINTS from the table instead of points ON the best-fit line\n✗ Using a small triangle (less than half the line length)\n✗ Omitting units from the gradient\n✗ Not showing the dotted triangle on the graph",
            tip: "💡 It is COMPULSORY to show both coordinates and the dotted triangle on the graph paper. The triangle must span at least HALF the length of the drawn line."
        ),
        StudyNote(
            id: "grad_02", category: .gradient, title: "Reading Values from a Graph",
            rule: "When reading a value from the graph, estimate to HALF the smallest square on the graph paper.\nA good choice of coordinate lies exactly on the corner of a small square.",
            examples: "Scale: 2 cm per big square → each small square = 0.2 units\nRead to nearest half small square = 0.1 units\nCoordinate: (8.0, 10.0) — on the corner of a small square ✓",
            doNotDo: "✗ Reading to the nearest big square only\n✗ Choosing coordinates that fall between small squares (introduces error)",
            tip: "💡 Choose gradient coordinates that fall exactly on gridline intersections — they are easier to read accurately and reduce errors in your gradient calculation."
        ),

        // ══════════════════════════════════════════════════════════════════════
        // PRECAUTIONS
        // Source: Physics Practical Revision Notes p.6
        // ══════════════════════════════════════════════════════════════════════

        StudyNote(
            id: "prec_elec_01", category: .precautions, title: "Electricity Experiment Precautions",
            rule: "Precaution = specific action taken to avoid a specific error or ensure accuracy.\nAlways state: WHAT you did + WHY (to avoid/reduce what error).",
            examples: "✓ I ensured there was no kink in the bare resistance wire so as to reduce inaccuracy in the measurement of the length.\n\n✓ I ensured the circuit was switched off after each reading to avoid heating and affecting the resistance of the nichrome wire.\n\n✓ I ensured the jockey was tapped from point to point so that the cross-sectional area of the wire remains uniform and does not affect the resistance.\n\n✓ I ensured the pointer was directly above its image before ammeter/voltmeter readings were taken, to avoid parallax error.",
            doNotDo: "✗ 'Be careful with the circuit' — too vague, scores zero\n✗ 'Switch off the circuit' without explaining why",
            tip: "💡 Structure: 'I [action] so as to [avoid/reduce/ensure] [specific error or accuracy goal].'"
        ),
        StudyNote(
            id: "prec_heat_01", category: .precautions, title: "Heat Experiment Precautions",
            rule: "Common precautions for heat experiments — state the action and the reason.",
            examples: "✓ I ensured the bulb of the thermometer was fully immersed in the centre of the liquid so as to ensure the temperature was measured accurately.\n\n✓ I stirred the liquid continuously using the stirrer (NOT the thermometer) to ensure the temperature was uniform.\n\n✓ I ensured the starting temperatures were the same so the comparison was fair.\n\n✓ I monitored the mercury level for several seconds before reading to avoid inaccuracy.\n\n✓ I transferred water quickly from one container to another to reduce heat lost to surroundings.\n\n✓ I kept my eye at the same level as the meniscus to avoid parallax error.",
            doNotDo: "✗ 'Use the thermometer to stir' — incorrect; stirrer must be separate\n✗ 'Read the thermometer quickly' — too vague",
            tip: "💡 Always stir with the STIRRER, not the thermometer — stirring with the thermometer breaks it and introduces error."
        ),
        StudyNote(
            id: "prec_light_01", category: .precautions, title: "Light Experiment Precautions",
            rule: "Common precautions for optics experiments.",
            examples: "✓ I stood up and looked perpendicularly to the lens or mirror to reduce parallax error.\n\n✓ I placed the pins as far apart as possible to reduce angular error during alignment.\n\n✓ I aligned the object with the optical centre of the lens to ensure the optical path was straight.\n\n✓ I ensured the lens was vertical and parallel to the screen to obtain a better-focused image.",
            doNotDo: "✗ 'Look straight at the lens' — must specify perpendicular to reduce parallax\n✗ Placing pins close together — increases angular uncertainty",
            tip: "💡 Distance matters for angular accuracy: pins placed far apart reduce the angle error when aligning to a straight line."
        ),
        StudyNote(
            id: "prec_mech_01", category: .precautions, title: "Mechanics Experiment Precautions",
            rule: "Common precautions for mechanics experiments.",
            examples: "✓ I placed plasticine on one end of the rule to ensure it balanced exactly at the 50 cm mark before the experiment.\n\n✓ I ensured the pendulum swung in a single plane to avoid circular oscillations.\n\n✓ I ensured the angle of oscillation was less than 10° to prevent it from affecting the period.\n\n✓ I measured the pendulum length from the point of suspension to the CENTRE of the bob, so the size of the bob did not affect the readings.\n\n✓ I reset the electronic balance before weighing to avoid inaccuracy.\n\n✓ I checked for zero error when using the vernier caliper or micrometer to avoid inaccuracy.",
            doNotDo: "✗ Measuring pendulum length to the TOP of the bob — must be to the centre\n✗ Forgetting to check zero error on vernier/micrometer",
            tip: "💡 Pendulum: measure from pivot to CENTRE of bob, not top. Keep angle < 10° so SHM applies."
        ),

        // ══════════════════════════════════════════════════════════════════════
        // CONCLUSIONS AND ERRORS
        // Source: Physics Practical Revision Notes p.7
        // ══════════════════════════════════════════════════════════════════════

        StudyNote(
            id: "conc_01", category: .conclusions, title: "Writing Relationship Statements",
            rule: "Look at the graph to determine the relationship:\n\nIf y-intercept = 0 AND straight line:\n→ 'A is DIRECTLY PROPORTIONAL to B' (A ∝ B)\n\nIf straight line but y-intercept ≠ 0:\n→ 'A VARIES LINEARLY with B' (A = mB + c)\n\nNever say 'proportional' unless the line passes through the origin.",
            examples: "Force-extension: straight line through origin → 'F is directly proportional to x'\n\nV-I with internal resistance: straight line, y-intercept ≠ 0 → 'V varies linearly with I'",
            doNotDo: "✗ Saying 'A is proportional to B' when the graph does NOT pass through the origin\n✗ Saying 'the graph is linear' without stating what that means about the relationship",
            tip: "💡 'Proportional' always implies the line passes through (0, 0). If it doesn't, use 'varies linearly'."
        ),
        StudyNote(
            id: "conc_02", category: .conclusions, title: "Common Sources of Error",
            rule: "Always explain HOW the error affects the accuracy of the reading — not just that it exists.",
            examples: "✓ Using a stopwatch: percentage error in timing due to human reaction time is significant, especially for short time intervals.\n\n✓ Wire becomes hot after prolonged use: resistance and current readings change over time, introducing a systematic drift.\n\n✓ Heat loss to surroundings: the calculated specific heat capacity is higher than the true value because the energy input exceeds the energy absorbed.\n\n✓ Parallax when reading a scale: reading is consistently too high or too low depending on the viewing angle.",
            doNotDo: "✗ 'Human error' — too vague, scores zero\n✗ 'The reading was inaccurate' — must say how and why",
            tip: "💡 Structure: 'Due to [source], the reading is [too high/too low/uncertain] because [physical reason].'"
        ),

        // ══════════════════════════════════════════════════════════════════════
        // PLANNING
        // Source: Instruction_for_Planning_Question + Physics Practical Notes p.8
        // ══════════════════════════════════════════════════════════════════════

        StudyNote(
            id: "plan_01", category: .planning, title: "Planning Template — 9 Steps",
            rule: "Use this structure for every planning question:\n\n1. Independent variable: [what you change]\n   Dependent variable: [what you measure]\n   Controlled variables: [what you keep constant]\n\n2. Set up apparatus [diagram if needed]\n\n3. Set [independent variable] to [value] using [apparatus/method]\n\n4. Measure and record [dependent variable] using [instrument], state precision\n\n5. Repeat for at least 5 other values of [independent variable]\n\n6. Calculate [derived quantity] from measurements\n\n7. Plot a graph of [y-axis] against [x-axis]\n\n8. Conclusion: if [graph shape], then [relationship] is verified\n\n9. Precautions: [at least one specific precaution]",
            examples: "Investigating T vs L for a pendulum:\n1. IV = length L; DV = period T; Control = angle (< 10°), same bob\n3. Set L = 10.0 cm using metre rule from suspension to centre of bob\n4. Time 20 oscillations with stopwatch; T = t/20\n5. Repeat for L = 20, 30, 40, 50, 60 cm\n6. Calculate T² for each value of L\n7. Plot T² / s² against L / cm\n8. If graph is straight line through origin, T² ∝ L is verified\n9. Ensure angle < 10° to maintain SHM",
            doNotDo: "✗ Forgetting to specify the range and interval of the independent variable\n✗ Not stating how the dependent variable is MEASURED (instrument + precision)\n✗ Not including at least 6 data points (5 + initial)\n✗ Conclusion says 'the experiment worked' — must state the specific relationship verified",
            tip: "💡 Linearise the equation first. If T = 2π√(L/g), squaring gives T² = (4π²/g)L. Plot T² vs L → straight line through origin → gradient = 4π²/g."
        ),
        StudyNote(
            id: "plan_02", category: .planning, title: "Linearising Equations for Planning",
            rule: "Always rearrange the given equation into y = mx + c form before planning.\n• y = dependent variable (what you plot on y-axis)\n• x = independent variable (what you plot on x-axis)\n• m = gradient (gives a physical constant)\n• c = y-intercept",
            examples: "T = 2π√(L/g)\n→ T² = (4π²/g)·L\n→ y = T², x = L, gradient = 4π²/g, c = 0\n\nV = E − Ir\n→ V = (−r)·I + E\n→ y = V, x = I, gradient = −r, c = E\n\nR = ρL/A\n→ R = (ρ/A)·L\n→ y = R, x = L, gradient = ρ/A, c = 0",
            doNotDo: "✗ Plotting the raw quantities without linearising — often gives a curve, not a line\n✗ Plotting the wrong variable on y (putting the independent on y gives 1/gradient for the constant)",
            tip: "💡 The gradient always connects to the physical constant you want to find. State what the gradient equals and how you use it to find the constant."
        ),
        StudyNote(
            id: "plan_03", category: .planning, title: "6 Required Data Points",
            rule: "Always collect at least 6 sets of readings:\n• State the exact values of the independent variable\n• Specify equal or sensible intervals\n• Include all repeat readings (t₁, t₂, tₐᵥₑ) where needed\n• Check that the range is wide enough to give a meaningful graph",
            examples: "Pendulum: L = 10.0, 20.0, 30.0, 40.0, 50.0, 60.0 cm\n(equal intervals of 10.0 cm; 6 values) ✓\n\nCircuit: V = 0.5, 1.0, 1.5, 2.0, 2.5, 3.0 V\n(equal intervals of 0.5 V; 6 values) ✓",
            doNotDo: "✗ Only listing 4–5 values — examiners expect 6\n✗ Not specifying the exact values (just saying 'change L several times')\n✗ Choosing intervals so small that the graph range is too small",
            tip: "💡 If the planning question is part of a longer question, check the range and intervals already used in the experiment — your planning values should be similar."
        ),
        StudyNote(
            id: "plan_04", category: .planning, title: "Identifying Variables",
            rule: "Independent variable (IV): the variable you deliberately CHANGE\nDependent variable (DV): the variable you MEASURE as a result\nControlled variables (CV): everything else kept CONSTANT for a fair test",
            examples: "Experiment: how does spring extension depend on load?\nIV = load F (changed by adding masses)\nDV = extension x (measured using metre rule)\nCV = same spring, same temperature, same starting length\n\nExperiment: how does V change with I in a circuit?\nIV = current I (changed using rheostat)\nDV = voltage V (measured using voltmeter)\nCV = same resistor/component, same temperature",
            doNotDo: "✗ Confusing IV and DV (putting extension as IV and force as DV)\n✗ Listing time, number of readings, or steps as controlled variables\n✗ Forgetting to include amplitude/angle as a CV in pendulum experiments",
            tip: "💡 Quick check: the IV is what YOU set. The DV is what the experiment DECIDES. CVs are everything that could affect the DV but you're keeping fixed."
        ),

        // ══════════════════════════════════════════════════════════════════════
        // EXAM FORMAT & MARKING — board-specific, one card per curriculum
        // Sources: SEAB 6091 syllabus PDF; Cambridge IGCSE 0625/0972 Learner Guide;
        // WAEC & NECO Physics syllabuses
        // ══════════════════════════════════════════════════════════════════════

        StudyNote(
            id: "fmt_sg_01", category: .examFormat, title: "SEAB 6091 Paper 3 — How It's Marked",
            rule: "Paper 3 (1 h 50 min, 40 marks, 20% of grade) has 2 sections, each with 55 minutes of apparatus time.\nFour skill areas are assessed:\n• Planning (P) — 15% of Paper 3\n• Manipulation, Measurement & Observation (MMO)\n• Presentation of Data & Observations (PDO)\n• Analysis, Conclusions & Evaluation (ACE)\nMMO + PDO + ACE together make up the remaining 85%.",
            examples: "Roughly: P ≈ 6 marks, MMO ≈ 14 marks, PDO ≈ 10 marks, ACE ≈ 10 marks (out of 40).\nP is usually woven into a question rather than asked as a standalone item — e.g. 'suggest one improvement to this method' or a short data-based question needing no apparatus.",
            doNotDo: "✗ Referring to notebooks/textbooks — not allowed during Paper 3\n✗ Assuming Planning is a separate question — it's usually embedded",
            tip: "💡 MMO rewards clean technique in the moment (right precision, right method). PDO and ACE reward what ends up on paper — tables, graphs, and written analysis — so don't rush the write-up.",
            curricula: SG
        ),
        StudyNote(
            id: "fmt_ig_01", category: .examFormat, title: "Cambridge 0625/0972 Paper 5 — How It's Marked",
            rule: "Paper 5 (1 h 15 min, 40 marks, 20% of grade) tests ONLY Assessment Objective AO3 (Experimental skills and investigations) — no recall of theory is directly marked.\nUsually 4 questions: about 20 minutes each for Q1–3 (apparatus-based) and 15 minutes for Q4 (often data-based, no apparatus needed).",
            examples: "Marks are awarded per question for things like: reading instruments to the correct precision, building a table with consistent units and s.f., plotting a well-scaled graph with a genuine best-fit line, and evaluating limitations with a specific improvement.\nIf you can't do Paper 5 in person, Paper 6 (Alternative to Practical, 1 hour) tests the exact same AO3 skills on paper instead.",
            doNotDo: "✗ Writing vague evaluation comments like 'parallax error' with no context\n✗ Memorising 'model answers' from old papers — examiners specifically watch for this and won't credit answers that don't match the actual apparatus in front of you",
            tip: "💡 Positive marking applies: you are marked on what you get right, with no penalty for wrong or missing parts elsewhere in the same question.",
            curricula: IG
        ),
        StudyNote(
            id: "fmt_waec_01", category: .examFormat, title: "WAEC Paper 3 — How It's Marked",
            rule: "Paper 3 (2 hours, 50 marks, ~25% of grade) has 3 COMPULSORY experiments — you must attempt all three (unlike NECO, where you choose 2 of 3).\nEach experiment is marked out of roughly 16–17 marks, split across: setting up, tabulation, graph, gradient/calculation, precautions, and conclusion.",
            examples: "Typical split per experiment: tabulation 3–4, graph 5–6, gradient/calculation 2–3, precaution 1–2, conclusion/deduction 2–3.\nPrecautions are marked individually — each distinct, correctly-explained precaution earns its own mark, so list more than one where you can.",
            doNotDo: "✗ Skipping one of the three experiments — all three are compulsory, unlike NECO's 'choose 2 of 3'\n✗ Giving only one precaution when the question allows marks for several",
            tip: "💡 WAEC's tolerance for graph scales and readings is a little more forgiving than Cambridge's — but explicit, well-explained precautions are especially rewarded, so don't skip them.",
            curricula: [.waec]
        ),
        StudyNote(
            id: "fmt_neco_01", category: .examFormat, title: "NECO Paper 3 — How It's Marked",
            rule: "Paper 3 (2 h 45 min, 50 marks, ~25% of grade) offers 3 experiments — you answer ANY 2 of the 3 (unlike WAEC, where all 3 are compulsory).\nMarking follows a similar pattern to WAEC: tabulation, graph, gradient, precaution, and conclusion marks per experiment.",
            examples: "Typical split per experiment (of 2 attempted): tabulation 3–4, graph 5, gradient and its use 3, precaution 1–2, conclusion 2–3.\nNECO frequently asks candidates to state the LEAST COUNT (smallest reading interval) of an instrument used — this is a distinct, easy mark that's often missed.",
            doNotDo: "✗ Attempting all 3 experiments when only 2 are required — this wastes time you need elsewhere\n✗ Forgetting to explicitly state the least count when the question or apparatus list calls for it",
            tip: "💡 Since you only need 2 of 3, quickly skim all three experiments first and pick the two you're most confident measuring accurately, then commit fully.",
            curricula: NC
        ),
        StudyNote(
            id: "fmt_gen_01", category: .examFormat, title: "General Mode — What This Covers",
            rule: "General mode isn't tied to one exam board. It pools instruments, simulations, graph types, and skills common across Singapore O-Level, Cambridge IGCSE, WAEC, and NECO Physics practicals, so you can practise broadly without board-specific quirks.",
            examples: "Use General mode if you're not yet sure which board you're sitting, or if you just want to drill core practical skills (precision, tabulation, graphing, gradients, precautions, planning) without board-specific marking rules.\nSwitch to your actual board in the Curriculum screen once you know it, so ACE questions and marking guidance match your real exam.",
            doNotDo: "✗ Relying on General mode right before your actual exam — switch to your specific board so the marking language matches what you'll see on the day",
            tip: "💡 The core skills (precision, sig figs, tabulation, graphing, gradients) are genuinely universal — they transfer directly to whichever board you end up sitting.",
            curricula: [.general]
        )
    ]

    static func forCategory(_ category: StudyNoteCategory, curriculum: Curriculum? = nil) -> [StudyNote] {
        all.filter { $0.category == category }
            .filter { curriculum == nil || $0.curricula.isEmpty || $0.curricula.contains(curriculum!) }
    }

    static func forCurriculum(_ curriculum: Curriculum) -> [StudyNote] {
        all.filter { $0.curricula.isEmpty || $0.curricula.contains(curriculum) }
    }
}

struct StudyNotesListView: View {
    let curriculum: Curriculum

    var body: some View {
        List {
            Section("Exam prep") {
                NavigationLink {
                    LastMinuteRevisionView()
                } label: {
                    Label("Last Minute Revision", systemImage: "book.fill")
                }
                NavigationLink {
                    AnsweringTechniquesListView(curriculum: curriculum)
                } label: {
                    Label("Answering Techniques", systemImage: "pencil.and.list.clipboard")
                }
            }

            Section("Study notes") {
                ForEach(StudyNoteCategory.allCases) { category in
                    NavigationLink {
                        StudyNoteCategoryDetailView(category: category, curriculum: curriculum)
                    } label: {
                        HStack(spacing: 12) {
                            Text(category.emoji).font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(category.label).font(.headline)
                                Text("\(StudyNotesBank.forCategory(category, curriculum: curriculum).count) note(s)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Study Notes")
    }
}

struct StudyNoteCategoryDetailView: View {
    let category: StudyNoteCategory
    let curriculum: Curriculum

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(StudyNotesBank.forCategory(category, curriculum: curriculum)) { note in
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
