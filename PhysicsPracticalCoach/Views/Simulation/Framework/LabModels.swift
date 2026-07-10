//
//  LabModels.swift
//  PhysicsPracticalCoach
//
//  Shared data shapes for every interactive "Lab" simulation (Pendulum,
//  and every future one: Hooke's Law, Moments, Density, Ohm's Law, Lens,
//  Refraction, Reflection, Centre of Gravity, etc).
//
//  ARCHITECTURE NOTE FOR ANDROID PORTING:
//  These three types are the entire "contract" a lab experiment needs to
//  fulfil to plug into the shared UI shell (`LabScaffoldView`) and the
//  shared grading/recording pipeline (`LabAttemptRecorder`). When porting
//  a new experiment to Android, recreate these three types first (as plain
//  Kotlin data classes), then the equivalent Compose scaffold — the rest of
//  each experiment's logic (its own @Observable/ViewModel state + its own
//  Canvas/DragGesture apparatus view) is experiment-specific and does not
//  need to match iOS structurally, only behaviourally.
//

import Foundation

/// One recorded measurement during a lab trial — e.g. trial 2's timed
/// oscillation reading, or a spring's extension for a given load. Every
/// experiment's data table is built from an array of these, so the table
/// UI (`LabDataTableView`) never needs experiment-specific code.
struct LabReading: Identifiable, Hashable {
    let id = UUID()
    /// 1-based trial number, shown as a table row label.
    let trialNumber: Int
    /// What was measured, e.g. "t (20 osc)", "Extension x", "Current I".
    let label: String
    let value: Double
    let unit: String
    /// Optional derived value shown in a second column, e.g. period T
    /// computed from a raw oscillation time — kept alongside the raw
    /// reading so students see both the measurement and what it implies,
    /// matching how a real lab notebook / data table is laid out.
    var derivedLabel: String? = nil
    var derivedValue: Double? = nil
    var derivedUnit: String? = nil
}

/// The outcome of grading a finished lab session — deliberately the same
/// shape as `ApparatusMarkResult` / `GraphGradientResult` elsewhere in the
/// app, so `LabFeedbackCard` can present all three consistently and a
/// student never has to learn a different feedback layout per mode.
struct LabRunResult {
    let correct: Bool
    let score: Int
    let feedback: [String]
    let examTip: String
}
