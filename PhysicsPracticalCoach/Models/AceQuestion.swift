//
//  AceQuestion.swift
//  PhysicsPracticalCoach
//
//  Port of `core.model.AceQuestion.kt`. A single ACE/Planning written
//  question in the style of Singapore O-Level Paper 3.
//
//  Skill area tags match the four SEAB assessment objectives:
//    P   = Planning (identify variables, describe procedure, assess risks)
//    MMO = Manipulation, Measurement and Observation
//    PDO = Presentation of Data and Observations
//    ACE = Analysis, Conclusions and Evaluation
//

import Foundation
import SwiftUI

enum AceSkillArea: String, CaseIterable, Codable {
    case planning = "PLANNING"
    case mmo = "MMO"
    case pdo = "PDO"
    case ace = "ACE"

    var label: String {
        switch self {
        case .planning: return "Planning (P)"
        case .mmo: return "Measurement (MMO)"
        case .pdo: return "Data Presentation (PDO)"
        case .ace: return "Analysis & Evaluation (ACE)"
        }
    }

    /// Hex string preserved from Android; `colour` (a SwiftUI Color) is the
    /// convenience accessor views should use.
    var hex: String {
        switch self {
        case .planning: return "#2980B9"
        case .mmo: return "#27AE60"
        case .pdo: return "#8E44AD"
        case .ace: return "#D98B36"
        }
    }

    var colour: Color { Color(hex: hex) }
}

enum AceTopic: String, CaseIterable, Codable {
    case pendulum = "PENDULUM"
    case spring = "SPRING"
    case ohmsLaw = "OHMS_LAW"
    case potentiometer = "POTENTIOMETER"
    case resistanceWire = "RESISTANCE_WIRE"
    case refraction = "REFRACTION"
    case moments = "MOMENTS"
    case lens = "LENS"
    case generalMeasurement = "GENERAL_MEASUREMENT"
    case generalGraph = "GENERAL_GRAPH"
    case generalPlanning = "GENERAL_PLANNING"
    case heat = "HEAT"
    case density = "DENSITY"

    var label: String {
        switch self {
        case .pendulum: return "Mechanical Oscillations / Pendulum"
        case .spring: return "Spring Extension / Hooke's Law"
        case .ohmsLaw: return "Ohm's Law / DC Circuits"
        case .potentiometer: return "Potentiometer"
        case .resistanceWire: return "Resistance of a Wire"
        case .refraction: return "Refraction / Glass Block"
        case .moments: return "Principle of Moments"
        case .lens: return "Converging Lens"
        case .generalMeasurement: return "General Measurement Skills"
        case .generalGraph: return "Graph Skills (PDO)"
        case .generalPlanning: return "Experiment Planning"
        case .heat: return "Thermal Physics"
        case .density: return "Density Determination"
        }
    }
}

enum AceDifficulty: String, CaseIterable, Codable {
    case basic = "BASIC"
    case standard = "STANDARD"
    case challenging = "CHALLENGING"
}

struct AceQuestion: Identifiable, Hashable {
    let id: String
    let topic: AceTopic
    let skillArea: AceSkillArea
    let difficulty: AceDifficulty
    let marks: Int
    /// Which exam boards this question is relevant to. Empty set = applies to
    /// ALL curricula (universal question).
    let curricula: Set<Curriculum>
    /// The question as it would appear on the exam paper.
    let questionText: String
    /// What the mark scheme awards, written as bullet points the student can self-check.
    let modelAnswer: String
    /// What students commonly write that scores zero.
    let commonMistakes: String
    /// Examiner report tip — the single most important thing to remember.
    let examinerTip: String

    init(
        id: String, topic: AceTopic, skillArea: AceSkillArea, difficulty: AceDifficulty,
        marks: Int, curricula: Set<Curriculum> = [], questionText: String,
        modelAnswer: String, commonMistakes: String, examinerTip: String
    ) {
        self.id = id
        self.topic = topic
        self.skillArea = skillArea
        self.difficulty = difficulty
        self.marks = marks
        self.curricula = curricula
        self.questionText = questionText
        self.modelAnswer = modelAnswer
        self.commonMistakes = commonMistakes
        self.examinerTip = examinerTip
    }
}

extension Color {
    /// Minimal `#RRGGBB` hex initialiser so `AceSkillArea.hex` values from the
    /// Android design system can be reused as-is.
    init(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized = sanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
