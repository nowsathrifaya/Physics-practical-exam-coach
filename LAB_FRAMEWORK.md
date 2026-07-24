# Lab Experiment Framework

iOS is the reference implementation for every interactive "Lab" experiment.
All twelve curriculum simulation types (Pendulum, Hooke's Law, Ohm's Law,
Density, Moments, Potentiometer, Lens, Refraction, Resistance Wire, Vernier
Caliper, Cooling Curve, Filament Lamp) are now built — see the
experiment-by-experiment status below for each one's specific design. This
doc describes the shared architecture so it can be reproduced in
Kotlin/Compose on Android.

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
- **Potentiometer** — fully built (`PotentiometerLabView.swift`), converted first among the remaining `GenericSimulationView` placeholders since it's the most frequently examined (WAEC/NECO past papers 2014, 2018, 2022, 2023). Fifth drag mechanic: a jockey dragged horizontally along a fixed 1 m wire, reusing the same one-axis drag math as Ohm's Law's rheostat but with a cm ruler underneath instead of an ohm scale. The driver current and wire resistance-per-metre are hidden constants; V is directly proportional to jockey position l, so the final graph reuses a new `.potentialGradient` Graph Coach definition (gradient = potential gradient K = I x r). A hidden, sometimes-nonzero contact-resistance offset means the V-l line occasionally doesn't pass through the origin — feedback explains why, directly matching `AceQuestionBank.poten_ace_02`'s reasoning, and the instruction text bakes in `poten_ace_01`'s "tap, don't hold" jockey technique.
- **Lens (Converging Lens / thin lens formula)** — fully built (`LensLabView.swift`). Sixth drag mechanic, and the first with *two* sequential drags per trial on one shared axis: the lens is dragged first (setting object distance u), then the screen is dragged to search for sharp focus, exactly like a real bracket-method search. The blur the student sees is a genuine `GraphicsContext` Gaussian blur whose radius grows with distance from the true image position \u2014 nothing about "how sharp is sharp" is faked or hinted numerically, matching `AceQuestionBank.lens_ace_01`'s point that sharpness of the image edges (not size) is the correct focus criterion. Readings are plotted as 1/v vs 1/u (new `.reciprocalLensDistances` Graph Coach definition) \u2014 the exact rearrangement `AceQuestionBank.lens_pdo_01` asks students to derive \u2014 with the gradient checked against \u22121 and f taken from the reciprocal of the y-intercept, rather than the gradient itself being the answer (unlike every other graph-based lab so far).
- **Refraction (Glass Block)** — fully built (`RefractionLabView.swift`), converted next among the remaining `GenericSimulationView` placeholders since it closes the optics cluster (Lens was the only optics lab) with a skill nothing else in the app tests: reading angles off a protractor rather than a linear scale. Eighth drag mechanic, and the first rotational one: the student drags the incident ray around a fixed-radius arc above the point of incidence to choose their own angle of incidence i (their experimental setup, not a source of error — same principle as Lens's u). Once locked, the refracted ray is drawn genuinely bent via Snell's law by a hidden refractive index, and a protractor is revealed for the student to read the angle of refraction r themselves and type it in — that by-eye reading is the real source of measurement error, matching the parallax-style error `AceQuestionBank.refrac_ace_01` describes for the real optical-pins method. Readings are plotted as sin i vs sin r (existing `.sinIVsSinR` Graph Coach definition, gradient = n) — the exact axes `AceQuestionBank.refrac_ace_02` asks students to interpret. Diagram-fidelity pass added afterwards: labelled point of incidence O, curved angle-indicator arcs for i and r (new reusable `LabCanvasHelpers.drawAngleIndicatorArc`), a two-tier protractor scale (5° medium ticks via a new opt-in `minorTickStepDeg` parameter on `drawProtractorArc`, 10° labelled major ticks — true 1° ticks aren't legible at phone-screen protractor radii, so a "zoom in to read" toggle substitutes for finer on-screen resolution), light-blue glass styling with Air/Glass labels, a non-blocking plausibility warning on physically-impossible readings, a precise "measured from the surface, not the normal" diagnostic derived from Snell's law per trial (not guessed), a trial-progress checklist, and a setup-phase nudge toward a wider spread of angles. Deliberately deferred: animated ray-bend transition, a reference "good graph shape" illustration, fit-quality/outlier graph feedback (would need extending the shared `LinearRegression` result with R², affecting other labs), sound/haptics/drag-snap/fade polish, and a full virtual-optical-pins interaction model (a genuine v2 redesign, not an incremental addition — the student would still need to read a protractor afterwards anyway).
- **Resistance Wire** — fully built (`ResistanceWireLabView.swift`), combining two existing primitives in a new way rather than a new mechanic: the wire-and-sliding-contact drag from Potentiometer (here the contact sets how much wire is actually in circuit, changing current with no separate rheostat needed) paired with the dual ammeter/voltmeter typed reading from Ohm's Law. R = V/I is computed per trial from the student's own readings, then plotted as R vs l (new `.resistanceVsLength` Graph Coach definition) — the exact axes `AceQuestionBank.resis_ace_01` asks students to interpret — with resistivity ρ recovered from a given cross-sectional area A and the gradient (ρ = gradient × A), matching that question's model answer precisely. Circuit-realism pass added afterwards: length shown prominently in cm (what the ruler is actually marked in) alongside a given-area/`R = V/I` header instead of burying them in the instruction text, a clearly highlighted "wire in circuit" active segment, a schematic switch, a voltmeter genuinely drawn in parallel across the active length (not just implied by a separate dial) with a "Sliding contact" label, a zoom toggle plus finer 2° minor ticks on the meters (reusing the same `minorTickStepDeg` addition from the Refraction pass), a non-blocking plausibility warning on an implied V/I resistance far outside what the length allows, a setup-phase nudge toward a wider spread of lengths, the shared `TrialProgressView` (promoted out of Refraction into `LabComponents.swift` since it's generic trial-tracking UI, not lab-specific physics), and residual-based outlier detection computed honestly from the regression fit rather than guessed. Deliberately deferred, same reasoning as Refraction: needle animation, fades, haptics, and an "Examiner Report" mark-out-of-10 card (that would be a shared `LabFeedbackCard` change affecting every lab, not a Resistance Wire change, so it's a separate cross-cutting pass). Also explicitly out of scope: catching a student's own V/I arithmetic mistake, since students never do that division themselves here — R is always derived automatically from their two typed readings, the same convention used app-wide, and reversing that would need a third stored value per trial beyond `LabReading`'s two-slot model.
- **Vernier Caliper** — fully built (`VernierCaliperLabView.swift`), converted next among the remaining `GenericSimulationView` placeholders. Ninth drag mechanic, and the first where the drag itself is deliberately *not* the source of error: closing the jaws is a simple squeeze-shut gesture (reusing Density's drag-past-threshold snap) since a real caliper's jaws stop dead against the object regardless of how carefully the student drags. First Lab experiment to reuse another feature's apparatus rendering outright — `VernierCaliperCanvasView` from `ApparatusVisuals.swift` — rather than drawing new Canvas code, and first to reuse Apparatus Practice's own grading convention: the zero error is *given* (shown directly on the instrument), and the tested skill is reading the main scale + the one coinciding vernier line and correctly applying that given correction, matching `AnsweringTechniquesView.ans_vernier` step-by-step. The rod is measured at three points along its length with genuine (small) non-uniformity between them, giving a real reason to take >= 3 readings and average rather than the framework's trial-count guidance being the only reason.
- **Cooling Curve** — fully built (`CoolingCurveLabView.swift`), converted next, leaving only Filament Lamp on the old placeholder shell. First Lab with no drag mechanic at all — driven purely by real wall-clock time, reusing `ThermometerCanvasView` from `ApparatusVisuals.swift` for the reading (second experiment, after Vernier Caliper, to reuse an Apparatus Practice renderer outright). Genuinely deviates from every other graph-adjacent Lab by *not* using `GraphDatasetGenerator`/`LinearRegression`: the underlying physics is a combined Newton's-law-of-cooling + isothermal-plateau model (exponential decay -> constant temperature while latent heat releases during solidification -> exponential decay again), which has no single gradient to grade. The graded quantity is the freezing point the student states from their own recorded data — nothing in the UI ever names or highlights the plateau; the student only notices it because two of their own readings taken a while apart come back suspiciously close, exactly how a real cooling-curve practical works. `plateauStartS` is derived algebraically from the session's hidden room/start temperatures and cooling constant rather than chosen independently, so the model stays physically self-consistent.
- **Filament Lamp** — fully built (`FilamentLampLabView.swift`), the last remaining `GenericSimulationView` placeholder converted. Every curriculum simulation type now has a full Lab build. Structurally the closest sibling to Ohm's Law (same rheostat drag + ammeter/voltmeter typed reading, reusing the identical `.currentVoltage` Graph Coach axis definition for its results scatter plot), but built specifically to be the one place that circuit shape *isn't* ohmic: lamp resistance R = R0 + kI grows with current as the filament heats up, so the true circuit current is solved as the positive root of the resulting quadratic equation (kI^2 + (rheostat + R0)I - EMF = 0) rather than read off directly. Like Cooling Curve, deliberately skips `GraphGradientMarker`/`LinearRegression` — a curved I-V relationship has no single gradient to grade — and instead grades a resistance RATIO (R at the student's own highest current ÷ R at their own lowest current), which is the standard exam technique for demonstrating non-ohmic behaviour. Adds a small non-numeric touch new to this Lab: the bulb itself visibly glows brighter as current rises, previewing what the dial readings will show the same way a real filament lamp does. Predates the shared `TrialProgressView`/plausibility-warning/zoom-toggle polish pass applied afterwards to Refraction and Resistance Wire — a candidate for the same treatment in a future pass, not applied here to keep this merge scoped to adding the missing experiment rather than reworking an already-reviewed one.
- All twelve curriculum simulation types are now fully built on the Lab framework; `GenericSimulationView` remains only as a fallback shell for any future simulation type added without an immediate Lab conversion.

### A note on `LabDataTableView`

The table renders each row's own `label`/`derivedLabel` (not a single shared
column header inferred from the first row) — this was corrected while
building Density, whose two readings (V\u2081 before, V\u2082 after) are
genuinely different measurements on one row each, unlike Pendulum/Spring/
Ohm's Law where every row measures the same thing repeated across trials.
Any new experiment can mix either shape freely.

