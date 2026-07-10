//
//  Models.swift
//  PhysicsPracticalCoach
//
//  Core domain enums and value types. Direct, faithful port of the Android
//  `core.model.Models.kt` file — same cases, same associated data, same
//  business meaning. Only the language idiom changes (Kotlin enum class ->
//  Swift enum with String raw values so persistence/JSON stays stable).
//

import Foundation

// MARK: - Curriculum

enum Curriculum: String, CaseIterable, Codable, Identifiable {
    case singapore = "SINGAPORE"
    case igcse = "IGCSE"
    case waec = "WAEC"
    case neco = "NECO"
    case general = "GENERAL"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .singapore: return "Singapore"
        case .igcse: return "IGCSE"
        case .waec: return "WAEC"
        case .neco: return "NECO"
        case .general: return "General"
        }
    }
}

// MARK: - Apparatus

enum ApparatusType: String, CaseIterable, Codable, Identifiable {
    case vernierCaliper = "VERNIER_CALIPER"
    case micrometer = "MICROMETER"
    case ammeter = "AMMETER"
    case voltmeter = "VOLTMETER"
    case newtonMeter = "NEWTON_METER"
    case stopwatch = "STOPWATCH"
    case thermometer = "THERMOMETER"
    case measuringCylinder = "MEASURING_CYLINDER"
    case burette = "BURETTE"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .vernierCaliper: return "Vernier caliper"
        case .micrometer: return "Micrometer screw gauge"
        case .ammeter: return "Ammeter"
        case .voltmeter: return "Voltmeter"
        case .newtonMeter: return "Newton-meter"
        case .stopwatch: return "Stopwatch"
        case .thermometer: return "Thermometer"
        case .measuringCylinder: return "Measuring cylinder"
        case .burette: return "Burette"
        }
    }

    var unit: String {
        switch self {
        case .vernierCaliper: return "cm"
        case .micrometer: return "mm"
        case .ammeter: return "A"
        case .voltmeter: return "V"
        case .newtonMeter: return "N"
        case .stopwatch: return "s"
        case .thermometer: return "\u{00B0}C"
        case .measuringCylinder: return "cm\u{00B3}"
        case .burette: return "cm\u{00B3}"
        }
    }

    /// Matches `ApparatusType.MVP_TYPES` on Android — the canonical ordering
    /// used by the "General" curriculum and any list screen with no filter.
    static let mvpTypes: [ApparatusType] = [
        .vernierCaliper, .micrometer, .ammeter, .voltmeter, .newtonMeter,
        .stopwatch, .thermometer, .measuringCylinder, .burette
    ]
}

// MARK: - Graph Coach

enum GraphCoachType: String, CaseIterable, Codable, Identifiable {
    case forceExtension = "FORCE_EXTENSION"
    case currentVoltage = "CURRENT_VOLTAGE"
    case distanceTime = "DISTANCE_TIME"
    case tSquaredVsLength = "T_SQUARED_VS_LENGTH"
    case sinIVsSinR = "SIN_I_VS_SIN_R"

    var id: String { rawValue }

    struct Definition {
        let label: String
        let xLabel: String
        let xUnit: String
        let yLabel: String
        let yUnit: String
        let gradientMeaning: String
    }

    var definition: Definition {
        switch self {
        case .forceExtension:
            return Definition(
                label: "Force vs extension",
                xLabel: "Extension", xUnit: "m",
                yLabel: "Force", yUnit: "N",
                gradientMeaning: "Gradient gives spring constant k (F = kx)."
            )
        case .currentVoltage:
            return Definition(
                label: "Current vs voltage",
                xLabel: "Current", xUnit: "A",
                yLabel: "Voltage", yUnit: "V",
                gradientMeaning: "Gradient gives resistance R (V = IR)."
            )
        case .distanceTime:
            return Definition(
                label: "Distance vs time",
                xLabel: "Time", xUnit: "s",
                yLabel: "Distance", yUnit: "m",
                gradientMeaning: "Gradient gives average speed for uniform motion."
            )
        case .tSquaredVsLength:
            return Definition(
                label: "T\u{00B2} vs Length (Pendulum)",
                xLabel: "Length L", xUnit: "m",
                yLabel: "Period\u{00B2} T\u{00B2}", yUnit: "s\u{00B2}",
                gradientMeaning: "Gradient = 4\u{03C0}\u{00B2}/g. Use it to find g = 4\u{03C0}\u{00B2}/gradient."
            )
        case .sinIVsSinR:
            return Definition(
                label: "sin i vs sin r (Refraction)",
                xLabel: "sin r", xUnit: "",
                yLabel: "sin i", yUnit: "",
                gradientMeaning: "Gradient gives the refractive index n of the glass block."
            )
        }
    }

    var label: String { definition.label }
}

// MARK: - Simulation

enum SimulationType: String, CaseIterable, Codable, Identifiable {
    case pendulum = "PENDULUM"
    case ohmsLaw = "OHMS_LAW"
    case springExtension = "SPRING_EXTENSION"
    case lensFocusing = "LENS_FOCUSING"
    case potentiometer = "POTENTIOMETER"
    case resistanceWire = "RESISTANCE_WIRE"
    case refraction = "REFRACTION"
    case moments = "MOMENTS"
    case vernierCaliper = "VERNIER_CALIPER"
    case densityDisplacement = "DENSITY_DISPLACEMENT"
    case coolingCurve = "COOLING_CURVE"
    case filamentLamp = "FILAMENT_LAMP"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .pendulum: return "Pendulum (Mechanical Oscillations)"
        case .ohmsLaw: return "Ohm's Law Circuit"
        case .springExtension: return "Spring Extension (F = kx)"
        case .lensFocusing: return "Converging Lens (1/f = 1/u + 1/v)"
        case .potentiometer: return "Potentiometer (Resistance Wire)"
        case .resistanceWire: return "Resistance of a Wire"
        case .refraction: return "Refraction through a Glass Block"
        case .moments: return "Principle of Moments"
        case .vernierCaliper: return "Vernier Caliper Measurement"
        case .densityDisplacement: return "Density by Displacement"
        case .coolingCurve: return "Cooling Curve"
        case .filamentLamp: return "Filament Lamp I-V Characteristic"
        }
    }

    var descriptionText: String {
        switch self {
        case .pendulum:
            return "Change the length and observe how the period changes. T = 2\u{03C0}\u{221A}(L/g)"
        case .ohmsLaw:
            return "Adjust voltage and resistance. Watch the ammeter respond to I = V/R."
        case .springExtension:
            return "Add masses to a spring. Plot force vs extension to see Hooke's Law."
        case .lensFocusing:
            return "Move the lens to focus an image. Explore the thin lens formula. (2023, 2016)"
        case .potentiometer:
            return "Slide the jockey along a resistance wire. Measure voltage across different lengths. (2023, 2022, 2018, 2014)"
        case .resistanceWire:
            return "Vary wire length, read V and I. Plot a V-I graph; find resistance from the gradient. (2025)"
        case .refraction:
            return "Vary angle of incidence and measure angle of refraction. Verify Snell's Law: n = sin i / sin r. (2021)"
        case .moments:
            return "Hang weights at different distances from a pivot. Balance the beam. (2015, 2014)"
        case .vernierCaliper:
            return "Slide the jaws closed on a rod. Read the main + vernier scales together to find its diameter."
        case .densityDisplacement:
            return "Lower a solid into a measuring cylinder and use the water it displaces to find its density."
        case .coolingCurve:
            return "Watch a heated liquid cool over time. Record readings to build a temperature-time graph."
        case .filamentLamp:
            return "Vary the voltage across a filament lamp and record current to see why it isn't ohmic."
        }
    }
}

// MARK: - Attempt mode

enum AttemptMode: String, Codable {
    case apparatusPractice = "APPARATUS_PRACTICE"
    case graphCoach = "GRAPH_COACH"
    case acePractice = "ACE_PRACTICE"
    /// A completed interactive lab experiment session (Pendulum, and every
    /// future drag-and-drop simulation) — distinct from the old ungraded
    /// exploratory simulations, which never recorded an attempt at all.
    case simulationLab = "SIMULATION_LAB"
}

// MARK: - Common mistake coaching

struct CommonMistake: Identifiable, Codable, Hashable {
    var id: String { title }
    let title: String
    let explanation: String
    let examinerPenalty: String
}

// MARK: - Apparatus visual state

/// Mirrors the Kotlin sealed class `ApparatusVisualState`. Swift has no direct
/// sealed-class equivalent with per-case stored properties, so this is
/// modelled as an enum with associated values — the idiomatic Swift pattern
/// for "one of several closed variants," preserving exhaustive `switch`
/// checking at every call site exactly like the Kotlin `when`.
enum ApparatusVisualState: Codable, Hashable {
    case vernier(mainScaleCm: Double, vernierCoincidence: Int, zeroErrorCm: Double)
    case micrometer(sleeveWholeMm: Int, showHalfMm: Bool, thimbleHundredths: Int, zeroErrorMm: Double)
    case ammeter(maxReading: Double, needleReading: Double)
    case stopwatch(minutes: Int, seconds: Int, tenths: Int)
    case thermometer(bulbTempC: Double, scaleMinC: Int, scaleMaxC: Int)
    case voltmeter(maxReading: Double, needleReading: Double)
    case newtonMeter(maxReading: Double, pointerReading: Double)
    case measuringCylinder(maxVolumeCm3: Int, liquidLevelCm3: Double, minorDivisionCm3: Double)
    case burette(readingCm3: Double)
}

struct ApparatusQuestion: Identifiable, Hashable {
    var id: String { "\(apparatusType.rawValue)-\(seed)" }
    let apparatusType: ApparatusType
    let seed: Int
    let prompt: String
    let correctReading: Double
    let tolerance: Double
    let unit: String
    let visualState: ApparatusVisualState
    let commonMistakes: [CommonMistake]
    let examTrap: String
}

struct ApparatusMarkResult {
    let correct: Bool
    let score: Int
    let feedback: [String]
    let mistakeExplanation: String?
    let examTrap: String
}

// MARK: - Graph coach data

struct GraphPoint: Hashable, Codable {
    let x: Double
    let y: Double
}

struct GraphDataset {
    let type: GraphCoachType
    let seed: Int
    let points: [GraphPoint]
    let expectedGradient: Double
}

struct GraphGradientResult {
    let correct: Bool
    let score: Int
    let expectedGradient: Double
    let studentGradient: Double?
    let feedback: [String]
    let explanation: String
}
