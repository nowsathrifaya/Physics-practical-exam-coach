//
//  CurriculumProfile.swift
//  PhysicsPracticalCoach
//
//  Direct port of `core.model.CurriculumProfile.kt`. Full syllabus profile
//  for each supported exam board — used to filter apparatus, simulations,
//  and graph types shown to the student, and to display board-specific
//  paper information on the Home screen.
//

import Foundation

struct CurriculumProfile {
    let curriculum: Curriculum
    let examBoard: String
    let paperName: String
    let paperCode: String
    let totalMarks: Int
    let durationMinutes: Int
    let weightPercent: Int
    /// Short description shown on the home screen chip panel.
    let paperSummary: String
    /// Instruments tested in this curriculum's practical paper.
    let apparatus: [ApparatusType]
    /// Simulations most relevant to this curriculum.
    let simulations: [SimulationType]
    /// Graph types assessed in PDO questions for this curriculum.
    let graphTypes: [GraphCoachType]
    /// Key practical topics in order of exam frequency.
    let keyTopics: [String]
    /// How marks are distributed across skill areas.
    let markingScheme: String
    /// Tolerance policy note shown to student.
    let toleranceNote: String
    /// Emoji shown as the curriculum's visual identifier on selector cards.
    let flagEmoji: String
    /// Short exam-level badge shown on cards, e.g. "O-LEVEL", "IGCSE", "SSCE".
    let levelTag: String
    /// First line of the big home-screen headline, e.g. "O-Level Physics".
    let homeHeadlineLine1: String
    /// Second line of the big home-screen headline, e.g. "Paper 3 Trainer".
    let homeHeadlineLine2: String
}

enum CurriculumProfiles {

    static let singapore = CurriculumProfile(
        curriculum: .singapore,
        examBoard: "SEAB",
        paperName: "Paper 3 \u{2014} Practical",
        paperCode: "6091",
        totalMarks: 40,
        durationMinutes: 110,
        weightPercent: 20,
        paperSummary: "SEAB 6091 \u{00B7} Paper 3 \u{00B7} 40 marks \u{00B7} 1 h 50 min",
        apparatus: [
            .vernierCaliper, .micrometer, .ammeter, .voltmeter, .newtonMeter,
            .stopwatch, .thermometer, .measuringCylinder, .burette
        ],
        simulations: [
            .pendulum, .springExtension, .ohmsLaw, .potentiometer, .resistanceWire,
            .lensFocusing, .refraction, .moments, .vernierCaliper,
            .densityDisplacement, .coolingCurve, .filamentLamp
        ],
        graphTypes: [.forceExtension, .currentVoltage, .distanceTime, .tSquaredVsLength, .sinIVsSinR],
        keyTopics: [
            "Mechanical oscillations (pendulum) \u{2014} tested every year",
            "Spring extension (Hooke's Law) \u{2014} 2024, 2023, 2020, 2018",
            "Potentiometer \u{2014} 2023, 2022, 2018, 2014",
            "DC circuits / resistance \u{2014} 2025, 2021, 2020, 2019",
            "Converging lens \u{2014} 2023, 2016",
            "Refraction (glass block) \u{2014} 2021",
            "Principle of moments \u{2014} 2015, 2014",
            "Heat capacity \u{2014} 2021"
        ],
        markingScheme: "P (Planning): ~6 marks\nMMO (Measurement & Observation): ~14 marks\nPDO (Data Presentation): ~10 marks\nACE (Analysis, Conclusions, Evaluation): ~10 marks",
        toleranceNote: "Readings marked to full instrument precision. \u{00B1}1 smallest division for analogue instruments.",
        flagEmoji: "\u{1F1F8}\u{1F1EC}",
        levelTag: "O-LEVEL",
        homeHeadlineLine1: "O-Level Physics",
        homeHeadlineLine2: "Paper 3 Trainer"
    )

    static let igcse = CurriculumProfile(
        curriculum: .igcse,
        examBoard: "Cambridge",
        paperName: "Paper 5 \u{2014} Practical Test",
        paperCode: "0625 / 0972",
        totalMarks: 40,
        durationMinutes: 75,
        weightPercent: 20,
        paperSummary: "Cambridge 0625 \u{00B7} Paper 5 \u{00B7} 40 marks \u{00B7} 1 h 15 min",
        apparatus: [
            .vernierCaliper, .micrometer, .ammeter, .voltmeter, .newtonMeter,
            .stopwatch, .thermometer, .measuringCylinder
            // Burette not in IGCSE Physics (Chemistry only)
        ],
        simulations: [
            .pendulum, .springExtension, .ohmsLaw, .resistanceWire, .lensFocusing,
            .refraction, .moments, .vernierCaliper, .densityDisplacement,
            .coolingCurve, .filamentLamp
        ],
        graphTypes: [.forceExtension, .currentVoltage, .distanceTime, .tSquaredVsLength, .sinIVsSinR],
        keyTopics: [
            "Electrical measurements (V, I, R) \u{2014} core every session",
            "Spring / elastic force \u{2014} recurring",
            "Pendulum and timing \u{2014} recurring",
            "Optics (lens, refraction) \u{2014} recurring",
            "Density by displacement \u{2014} recurring",
            "Thermal measurement \u{2014} recurring",
            "Forces and moments \u{2014} recurring"
        ],
        markingScheme: "Paper 5 tests Assessment Objective AO3 (Experimental skills and investigations) only \u{2014} no knowledge recall marks.\nUsually 4 questions (~20 min each for Q1\u{2013}3, ~15 min for Q4); most need apparatus, one is data-based.\nMarks are awarded per question for: accurate readings, correct table/graph construction (units, scales, best-fit line), analysis and calculation, and evaluation (identifying limitations and suggesting improvements).\n\nNote: Cambridge Paper 6 (Alternative to Practical) tests the same AO3 skills via a written paper instead of hands-on apparatus.",
        toleranceNote: "Cambridge allows \u{00B1}1 small division for analogue readings. Significant figures must match instrument precision.",
        flagEmoji: "\u{1F310}",
        levelTag: "IGCSE",
        homeHeadlineLine1: "IGCSE Physics",
        homeHeadlineLine2: "Paper 5 Trainer"
    )

    static let waec = CurriculumProfile(
        curriculum: .waec,
        examBoard: "WAEC",
        paperName: "Paper 3 \u{2014} Practical",
        paperCode: "WAEC Physics",
        totalMarks: 50,
        durationMinutes: 120,
        weightPercent: 25,
        paperSummary: "WAEC \u{00B7} Paper 3 \u{00B7} 50 marks \u{00B7} 2 hours",
        apparatus: [
            .ammeter, .voltmeter, .newtonMeter, .stopwatch, .thermometer,
            .measuringCylinder, .vernierCaliper, .micrometer
        ],
        simulations: [
            .pendulum, .springExtension, .ohmsLaw, .resistanceWire, .lensFocusing,
            .refraction, .moments, .vernierCaliper, .densityDisplacement,
            .coolingCurve, .filamentLamp
        ],
        graphTypes: [.forceExtension, .currentVoltage, .distanceTime, .tSquaredVsLength, .sinIVsSinR],
        keyTopics: [
            "Simple pendulum \u{2014} T vs L graph (appears almost every year)",
            "Spring / Hooke's Law \u{2014} e vs W graph",
            "Ohm's Law / resistance \u{2014} V vs I graph",
            "Refraction (glass prism or block) \u{2014} sin i vs sin r",
            "Converging lens \u{2014} u/v graphs",
            "Cooling curves / thermal experiments",
            "Pulley systems / inclined plane (mechanics)"
        ],
        markingScheme: "WAEC Paper 3 has 3 compulsory experiments.\nEach experiment is marked out of ~16\u{2013}17 marks:\n\u{2022} Tabulation of results: 3\u{2013}4 marks\n\u{2022} Graph (correct axes, scale, points, line): 5\u{2013}6 marks\n\u{2022} Slope/gradient calculation: 2\u{2013}3 marks\n\u{2022} Precaution stated: 1\u{2013}2 marks\n\u{2022} Conclusion / deduction: 2\u{2013}3 marks\n\nTotal: 50 marks",
        toleranceNote: "WAEC allows \u{00B1}1 division for analogue readings and wider graph tolerance than Cambridge. Precautions must be stated explicitly \u{2014} 1 mark each.",
        flagEmoji: "\u{1F30D}",
        levelTag: "SSCE",
        homeHeadlineLine1: "WAEC Physics",
        homeHeadlineLine2: "Practical Trainer"
    )

    static let neco = CurriculumProfile(
        curriculum: .neco,
        examBoard: "NECO",
        paperName: "Paper 3 \u{2014} Practical",
        paperCode: "NECO Physics",
        totalMarks: 50,
        durationMinutes: 165,
        weightPercent: 25,
        paperSummary: "NECO \u{00B7} Paper 3 \u{00B7} 50 marks \u{00B7} 2 h 45 min",
        apparatus: [
            .ammeter, .voltmeter, .newtonMeter, .stopwatch, .thermometer,
            .measuringCylinder, .vernierCaliper, .micrometer
        ],
        simulations: [
            .pendulum, .springExtension, .ohmsLaw, .resistanceWire, .lensFocusing,
            .refraction, .moments, .vernierCaliper, .densityDisplacement,
            .coolingCurve, .filamentLamp
        ],
        graphTypes: [.forceExtension, .currentVoltage, .distanceTime, .tSquaredVsLength, .sinIVsSinR],
        keyTopics: [
            "Simple pendulum \u{2014} T\u{00B2} vs L graph",
            "Ohm's Law \u{2014} V vs I, find internal resistance",
            "Spring extension \u{2014} F vs e, find k",
            "Refraction \u{2014} sin i vs sin r, find n",
            "Lens \u{2014} 1/u + 1/v, find f",
            "Moments \u{2014} balancing a metre rule",
            "Thermal \u{2014} specific heat or cooling"
        ],
        markingScheme: "NECO Paper 3 offers 3 questions \u{2014} candidates answer any 2 (2 h 45 min total).\nMarking is similar to WAEC:\n\u{2022} Readings/tabulation: 3\u{2013}4 marks per experiment\n\u{2022} Graph (scale, points, best-fit line): 5 marks\n\u{2022} Gradient and use: 3 marks\n\u{2022} Precaution: 1\u{2013}2 marks\n\u{2022} Conclusion: 2\u{2013}3 marks\n\nTotal: 50 marks\n\nNote: NECO often requires students to state the instrument's least count.",
        toleranceNote: "NECO tolerances are similar to WAEC \u{2014} \u{00B1}1 small division. Students must state the least count of each instrument used.",
        flagEmoji: "\u{1F30D}",
        levelTag: "SSCE",
        homeHeadlineLine1: "NECO Physics",
        homeHeadlineLine2: "Practical Trainer"
    )

    static let general = CurriculumProfile(
        curriculum: .general,
        examBoard: "General",
        paperName: "General Physics Practical",
        paperCode: "\u{2014}",
        totalMarks: 50,
        durationMinutes: 120,
        weightPercent: 20,
        paperSummary: "General practical skills \u{00B7} All instruments \u{00B7} All topics",
        apparatus: ApparatusType.mvpTypes,
        simulations: SimulationType.allCases,
        graphTypes: GraphCoachType.allCases,
        keyTopics: [
            "Instrument reading and zero-error correction",
            "Tabulating and graphing experimental data",
            "Calculating gradients from best-fit lines",
            "Identifying sources of error and precautions",
            "Planning a fair-test experiment",
            "Drawing conclusions from experimental data"
        ],
        markingScheme: "General mode covers all skill areas with no board-specific weighting.",
        toleranceNote: "Standard tolerance: \u{00B1}1 smallest division for analogue instruments.",
        flagEmoji: "\u{1F9EA}",
        levelTag: "GENERAL",
        homeHeadlineLine1: "Physics Practical",
        homeHeadlineLine2: "Skills Trainer"
    )

    static func forCurriculum(_ curriculum: Curriculum) -> CurriculumProfile {
        switch curriculum {
        case .singapore: return singapore
        case .igcse: return igcse
        case .waec: return waec
        case .neco: return neco
        case .general: return general
        }
    }
}
