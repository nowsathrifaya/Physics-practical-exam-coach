# Lab Experiment Framework

iOS is the reference implementation for every new interactive "Lab"
experiment (Pendulum done; Hooke's Law, Moments, Density, Ohm's Law, Lens,
Refraction, Reflection, Centre of Gravity, etc. to follow). This doc
describes the shared architecture so it can be reproduced in Kotlin/Compose
on Android once each experiment is finalised here.

## Why "Lab" experiments are a separate thing from the old Simulations

The original Simulations tab (`GenericSimulationView` + `SimulationType`) is
**exploratory and ungraded** — drag a slider, watch a formula respond, no
attempt recorded. Real practical exams don't work that way: the student
performs a physical setup themselves, takes real measurements with real
error in them (their own reaction time, their own care in aligning apparatus),
records those measurements in a data table, and is graded against the
theoretical value with an exam-realistic tolerance.

"Lab" experiments (`Views/Simulation/PendulumLabView.swift` is the first and
the template) are that. They **are** graded, **do** record an `Attempt`
(`AttemptMode.simulationLab` / `"SIMULATION_LAB"`), and **do** show up in
Progress tab history/stats/streaks — a deliberate change from the old
Simulations behavior.

## The two-type split (copy this exactly for every new experiment)

**1. Apparatus state** — e.g. `PendulumLabState`
Owns *only* the physical simulation: what the student sees and drags,
driven by real wall-clock time where relevant (`Date()`/`TimeInterval`, not
a canned animation loop). Knows nothing about tasks, trials, scoring, or
curricula. This part is fully experiment-specific — a spring's drag
mechanic looks nothing like a pendulum's, and that's fine, it's not meant to
be shared.

**2. Experiment view model** — e.g. `PendulumExperimentViewModel`
Owns the task/session layer on top of the apparatus state:
- Assigns a randomised target for the task (seeded, via `SeededRandomNumberGenerator` on iOS — use a seeded `kotlin.random.Random` on Android for parity)
- Records each trial as a `LabReading` (raw measurement + optional derived value, e.g. raw stopwatch time -> derived period)
- Grades the finished session into a `LabRunResult` (correct/score/feedback/examTip), using the same tolerance-based philosophy as `ApparatusTrainer`/`GraphGradientMarker`
- Records the result via `LabAttemptRecorder`

This layer is *structurally* identical across every experiment even though
the physics inside each step differs completely:
`assign target -> record N trials -> calculate -> grade -> record attempt`.

**3. The View** stays thin. It composes `LabScaffoldView` (the shared shell:
title, instruction banner, apparatus area, controls, data table, feedback
card) with an experiment-specific `Canvas`/`DragGesture` apparatus view and
experiment-specific control buttons. A new experiment's SwiftUI code should
mostly be the Canvas drawing + gesture handling — the surrounding chrome is
free.

## Shared framework files (`Views/Simulation/Framework/`)

| File | Purpose | Android equivalent |
|---|---|---|
| `LabModels.swift` | `LabReading` (one recorded trial), `LabRunResult` (grading outcome) | Two Kotlin `data class`es, no framework dependency |
| `LabAttemptRecorder.swift` | Records a finished session as a graded `Attempt` | Thin Kotlin class wrapping `AttemptRepository`, identical shape |
| `LabComponents.swift` | `LabScaffoldView` (screen shell), `LabDataTableView`, `LabFeedbackCard`, `LabInstructionBanner` | Compose `@Composable` equivalents with the same slot order: apparatus -> controls -> data table -> feedback |
| `LabCanvasHelpers.swift` | Reusable `GraphicsContext` drawing functions: vertical ruler, protractor arc, weight/bob, label text | Free functions taking an Android `Canvas`/`Paint`, same tick-mark geometry |

## Design rules for every new experiment

1. **Prioritise realism over speed.** The student's own action (timing,
   dragging to align, reading a scale) should be the actual source of
   measurement error — don't fake or shortcut it.
2. **Drag-and-drop, not sliders**, wherever a real practical would have the
   student physically manipulate apparatus.
3. **Randomise the task** (target length, target mass, target angle, etc.)
   via a seeded RNG so each attempt is a fresh, reproducible scenario —
   never a fixed demo value.
4. **Record real trials** into `LabReading`s — most exam mark schemes
   expect >= 3 trials; nudge the student toward that in feedback rather than
   hard-blocking below it.
5. **Grade against the theoretical/small-effect value**, with a tolerance
   wide enough to accommodate genuine human reaction-time/reading error,
   narrow enough to still mean something. `PendulumExperimentViewModel`
   uses +/-8% on the timed period and +/-0.02 m on the apparatus setup as a
   reference scale.
6. **Feedback should teach**, not just say right/wrong — reference the
   specific exam-technique reasoning (see `AceQuestionBank` for the matching
   ACE question content per topic, so Lab feedback and ACE study content
   reinforce each other).
7. **Graphs**: where an experiment's real practical produces a graph (e.g.
   a multi-length pendulum reduction, or a V-I sweep), reuse
   `GraphDatasetGenerator`/`ScatterPlotCanvasView`/`LinearRegression` from
   the Graph Coach feature rather than building new plotting code.

## Current status

- **Pendulum** — fully built on this framework (`PendulumLabView.swift`). Original reference template: drag-to-length, drag-to-release-angle, real-time-driven swing, student times their own oscillations.
- **Hooke's Law / Spring** — fully built (`SpringLabView.swift`). New drag mechanic (drag a mass upward onto the hook past a threshold). Reuses `LinearRegression` + `ScatterPlotCanvasView` + the existing `.forceExtension` Graph Coach definition for the final F-x graph — first example of a Lab experiment reusing another feature's plotting engine wholesale.
- **Ohm's Law** — fully built (`OhmsLawLabView.swift`). Horizontal drag-gesture rheostat slider; student reads ammeter/voltmeter dials themselves (typed reading, tolerance-graded); reuses `ScatterPlotCanvasView` + the `.currentVoltage` definition for the V-I graph, R = gradient.
- **Density by Displacement** — fully built (`DensityLabView.swift`). Third distinct drag mechanic (drag an object down into the cylinder); two typed cylinder readings (before/after) matching the Apparatus Practice measuring-cylinder convention; student computes density themselves from their own readings + a given mass.
- **Moments** — fully built (`MomentsLabView.swift`). Fourth, and most different, drag mechanic: continuous live feedback (the beam tilts in real time as the student drags, like a real seesaw) rather than Pendulum/Spring/Density's discrete phases. Grades both the physics outcome (was it actually balanced) and reading accuracy (did the student's typed distance match where they actually placed the weight) separately. Feedback references the same "non-uniform beam" reasoning as `AceQuestionBank.moment_ace_01`.
- All other curriculum simulations (Lens, Refraction, Potentiometer, Resistance Wire, Vernier Caliper (simulation), Cooling Curve, Filament Lamp) — still on the old `GenericSimulationView` slider shell, pending conversion to this pattern one at a time, in curriculum priority order.

### A note on `LabDataTableView`

The table renders each row's own `label`/`derivedLabel` (not a single shared
column header inferred from the first row) — this was corrected while
building Density, whose two readings (V\u2081 before, V\u2082 after) are
genuinely different measurements on one row each, unlike Pendulum/Spring/
Ohm's Law where every row measures the same thing repeated across trials.
Any new experiment can mix either shape freely.

