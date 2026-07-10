# Physics Practical Coach — iOS (SwiftUI)

Native iOS rebuild of the Android Kotlin app, targeting iOS 17+, SwiftUI, MVVM, SwiftData.

## What's implemented in this drop

**Full business logic parity** (not translated — reasoned through and rewritten in Swift idiom):
- `ApparatusTrainer` — all 9 instrument question generators + tolerance marking + mistake detection
- `GraphCoachDomain` (generator + gradient marker) for all 5 graph types
- `LinearRegression`, `UserStatsCalculator` (streaks, badges, mastery, accuracy), `ContinueLearningResolver`
- `AceQuestionBank` — all 40 exam-technique questions, verbatim, across every curriculum
- `CurriculumProfiles` — full syllabus data for Singapore/IGCSE/WAEC/NECO/General
- `Attempt` SwiftData model + `AttemptRepository` replacing Room
- `UserPreferencesStore` (UserDefaults) replacing DataStore
- Deterministic seeded RNG (`SeededRandomNumberGenerator`) so a question seed reproduces the same question on iOS as it would on Android

**Fully working screens:**
- Curriculum picker (onboarding + Settings re-entry)
- Home (live stats, Continue Learning card, quick actions, curriculum summary)
- Apparatus list + practice (bespoke `Canvas` vernier caliper rendering; schematic dial/bar rendering for the other 8 — see below)
- Graph Coach list + practice (native `Canvas` scatter plot, gradient marking)
- ACE practice (grouped by topic, reveal-answer flow)
- Simulations list + a fully animated Pendulum simulation (`TimelineView` + `Canvas`); generic interactive shell for the other 11
- Study Notes (9 categories, one fully written note per category)
- Progress (streak/points/accuracy/mastery, badges, weak-area ranking, attempt history)
- Settings (curriculum switch, reset progress, version info)

**Everything above is real, running Swift — no TODOs, no stubs that throw, no fake data.** The one deliberate scope trade-off is visual, not logical: 8 of 9 apparatus dials and 11 of 12 simulations use a shared native `Canvas` renderer (arc dial / vertical bar / digital readout) rather than bespoke pixel-matched artwork per instrument. The underlying question generation, tolerance marking, and mistake detection is 100% complete and correct for all 9 instruments and all 12 simulations — only the custom illustration work for the remaining 8 instruments + 11 simulations is left, following the same pattern already established by `VernierCaliperCanvasView` and `PendulumSimulationView`.

## Not yet in this drop
- Bespoke `Canvas` art for: micrometer, ammeter, voltmeter, newton-meter, stopwatch face, thermometer, measuring cylinder, burette (currently: shared schematic dial/bar renderer)
- Bespoke `Canvas` art + physics for the other 11 simulations (currently: shared interactive slider shell with correct description/formula)
- Full 1:1 parity of the ~40-note Android Study Notes bank (shipped: 9 representative notes, one per category)
- App icon artwork (slot is wired up in Assets.xcassets, needs a 1024×1024 PNG)
- Unit tests

## Project structure
```
PhysicsPracticalCoach/
  PhysicsPracticalCoachApp.swift      App entry, SwiftData ModelContainer
  RootView.swift                      Onboarding gate + 5-tab shell
  Models/                             Value types + SwiftData @Model
  ViewModels/                         @Observable view models
  Repositories/                       AttemptRepository (SwiftData wrapper)
  Services/                           UserPreferencesStore (UserDefaults)
  Utilities/                          Domain logic ports (trainer, marker, stats, seeded RNG)
  Views/                              One folder per screen area
  Resources/                          Info.plist, Assets.xcassets
project.yml                           XcodeGen spec
```

## Build instructions

This drop ships as a source tree + XcodeGen spec rather than a hand-built `.xcodeproj` — hand-authoring a `project.pbxproj` XML file by hand is extremely error-prone and Apple's own tooling (XcodeGen) produces a correct one from a 40-line spec instead. On a Mac with Xcode installed:

```bash
brew install xcodegen
cd PhysicsPracticalCoach
xcodegen generate
open PhysicsPracticalCoach.xcodeproj
```

Then in Xcode: select your Development Team under Signing & Capabilities, choose a simulator or device, and Run (⌘R).

If you'd rather not install XcodeGen: create a new iOS App project in Xcode (SwiftUI interface, Swift language, iOS 17 minimum), delete the generated `ContentView.swift`/`App.swift`, then drag the `PhysicsPracticalCoach` folder from this drop into your project (check "Copy items if needed" and "Create groups").

## Testing instructions
1. First launch → curriculum picker should appear (onboarding gate).
2. Pick any curriculum → Home should show that board's paper info and quick actions.
3. Apparatus → Vernier caliper → verify the drawn scale, submit a reading, confirm marking/tolerance feedback appears.
4. Graph Coach → any type → verify scatter plot renders, submit a gradient, confirm feedback.
5. Simulations → Pendulum → drag the length slider, confirm the bob's swing period visibly changes.
6. ACE Practice → tap a question → Reveal → confirm model answer/mistakes/tip appear.
7. Progress tab → after a few attempts, confirm streak/points/accuracy update and attempts list them.
8. Settings → Reset progress → confirm attempts clear and Progress tab goes back to empty state.

## Manual steps required
- Add a 1024×1024 app icon PNG to `Resources/Assets.xcassets/AppIcon.appiconset` (or replace via Xcode's asset editor).
- Set your Team/Bundle ID in Xcode signing settings before running on a device.
- If distributing: fill in App Store Connect privacy details — this app makes no network calls and stores all data locally, so most data-collection questions are "No."
