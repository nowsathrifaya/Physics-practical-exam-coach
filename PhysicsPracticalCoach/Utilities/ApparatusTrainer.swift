//
//  ApparatusTrainer.swift
//  PhysicsPracticalCoach
//
//  Full port of `domain.apparatus.ApparatusTrainer.kt`. Generates a
//  deterministic reading question for each instrument from a seed, and marks
//  a student's submitted reading against tolerance, detecting the most
//  likely specific mistake so feedback can name it rather than just saying
//  "wrong."
//

import Foundation

struct ApparatusTrainer {

    func question(type: ApparatusType, seed: Int, curriculum: Curriculum = .general) -> ApparatusQuestion {
        precondition(ApparatusType.mvpTypes.contains(type), "Unsupported apparatus type: \(type)")
        var rng = SeededRandomNumberGenerator(seed: seed)
        let base: ApparatusQuestion
        switch type {
        case .vernierCaliper: base = vernierQuestion(&rng, seed)
        case .micrometer: base = micrometerQuestion(&rng, seed)
        case .ammeter: base = ammeterQuestion(&rng, seed)
        case .voltmeter: base = voltmeterQuestion(&rng, seed)
        case .newtonMeter: base = newtonMeterQuestion(&rng, seed)
        case .stopwatch: base = stopwatchQuestion(&rng, seed)
        case .thermometer: base = thermometerQuestion(&rng, seed)
        case .measuringCylinder: base = measuringCylinderQuestion(&rng, seed)
        case .burette: base = buretteQuestion(&rng, seed)
        }
        return applyCurriculum(base, curriculum: curriculum)
    }

    /// Curricula differ in how strictly readings are marked and what
    /// conventions students are taught to follow. Singapore O-Level and
    /// IGCSE mark instrument readings tightly to the stated least count;
    /// WAEC/NECO practical marking schemes are typically more forgiving of a
    /// one-division reading error, so the tolerance band is widened
    /// accordingly.
    private func applyCurriculum(_ question: ApparatusQuestion, curriculum: Curriculum) -> ApparatusQuestion {
        let toleranceMultiplier: Double
        switch curriculum {
        case .singapore, .igcse: toleranceMultiplier = 1.0
        case .waec, .neco: toleranceMultiplier = 1.5
        case .general: toleranceMultiplier = 1.0
        }
        let note = curriculumPromptNote(curriculum)
        return ApparatusQuestion(
            apparatusType: question.apparatusType,
            seed: question.seed,
            prompt: "\(question.prompt) \(note)",
            correctReading: question.correctReading,
            tolerance: round2(question.tolerance * toleranceMultiplier),
            unit: question.unit,
            visualState: question.visualState,
            commonMistakes: question.commonMistakes,
            examTrap: question.examTrap
        )
    }

    private func curriculumPromptNote(_ curriculum: Curriculum) -> String {
        switch curriculum {
        case .singapore: return "(Singapore practical convention: state the reading to the instrument's full precision.)"
        case .igcse: return "(IGCSE convention: record the reading with its correct unit and significant figures.)"
        case .waec: return "(WAEC convention: show the scale reading clearly before applying any correction.)"
        case .neco: return "(NECO convention: show the scale reading clearly before applying any correction.)"
        case .general: return "(Record the reading with the correct unit.)"
        }
    }

    func mark(question: ApparatusQuestion, studentReading: Double?) -> ApparatusMarkResult {
        guard let studentReading else {
            return ApparatusMarkResult(
                correct: false,
                score: 0,
                feedback: [
                    "Enter a numeric reading with the correct unit before submitting.",
                    "Correct reading: \(format(question.correctReading)) \(question.unit)."
                ],
                mistakeExplanation: "No reading submitted.",
                examTrap: question.examTrap
            )
        }

        let error = abs(studentReading - question.correctReading)
        let correct = error <= question.tolerance
        var feedback: [String] = []
        let mistakeExplanation: String?
        if correct {
            feedback.append("Reading accepted within +/- \(format(question.tolerance)) \(question.unit).")
            feedback.append("Correct reading: \(format(question.correctReading)) \(question.unit).")
            mistakeExplanation = nil
        } else {
            let likelyMistake = detectLikelyMistake(question: question, studentReading: studentReading)
            feedback.append("Your reading \(format(studentReading)) \(question.unit) is outside tolerance.")
            feedback.append("Correct reading: \(format(question.correctReading)) \(question.unit).")
            feedback.append(likelyMistake.explanation)
            mistakeExplanation = likelyMistake.explanation
        }
        return ApparatusMarkResult(
            correct: correct,
            score: correct ? 100 : 40,
            feedback: feedback,
            mistakeExplanation: mistakeExplanation,
            examTrap: question.examTrap
        )
    }

    // MARK: - Question generators

    private func vernierQuestion(_ rng: inout SeededRandomNumberGenerator, _ seed: Int) -> ApparatusQuestion {
        let mainScaleCm = Double(rng.nextInt(10, 80)) / 10.0
        let vernierCoincidence = rng.nextInt(0, 10)
        let zeroErrorCm = Double(rng.nextInt(-2, 3)) / 100.0
        let observed = mainScaleCm + (Double(vernierCoincidence) * 0.01)
        let correct = round2(observed - zeroErrorCm)
        let visual = ApparatusVisualState.vernier(
            mainScaleCm: mainScaleCm, vernierCoincidence: vernierCoincidence, zeroErrorCm: zeroErrorCm
        )
        return ApparatusQuestion(
            apparatusType: .vernierCaliper, seed: seed,
            prompt: "Read the vernier caliper. Least count = 0.01 cm. Check zero error before final answer.",
            correctReading: correct, tolerance: 0.01, unit: ApparatusType.vernierCaliper.unit,
            visualState: visual, commonMistakes: vernierMistakes(),
            examTrap: "Students often forget to subtract positive zero error or add negative zero error."
        )
    }

    private func micrometerQuestion(_ rng: inout SeededRandomNumberGenerator, _ seed: Int) -> ApparatusQuestion {
        let sleeveWholeMm = rng.nextInt(0, 25)
        let showHalfMm = rng.nextBoolean()
        let thimbleHundredths = rng.nextInt(0, 50)
        let zeroErrorMm = Double(rng.nextInt(-3, 4)) / 100.0
        let observed = Double(sleeveWholeMm) + (showHalfMm ? 0.5 : 0.0) + (Double(thimbleHundredths) / 100.0)
        let correct = round2(observed - zeroErrorMm)
        let visual = ApparatusVisualState.micrometer(
            sleeveWholeMm: sleeveWholeMm, showHalfMm: showHalfMm,
            thimbleHundredths: thimbleHundredths, zeroErrorMm: zeroErrorMm
        )
        return ApparatusQuestion(
            apparatusType: .micrometer, seed: seed,
            prompt: "Read the micrometer screw gauge. Thimble divisions are 0.01 mm. Apply zero error correction.",
            correctReading: correct, tolerance: 0.01, unit: ApparatusType.micrometer.unit,
            visualState: visual, commonMistakes: micrometerMistakes(),
            examTrap: "A common trap is ignoring the 0.5 mm sleeve mark or misreading the thimble by one division."
        )
    }

    private func ammeterQuestion(_ rng: inout SeededRandomNumberGenerator, _ seed: Int) -> ApparatusQuestion {
        let maxReading: Double = rng.nextBoolean() ? 1.0 : 5.0
        let divisions = maxReading == 1.0 ? 10 : 50
        let needleIndex = rng.nextInt(1, divisions)
        let correct = round2(maxReading * Double(needleIndex) / Double(divisions))
        let visual = ApparatusVisualState.ammeter(maxReading: maxReading, needleReading: correct)
        return ApparatusQuestion(
            apparatusType: .ammeter, seed: seed,
            prompt: "Read the ammeter needle position. Avoid parallax and note the scale maximum.",
            correctReading: correct, tolerance: maxReading == 1.0 ? 0.05 : 0.1,
            unit: ApparatusType.ammeter.unit, visualState: visual, commonMistakes: ammeterMistakes(),
            examTrap: "Parallax and using the wrong scale range are the most common ammeter errors in practical exams."
        )
    }

    private func voltmeterQuestion(_ rng: inout SeededRandomNumberGenerator, _ seed: Int) -> ApparatusQuestion {
        // SEAB apparatus list: f.s.d. 3 V or 5 V
        let fsd: Double = rng.nextBoolean() ? 3.0 : 5.0
        let reading = round2(rng.nextDouble() * fsd * 0.85 + fsd * 0.05) // 5-90% of fsd
        let visual = ApparatusVisualState.voltmeter(maxReading: fsd, needleReading: reading)
        return ApparatusQuestion(
            apparatusType: .voltmeter, seed: seed,
            prompt: "Record the voltmeter reading in V. The meter has f.s.d. \(Int(fsd)) V.",
            correctReading: reading, tolerance: fsd * 0.02, // +/-2% of fsd, standard O-Level tolerance
            unit: ApparatusType.voltmeter.unit, visualState: visual, commonMistakes: voltmeterMistakes(fsd: fsd),
            examTrap: "Candidates often read from the wrong scale when dual-scale voltmeters (3 V / 5 V) are used."
        )
    }

    private func newtonMeterQuestion(_ rng: inout SeededRandomNumberGenerator, _ seed: Int) -> ApparatusQuestion {
        // SEAB apparatus list: 1 N or 2.5 N newton-meters
        let fsd: Double = rng.nextBoolean() ? 1.0 : 2.5
        let divisionSize = 0.1
        let reading = round2(
            (Double(rng.nextInt(1, Int(fsd / divisionSize))) * divisionSize) + rng.nextDouble() * divisionSize * 0.9
        )
        let clamped = min(reading, fsd * 0.95)
        let visual = ApparatusVisualState.newtonMeter(maxReading: fsd, pointerReading: clamped)
        return ApparatusQuestion(
            apparatusType: .newtonMeter, seed: seed,
            prompt: "Read the newton-meter in N. Hold the instrument vertically with the pointer visible.",
            correctReading: round2(clamped), tolerance: divisionSize / 2,
            unit: ApparatusType.newtonMeter.unit, visualState: visual, commonMistakes: newtonMeterMistakes(),
            examTrap: "Newton-meters must be held vertically and zeroed before use. Horizontal use introduces friction errors."
        )
    }

    private func measuringCylinderQuestion(_ rng: inout SeededRandomNumberGenerator, _ seed: Int) -> ApparatusQuestion {
        // SEAB: 50 cm3 or 100 cm3
        let maxVol = rng.nextBoolean() ? 50 : 100
        let minorDiv = 1.0
        let correct = round2(Double(rng.nextInt(5, maxVol - 5)) + rng.nextDouble() * 0.8)
        let visual = ApparatusVisualState.measuringCylinder(
            maxVolumeCm3: maxVol, liquidLevelCm3: correct, minorDivisionCm3: minorDiv
        )
        return ApparatusQuestion(
            apparatusType: .measuringCylinder, seed: seed,
            prompt: "Record the volume of liquid in cm\u{00B3}. Read from the bottom of the meniscus at eye level.",
            correctReading: correct, tolerance: minorDiv / 2,
            unit: ApparatusType.measuringCylinder.unit, visualState: visual,
            commonMistakes: measuringCylinderMistakes(),
            examTrap: "Reading from the top of the meniscus (not the base) is the single most common error in density and volume experiments."
        )
    }

    private func buretteQuestion(_ rng: inout SeededRandomNumberGenerator, _ seed: Int) -> ApparatusQuestion {
        // Burette: 0 at top, 50 at bottom, read to 0.05 cm3 (nearest 0.05 mL)
        let rawReading = Double(rng.nextInt(0, 490)) / 10.0 // 0.0-49.0
        let correct = round2(rawReading + Double(rng.nextInt(0, 2)) * 0.05)
        let visual = ApparatusVisualState.burette(readingCm3: correct)
        return ApparatusQuestion(
            apparatusType: .burette, seed: seed,
            prompt: "Record the burette reading in cm\u{00B3}. Note: zero is at the TOP, 50 at the bottom. Read at the bottom of the meniscus.",
            correctReading: correct, tolerance: 0.05,
            unit: ApparatusType.burette.unit, visualState: visual, commonMistakes: buretteMistakes(),
            examTrap: "The burette scale runs from 0 (top) to 50 (bottom) \u{2014} the opposite of a measuring cylinder. Reading upward gives a volume that equals 50 minus the correct answer."
        )
    }

    private func stopwatchQuestion(_ rng: inout SeededRandomNumberGenerator, _ seed: Int) -> ApparatusQuestion {
        let minutes = rng.nextInt(0, 10)
        let seconds = rng.nextInt(0, 60)
        let tenths = rng.nextInt(0, 10)
        let correct = round2(Double(minutes) * 60.0 + Double(seconds) + Double(tenths) / 10.0)
        let visual = ApparatusVisualState.stopwatch(minutes: minutes, seconds: seconds, tenths: tenths)
        return ApparatusQuestion(
            apparatusType: .stopwatch, seed: seed,
            prompt: "Record the stopwatch reading in seconds to 1 decimal place. Express as total seconds, not mm:ss.",
            correctReading: correct, tolerance: 0.1,
            unit: ApparatusType.stopwatch.unit, visualState: visual, commonMistakes: stopwatchMistakes(),
            examTrap: "Students often write the display time directly (e.g. 1:23.4) rather than converting to total seconds (83.4 s), losing the answer mark."
        )
    }

    private func thermometerQuestion(_ rng: inout SeededRandomNumberGenerator, _ seed: Int) -> ApparatusQuestion {
        let scaleMin = rng.randomElement([0, 20, 30, 60])
        let scaleMax = scaleMin + [50, 30, 20][rng.nextInt(0, 3)]
        let correct = round2(Double(scaleMin) + rng.nextDouble() * Double(scaleMax - scaleMin))
        let visual = ApparatusVisualState.thermometer(bulbTempC: correct, scaleMinC: scaleMin, scaleMaxC: scaleMax)
        return ApparatusQuestion(
            apparatusType: .thermometer, seed: seed,
            prompt: "Record the thermometer reading in \u{00B0}C. Interpolate between the nearest division marks.",
            correctReading: correct, tolerance: 0.5,
            unit: ApparatusType.thermometer.unit, visualState: visual, commonMistakes: thermometerMistakes(),
            examTrap: "Parallax when reading a liquid-in-glass thermometer at eye level is the most commonly penalized error."
        )
    }

    // MARK: - Mistake detection

    private func detectLikelyMistake(question: ApparatusQuestion, studentReading: Double) -> CommonMistake {
        let mistakes = question.commonMistakes
        switch question.visualState {
        case let .vernier(mainScaleCm, vernierCoincidence, _):
            let withoutZero = round2(mainScaleCm + Double(vernierCoincidence) * 0.01)
            return abs(studentReading - withoutZero) <= question.tolerance ? mistakes[1] : mistakes[0]

        case let .micrometer(sleeveWholeMm, showHalfMm, thimbleHundredths, _):
            let withoutZero = round2(
                Double(sleeveWholeMm) + (showHalfMm ? 0.5 : 0.0) + Double(thimbleHundredths) / 100.0
            )
            return abs(studentReading - withoutZero) <= question.tolerance ? mistakes[1] : mistakes[0]

        case .ammeter:
            return mistakes[0]
        case .voltmeter:
            return mistakes[0]
        case .newtonMeter:
            return mistakes[0]

        case let .stopwatch(minutes, seconds, tenths):
            // Check if student read minutes as full seconds (e.g. 1:23.4 read as 123.4 s)
            let minutesAsSeconds = Double(minutes) * 60 + Double(seconds) + Double(tenths) / 10.0
            let digitsAsDecimal = Double(minutes * 100 + seconds) + Double(tenths) / 10.0
            if abs(studentReading - digitsAsDecimal) <= 1.0 {
                return mistakes[1]
            } else if abs(studentReading - minutesAsSeconds) <= question.tolerance {
                return mistakes[0]
            } else {
                return mistakes[0]
            }

        case let .thermometer(bulbTempC, _, _):
            let floorReading = bulbTempC.rounded(.down)
            return abs(studentReading - floorReading) <= question.tolerance ? mistakes[1] : mistakes[0]

        case let .measuringCylinder(_, liquidLevelCm3, minorDivisionCm3):
            // Detect reading the top of the meniscus instead of the base
            let topOfMeniscus = round2(liquidLevelCm3 + minorDivisionCm3 * 0.4)
            return abs(studentReading - topOfMeniscus) <= question.tolerance ? mistakes[1] : mistakes[0]

        case let .burette(readingCm3):
            // Detect reading upward from bottom instead of downward from top
            let invertedReading = round2(50.0 - readingCm3)
            return abs(studentReading - invertedReading) <= 0.5 ? mistakes[1] : mistakes[0]
        }
    }

    // MARK: - Mistake catalogues

    private func voltmeterMistakes(fsd: Double) -> [CommonMistake] {
        [
            CommonMistake(
                title: "Parallax error",
                explanation: "Read with your eye perpendicular to the pointer and the scale.",
                examinerPenalty: "Reading accuracy mark may be lost."
            ),
            CommonMistake(
                title: "Wrong scale selected",
                explanation: "A \(Int(fsd)) V meter has a specific scale. Using the wrong scale gives a reading \(fsd == 3.0 ? "5/3" : "3/5")\u{00D7} the true value.",
                examinerPenalty: "Order-of-magnitude errors lose all reading marks."
            )
        ]
    }

    private func newtonMeterMistakes() -> [CommonMistake] {
        [
            CommonMistake(
                title: "Not zeroed before use",
                explanation: "Check the pointer is at zero before applying any force. Adjust the zero-set screw if provided.",
                examinerPenalty: "Systematic offset in all readings."
            ),
            CommonMistake(
                title: "Held horizontally",
                explanation: "Newton-meters are calibrated for vertical use. Horizontal use causes friction with the spring guide, giving a lower reading.",
                examinerPenalty: "Reading error of up to 5% for horizontal use."
            )
        ]
    }

    private func measuringCylinderMistakes() -> [CommonMistake] {
        [
            CommonMistake(
                title: "Reading top of meniscus",
                explanation: "Always read from the bottom (lowest point) of the curved meniscus surface for water.",
                examinerPenalty: "Volume reading is consistently too high."
            ),
            CommonMistake(
                title: "Eye not level with meniscus",
                explanation: "Position your eye at the same height as the meniscus to avoid parallax.",
                examinerPenalty: "Reading is too high or too low depending on viewing angle."
            )
        ]
    }

    private func buretteMistakes() -> [CommonMistake] {
        [
            CommonMistake(
                title: "Scale read upward from bottom",
                explanation: "The burette zero is at the TOP. A reading near the bottom of the liquid column is a large number (e.g. 42.00 cm\u{00B3}), not a small one.",
                examinerPenalty: "Answer is 50 minus the correct value, losing all marks."
            ),
            CommonMistake(
                title: "Reading to wrong precision",
                explanation: "Burettes must be read to 0.05 cm\u{00B3} (the nearest half-division). Reporting to 0.1 or 1 cm\u{00B3} loses the precision mark.",
                examinerPenalty: "Precision mark is lost."
            )
        ]
    }

    private func stopwatchMistakes() -> [CommonMistake] {
        [
            CommonMistake(
                title: "Time not converted to seconds",
                explanation: "Convert mm:ss.t to total seconds: multiply minutes by 60 then add seconds and tenths.",
                examinerPenalty: "Answer mark lost for wrong unit or format."
            ),
            CommonMistake(
                title: "Digits misread as seconds",
                explanation: "The digits mm:ss.t do not represent a decimal number. 1:23.4 is 83.4 s, not 123.4 s.",
                examinerPenalty: "Completely wrong value scores zero."
            )
        ]
    }

    private func thermometerMistakes() -> [CommonMistake] {
        [
            CommonMistake(
                title: "Parallax error",
                explanation: "Read with your eye level with the meniscus of the liquid column, perpendicular to the scale.",
                examinerPenalty: "Reading accuracy mark may be lost."
            ),
            CommonMistake(
                title: "Rounding to the nearest whole degree",
                explanation: "Interpolate between minor division marks to the nearest 0.5 \u{00B0}C or 0.1 \u{00B0}C depending on instrument.",
                examinerPenalty: "Precision mark is lost."
            )
        ]
    }

    private func vernierMistakes() -> [CommonMistake] {
        [
            CommonMistake(
                title: "Wrong vernier coincidence",
                explanation: "Find the vernier line that aligns exactly with a main-scale mm mark, then add n x 0.01 cm.",
                examinerPenalty: "One reading mark is often lost."
            ),
            CommonMistake(
                title: "Zero error ignored",
                explanation: "If the caliper does not read zero when closed, subtract positive zero error from the observed reading.",
                examinerPenalty: "Systematic error is penalized in marking schemes."
            )
        ]
    }

    private func micrometerMistakes() -> [CommonMistake] {
        [
            CommonMistake(
                title: "Thimble scale misread",
                explanation: "Add sleeve reading, optional 0.5 mm, and thimble hundredths in 0.01 mm steps.",
                examinerPenalty: "Precision mark is lost."
            ),
            CommonMistake(
                title: "Zero error ignored",
                explanation: "Check closure reading and correct the final value before writing the answer.",
                examinerPenalty: "Final reading may be consistently shifted."
            )
        ]
    }

    private func ammeterMistakes() -> [CommonMistake] {
        [
            CommonMistake(
                title: "Parallax error",
                explanation: "Read with your eye perpendicular to the scale pointer.",
                examinerPenalty: "Reading accuracy mark may be lost."
            ),
            CommonMistake(
                title: "Wrong scale range",
                explanation: "Confirm whether the meter is on the 0-1 A or 0-5 A range before reading.",
                examinerPenalty: "Order-of-magnitude errors lose multiple marks."
            )
        ]
    }

    private func round2(_ value: Double) -> Double { (value * 100.0).rounded() / 100.0 }
    private func format(_ value: Double) -> String { String(format: "%.2f", value) }
}
