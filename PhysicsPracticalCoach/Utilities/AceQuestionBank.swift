//
//  AceQuestionBank.swift
//  PhysicsPracticalCoach
//
//  Port of `domain.ace.AceQuestionBank.kt`. Every question, model answer,
//  common-mistake note, and examiner tip is preserved verbatim from the
//  Android content bank — this is exam content the student is studying, so
//  it must not drift between platforms.
//

import Foundation

private let sg: Set<Curriculum> = [.singapore]
private let ig: Set<Curriculum> = [.igcse]
private let wn: Set<Curriculum> = [.waec, .neco]
private let allBoards: Set<Curriculum> = []

enum AceQuestionBank {

    static let all: [AceQuestion] = [

        // MARK: - Pendulum (universal)

        AceQuestion(
            id: "pend_ace_01", topic: .pendulum, skillArea: .ace, difficulty: .standard,
            marks: 1, curricula: allBoards,
            questionText: "A student measures the period of a pendulum by timing one complete oscillation. Suggest one improvement to the method to obtain a more accurate value of the period.",
            modelAnswer: "\u{2022} Time 20 (or more) complete oscillations and divide by 20.\n\u{2022} This reduces the percentage error in the time measurement since the stopwatch reaction-time error is spread over many oscillations.",
            commonMistakes: "\u{2717} 'Use a more accurate stopwatch' \u{2014} reaction time is the dominant error, not stopwatch precision.\n\u{2717} 'Time it more carefully' \u{2014} too vague, scores zero.",
            examinerTip: "Always state both WHAT to do (time N oscillations) and WHY (reduces % error / reaction time divided by N)."
        ),
        AceQuestion(
            id: "pend_ace_02", topic: .pendulum, skillArea: .ace, difficulty: .standard,
            marks: 1, curricula: allBoards,
            questionText: "State one precaution to ensure the pendulum oscillates in a vertical plane only.",
            modelAnswer: "\u{2022} Displace the bob by a small angle only (less than 10\u{00B0}) before releasing.\n\u{2022} Release from rest without pushing.\n\u{2022} Ensure the string is fixed at a single point.",
            commonMistakes: "\u{2717} 'Use a heavier bob' \u{2014} does not prevent elliptical swinging.",
            examinerTip: "The answer must address WHY the pendulum swings in an ellipse and what prevents it."
        ),
        AceQuestion(
            id: "pend_plan_01", topic: .pendulum, skillArea: .planning, difficulty: .standard,
            marks: 2, curricula: allBoards,
            questionText: "A student investigates how the period T of a pendulum depends on its length L.\n(a) State the independent variable.\n(b) State TWO variables that must be controlled.",
            modelAnswer: "(a) Length L.\n(b) Any two: mass/weight of bob; amplitude (< 10\u{00B0}); same location (same g); diameter/material of bob.",
            commonMistakes: "\u{2717} Stating 'time' as controlled variable.\n\u{2717} Forgetting amplitude \u{2014} very commonly missed.",
            examinerTip: "Amplitude must be kept small so simple harmonic motion applies \u{2014} examiners look for this."
        ),
        AceQuestion(
            id: "pend_pdo_01", topic: .pendulum, skillArea: .pdo, difficulty: .standard,
            marks: 2, curricula: allBoards,
            questionText: "A student plots T\u{00B2} vs L and gets a straight line through the origin with gradient m.\n(a) What does gradient m represent?\n(b) How would the student find g?",
            modelAnswer: "(a) m = 4\u{03C0}\u{00B2}/g\n(b) g = 4\u{03C0}\u{00B2}/m",
            commonMistakes: "\u{2717} Saying gradient = g.\n\u{2717} Writing g = 4\u{03C0}\u{00B2}m instead of g = 4\u{03C0}\u{00B2}/m.",
            examinerTip: "Derive: T\u{00B2} = (4\u{03C0}\u{00B2}/g) \u{00D7} L \u{2192} y = mx \u{2192} m = 4\u{03C0}\u{00B2}/g \u{2192} g = 4\u{03C0}\u{00B2}/m."
        ),

        // MARK: - Spring (universal)

        AceQuestion(
            id: "spring_ace_01", topic: .spring, skillArea: .ace, difficulty: .basic,
            marks: 1, curricula: allBoards,
            questionText: "A student plots F vs x for a spring and finds one point lies well off the line. What should the student do with this anomalous point when drawing the best-fit line?",
            modelAnswer: "\u{2022} Circle (identify) the anomalous point.\n\u{2022} Exclude it when drawing the best-fit line \u{2014} do NOT include it.",
            commonMistakes: "\u{2717} Forcing the line through the anomalous point.\n\u{2717} Joining all points dot-to-dot.",
            examinerTip: "Anomalous points must be circled AND excluded. Examiners check both steps."
        ),
        AceQuestion(
            id: "spring_ace_02", topic: .spring, skillArea: .ace, difficulty: .standard,
            marks: 2, curricula: allBoards,
            questionText: "An F-x graph has a straight section then a curve where the gradient decreases.\n(a) What does the straight section show?\n(b) What does the curve at larger extensions show?",
            modelAnswer: "(a) Spring obeys Hooke's Law \u{2014} F \u{221D} x. Spring constant k = gradient.\n(b) Spring has exceeded its elastic limit \u{2014} extension increases faster than force; spring is permanently deformed.",
            commonMistakes: "\u{2717} (a) 'The spring is elastic' \u{2014} misses proportionality.\n\u{2717} (b) 'The spring breaks' \u{2014} elastic limit \u{2260} breaking point.",
            examinerTip: "Two distinct concepts: Hooke's Law region vs elastic limit. Know both."
        ),
        AceQuestion(
            id: "spring_plan_01", topic: .spring, skillArea: .planning, difficulty: .challenging,
            marks: 3, curricula: allBoards,
            questionText: "Plan an experiment to determine the spring constant k using slotted masses, a metre rule, and a clamp stand. Include measurements, how to find k, and one precaution.",
            modelAnswer: "Measurements: natural length L\u{2080}; new length L for each mass m; extension x = L \u{2212} L\u{2080}; at least 6 values.\nFinding k: plot F = mg vs x; k = gradient of best-fit line.\nPrecaution (any one): wait for spring to stop oscillating; do not exceed elastic limit; read rule at eye level.",
            commonMistakes: "\u{2717} Not converting mass to force (F = mg).\n\u{2717} Fewer than 5\u{2013}6 data points.\n\u{2717} Omitting the precaution.",
            examinerTip: "Planning marks: procedure clarity, correct use of data, safety/accuracy precaution."
        ),

        // MARK: - DC circuits (universal)

        AceQuestion(
            id: "circuit_ace_01", topic: .ohmsLaw, skillArea: .ace, difficulty: .standard,
            marks: 2, curricula: allBoards,
            questionText: "A student connects an ammeter between the voltmeter and the component.\n(a) What systematic error does this introduce?\n(b) How could the circuit be reconnected to reduce this error?",
            modelAnswer: "(a) Voltmeter reads voltage across ammeter + component \u{2192} calculated R is too high.\n(b) Connect ammeter outside (between battery and the voltmeter-component parallel combination).",
            commonMistakes: "\u{2717} 'The ammeter reading is wrong' \u{2014} current reading is fine; voltage reading is affected.",
            examinerTip: "For LOW resistance: ammeter outside is better. For HIGH resistance: ammeter inside is better."
        ),
        AceQuestion(
            id: "circuit_plan_01", topic: .ohmsLaw, skillArea: .planning, difficulty: .standard,
            marks: 3, curricula: allBoards,
            questionText: "Describe an experiment to verify Ohm's Law for a metal wire at constant temperature. State the circuit, measurements, and how results confirm Ohm's Law.",
            modelAnswer: "Circuit: wire in series with ammeter and rheostat; voltmeter in parallel across wire; switch.\nMeasurements: vary rheostat for \u{2265}6 settings; record V and I each time.\nConfirming: plot V vs I \u{2014} straight line through origin confirms V \u{221D} I (Ohm's Law).",
            commonMistakes: "\u{2717} Forgetting the rheostat \u{2014} only one V-I pair possible.\n\u{2717} 'Linear graph' without adding 'through the origin'.",
            examinerTip: "'Through the origin' is essential \u{2014} proportionality requires both linearity and zero intercept."
        ),

        // MARK: - Potentiometer (Singapore only)

        AceQuestion(
            id: "poten_ace_01", topic: .potentiometer, skillArea: .ace, difficulty: .standard,
            marks: 2, curricula: sg,
            questionText: "A student presses the jockey firmly onto the resistance wire. Explain why this is bad practice and what to do instead.",
            modelAnswer: "\u{2022} Firm pressing wears the wire, changing its resistance per unit length.\n\u{2022} Student should tap lightly and briefly \u{2014} do not hold down.",
            commonMistakes: "\u{2717} 'It gives a wrong reading' \u{2014} true but not a physical explanation.",
            examinerTip: "Potentiometer questions almost always include a jockey-technique mark. Tap, don't hold."
        ),
        AceQuestion(
            id: "poten_ace_02", topic: .potentiometer, skillArea: .ace, difficulty: .standard,
            marks: 2, curricula: sg,
            questionText: "A V-vs-l graph does not pass through the origin.\n(a) What does this suggest?\n(b) State one possible cause.",
            modelAnswer: "(a) Voltage offset \u{2014} V \u{2260} 0 when l = 0, suggesting contact resistance at the wire ends.\n(b) Any one: crocodile-clip contact resistance; non-uniform wire; fluctuating EMF.",
            commonMistakes: "\u{2717} 'The graph is wrong' \u{2014} not a physical explanation.",
            examinerTip: "Y-intercept in a V-l graph \u{2192} additive contact resistance at the wire ends."
        ),

        // MARK: - Resistance wire (universal)

        AceQuestion(
            id: "resis_ace_01", topic: .resistanceWire, skillArea: .ace, difficulty: .standard,
            marks: 2, curricula: allBoards,
            questionText: "A student plots R vs l for a wire. Describe how to find resistivity \u{03C1} from this graph, given cross-sectional area A.",
            modelAnswer: "\u{2022} Gradient of R-l graph = \u{03C1}/A (from R = \u{03C1}l/A).\n\u{2022} Therefore \u{03C1} = gradient \u{00D7} A.\n\u{2022} Use a large triangle on the best-fit line to measure gradient.",
            commonMistakes: "\u{2717} Using a single point instead of the gradient.\n\u{2717} Using \u{03C1} = R/l (forgetting to divide by A).",
            examinerTip: "R = \u{03C1}l/A \u{2192} gradient = \u{03C1}/A \u{2192} \u{03C1} = gradient \u{00D7} A."
        ),

        // MARK: - Refraction (universal)

        AceQuestion(
            id: "refrac_ace_01", topic: .refraction, skillArea: .mmo, difficulty: .standard,
            marks: 2, curricula: allBoards,
            questionText: "In a glass block refraction experiment using optical pins:\n(a) Why must at least two pins be used on each side?\n(b) What is the main source of error?",
            modelAnswer: "(a) Two pins define a straight line \u{2014} one pin cannot determine ray direction.\n(b) Parallax error \u{2014} eye not at same height as pin image.",
            commonMistakes: "\u{2717} (a) 'To make it more accurate' \u{2014} too vague.\n\u{2717} (b) 'The glass distorts the image' \u{2014} refraction is the phenomenon, not an error.",
            examinerTip: "Parallax error fix: close one eye, move head until pins appear aligned."
        ),
        AceQuestion(
            id: "refrac_ace_02", topic: .refraction, skillArea: .pdo, difficulty: .standard,
            marks: 2, curricula: allBoards,
            questionText: "A student plots sin i (y) vs sin r (x) and gets a straight line through the origin.\n(a) What does the gradient represent?\n(b) The gradient is 1.48. What is n?",
            modelAnswer: "(a) Gradient = refractive index n (sin i = n \u{00D7} sin r).\n(b) n = 1.48",
            commonMistakes: "\u{2717} Saying gradient = 1/n.\n\u{2717} Taking n = 1/1.48.",
            examinerTip: "Check axis orientation. sin i on y, sin r on x \u{2192} gradient = n."
        ),

        // MARK: - Moments (universal)

        AceQuestion(
            id: "moment_ace_01", topic: .moments, skillArea: .ace, difficulty: .standard,
            marks: 2, curricula: allBoards,
            questionText: "A beam does not balance even with no weights added. What does this show and how should the student account for it?",
            modelAnswer: "\u{2022} Beam is not uniform \u{2014} centre of gravity not at the pivot.\n\u{2022} Find natural balance point first, OR include beam's own weight as an additional moment.",
            commonMistakes: "\u{2717} 'The pivot is in the wrong place' \u{2014} observation not explanation.",
            examinerTip: "Non-uniform beams appear frequently. Fix: find true centre of mass."
        ),

        // MARK: - Lens (universal)

        AceQuestion(
            id: "lens_ace_01", topic: .lens, skillArea: .mmo, difficulty: .standard,
            marks: 2, curricula: allBoards,
            questionText: "How can a student tell when the image on the screen is sharply focused?",
            modelAnswer: "\u{2022} Image edges are clearest/sharpest.\n\u{2022} Move screen forward and back \u{2014} image blurs on both sides of the sharp position.\n\u{2022} Image is as small and bright as possible at the sharp position.",
            commonMistakes: "\u{2717} 'When the image is the right size' \u{2014} size is not the focus criterion.\n\u{2717} 'When the image is upright' \u{2014} real images are always inverted.",
            examinerTip: "Focus criterion = sharpness of edge, not size. Bracket method confirms exact position."
        ),
        AceQuestion(
            id: "lens_pdo_01", topic: .lens, skillArea: .pdo, difficulty: .challenging,
            marks: 3, curricula: allBoards,
            questionText: "Rearrange the lens formula to give a straight-line graph, and describe how f is found from it.",
            modelAnswer: "1/v = \u{2212}(1/u) + 1/f\nPlot 1/v (y) vs 1/u (x) \u{2192} gradient = \u{2212}1, y-intercept = 1/f.\nf = 1 / (y-intercept).",
            commonMistakes: "\u{2717} Plotting v vs u \u{2014} gives a curve.\n\u{2717} Forgetting negative gradient.\n\u{2717} Reading f directly from intercept without taking reciprocal.",
            examinerTip: "Rearrange \u{2192} identify axes \u{2192} link intercept to f via reciprocal."
        ),

        // MARK: - General measurement (universal)

        AceQuestion(
            id: "meas_mmo_01", topic: .generalMeasurement, skillArea: .mmo, difficulty: .basic,
            marks: 1, curricula: allBoards,
            questionText: "A micrometer reads 3.24 mm. The zero error is +0.04 mm. What is the correct diameter?",
            modelAnswer: "Correct = 3.24 \u{2212} 0.04 = 3.20 mm.\n(Positive zero error \u{2192} instrument over-reads \u{2192} subtract.)",
            commonMistakes: "\u{2717} Adding: 3.24 + 0.04 = 3.28 mm.",
            examinerTip: "Positive zero error \u{2192} subtract. Negative zero error \u{2192} add."
        ),
        AceQuestion(
            id: "meas_ace_01", topic: .generalMeasurement, skillArea: .ace, difficulty: .standard,
            marks: 2, curricula: allBoards,
            questionText: "Explain the difference between a systematic error and a random error, giving one example of each.",
            modelAnswer: "Systematic: same direction every reading (e.g. zero error on micrometer).\nRandom: varies unpredictably (e.g. reaction time on stopwatch).\nKey: repeating reduces random errors but NOT systematic errors.",
            commonMistakes: "\u{2717} 'Systematic = big, random = small' \u{2014} completely wrong.",
            examinerTip: "Reduction by repetition = clearest distinguishing feature."
        ),

        // MARK: - Graph skills (universal)

        AceQuestion(
            id: "graph_pdo_01", topic: .generalGraph, skillArea: .pdo, difficulty: .standard,
            marks: 2, curricula: allBoards,
            questionText: "Describe the correct method for drawing a best-fit line and what to do with an anomalous point.",
            modelAnswer: "\u{2022} Equal numbers of points above and below the line.\n\u{2022} Circle anomalous point; exclude it from the line.\n\u{2022} Line need not pass through any data point or the origin.",
            commonMistakes: "\u{2717} Joining points dot-to-dot.\n\u{2717} Forcing through origin without justification.",
            examinerTip: "Best-fit line need not pass through ANY data point."
        ),
        AceQuestion(
            id: "graph_pdo_02", topic: .generalGraph, skillArea: .pdo, difficulty: .standard,
            marks: 2, curricula: allBoards,
            questionText: "Describe how to measure the gradient of a straight-line graph accurately. Why use a large triangle?",
            modelAnswer: "\u{2022} Large right-angled triangle with hypotenuse on best-fit line; spanning \u{2265} half the line.\n\u{2022} Read \u{0394}y and \u{0394}x from the scale.\n\u{2022} Gradient = \u{0394}y/\u{0394}x with units.\n\u{2022} Large triangle: smaller % uncertainty.",
            commonMistakes: "\u{2717} Using two data points instead of the best-fit line.\n\u{2717} Not including units.",
            examinerTip: "Triangle ON the best-fit line. Show and label \u{0394}y, \u{0394}x on the graph."
        ),

        // MARK: - General planning (universal)

        AceQuestion(
            id: "plan_01", topic: .generalPlanning, skillArea: .planning, difficulty: .standard,
            marks: 2, curricula: allBoards,
            questionText: "State the difference between independent, dependent, and controlled variables. Give examples for a spring extension experiment.",
            modelAnswer: "Independent: what you change (load/force).\nDependent: what you measure (extension).\nControlled: kept constant (same spring, temperature, starting position).",
            commonMistakes: "\u{2717} Confusing independent and dependent.\n\u{2717} Stating time as a controlled variable.",
            examinerTip: "Independent = what YOU set. Dependent = what the spring does."
        ),
        AceQuestion(
            id: "plan_02", topic: .generalPlanning, skillArea: .planning, difficulty: .basic,
            marks: 1, curricula: allBoards,
            questionText: "State ONE specific safety precaution for an experiment involving heating water to boiling point.",
            modelAnswer: "Any one: use heating mat; do not lean over boiling beaker; use tongs for hot glassware; do not fill beaker more than two-thirds full.",
            commonMistakes: "\u{2717} 'Be careful' \u{2014} too vague.\n\u{2717} 'Wear goggles' \u{2014} not specific to boiling water hazard.",
            examinerTip: "Safety precautions must be SPECIFIC to the hazard."
        ),

        // MARK: - Heat (universal)

        AceQuestion(
            id: "heat_ace_01", topic: .heat, skillArea: .ace, difficulty: .standard,
            marks: 2, curricula: allBoards,
            questionText: "A student's calculated specific heat capacity is higher than the accepted value. Suggest TWO reasons.",
            modelAnswer: "Any two: heat lost to surroundings; thermometer lags (under-records \u{0394}T); heat absorbed by heater; poor thermal contact.",
            commonMistakes: "\u{2717} 'The student made a mistake' \u{2014} too vague.",
            examinerTip: "Heat loss to surroundings ALWAYS makes calculated c larger than true c."
        ),

        // MARK: - Density (universal)

        AceQuestion(
            id: "density_plan_01", topic: .density, skillArea: .planning, difficulty: .standard,
            marks: 3, curricula: allBoards,
            questionText: "Describe how to determine the density of an irregularly shaped stone that sinks in water.",
            modelAnswer: "Apparatus: measuring cylinder, balance, water, string.\nMeasurements: mass m; V\u{2081} (water); V\u{2082} (water + stone); volume = V\u{2082} \u{2212} V\u{2081}.\nCalculation: \u{03C1} = m / (V\u{2082} \u{2212} V\u{2081}); consistent units.",
            commonMistakes: "\u{2717} Not stating displacement method.\n\u{2717} Mixing g with m\u{00B3}.",
            examinerTip: "Key marks: volume = V\u{2082} \u{2212} V\u{2081}, \u{03C1} = m/V with consistent units."
        ),

        // MARK: - IGCSE-specific (Cambridge 0625)

        AceQuestion(
            id: "igcse_ace_01", topic: .generalMeasurement, skillArea: .ace, difficulty: .standard,
            marks: 2, curricula: ig,
            questionText: "A student records ammeter readings: 0.42 A, 0.41 A, 0.43 A, 0.41 A, 0.68 A.\n(a) Identify the anomalous reading and suggest a cause.\n(b) Calculate the best estimate of the current.",
            modelAnswer: "(a) 0.68 A is anomalous \u{2014} far from others. Possible cause: loose connection or misread scale.\n(b) Average of remaining four: (0.42 + 0.41 + 0.43 + 0.41) / 4 = 0.42 A",
            commonMistakes: "\u{2717} Including 0.68 A in the average.\n\u{2717} Not suggesting a cause for the anomaly.",
            examinerTip: "Cambridge Paper 5 asks to identify AND suggest a cause. Both parts needed for full marks."
        ),
        AceQuestion(
            id: "igcse_pdo_01", topic: .generalGraph, skillArea: .pdo, difficulty: .standard,
            marks: 3, curricula: ig,
            questionText: "A student plots a graph with y-axis starting at 4.0 instead of 0.\n(a) Is this acceptable?\n(b) What must the student NOT conclude from this graph?",
            modelAnswer: "(a) Acceptable \u{2014} it makes better use of graph paper and gives a larger, clearer graph.\n(b) Must NOT: claim y-intercept = 0; state y \u{221D} x (direct proportionality); say relationship 'starts at zero' \u{2014} the origin is not shown.",
            commonMistakes: "\u{2717} Assuming all graphs must start at (0,0).\n\u{2717} Writing 'y \u{221D} x' when line does not pass through the origin.",
            examinerTip: "Cambridge specifically penalises unjustified proportionality claims. If origin is not on the graph, you cannot confirm direct proportionality."
        ),
        AceQuestion(
            id: "igcse_plan_01", topic: .generalPlanning, skillArea: .planning, difficulty: .challenging,
            marks: 4, curricula: ig,
            questionText: "A student investigates how the extension of a rubber band depends on force. Unlike a metal spring, rubber does not obey Hooke's Law.\nDescribe the experiment, state what graph to plot, and explain what the graph would show.",
            modelAnswer: "Method: hang rubber band; add masses in steps; measure length; calculate extension = length \u{2212} natural length; repeat with decreasing load to check hysteresis.\nGraph: extension (y) vs force (x).\nWhat it shows: curve (not straight line); loading and unloading curves may differ (hysteresis) \u{2014} energy is lost.",
            commonMistakes: "\u{2717} Expecting a straight-line F-x graph for rubber.\n\u{2717} Not mentioning hysteresis.",
            examinerTip: "Cambridge distinguishes Hooke's Law (spring) from non-Hookean (rubber). Hysteresis earns a bonus mark."
        ),
        AceQuestion(
            id: "igcse_ace_02", topic: .ohmsLaw, skillArea: .ace, difficulty: .standard,
            marks: 2, curricula: ig,
            questionText: "As a room gets brighter, the ammeter reading in an LDR circuit increases while voltmeter stays constant.\n(a) Explain why the current increases.\n(b) What does this tell you about the LDR's resistance?",
            modelAnswer: "(a) Brighter light \u{2192} LDR resistance decreases \u{2192} I = V/R increases at constant V.\n(b) Resistance of LDR decreases as light intensity increases.",
            commonMistakes: "\u{2717} 'More light gives more energy so more current' \u{2014} lacks resistance mechanism.",
            examinerTip: "LDR chain: more light \u{2192} lower resistance \u{2192} higher current (constant V). All three links needed."
        ),
        AceQuestion(
            id: "igcse_ace_03", topic: .generalMeasurement, skillArea: .ace, difficulty: .standard,
            marks: 2, curricula: ig,
            questionText: "In Cambridge Paper 6, a student is asked to evaluate a proposed experiment. The plan states: 'Measure the temperature of water with a thermometer while stirring.' Identify ONE limitation of this method and suggest an improvement.",
            modelAnswer: "Limitation: the thermometer may not be in thermal equilibrium with the water when read \u{2014} reading too early gives an incorrect temperature.\nImprovement: stir thoroughly then wait for the thermometer reading to stabilise before recording; or use a digital thermometer with faster response.",
            commonMistakes: "\u{2717} 'The thermometer might break' \u{2014} not a measurement limitation.\n\u{2717} 'Use a better thermometer' \u{2014} too vague without explaining what 'better' means.",
            examinerTip: "Cambridge Paper 6 evaluation questions require: (1) a specific physical limitation, (2) a specific improvement addressing that limitation. Vague answers score zero."
        ),

        // MARK: - WAEC / NECO-specific

        AceQuestion(
            id: "waec_pend_01", topic: .pendulum, skillArea: .pdo, difficulty: .standard,
            marks: 3, curricula: wn,
            questionText: "In a WAEC pendulum experiment, T = 1.60 s for a given length.\n(a) Calculate T\u{00B2}.\n(b) State what the slope of the T\u{00B2}-L graph gives.\n(c) State TWO precautions.",
            modelAnswer: "(a) T\u{00B2} = 1.60\u{00B2} = 2.56 s\u{00B2}\n(b) Slope = 4\u{03C0}\u{00B2}/g \u{2192} value of g = 4\u{03C0}\u{00B2}/slope\n(c) Any two: displace bob by small angle (< 10\u{00B0}); time 20 oscillations and divide; do not let string touch stand; repeat timing and average.",
            commonMistakes: "\u{2717} Squaring T incorrectly.\n\u{2717} Stating slope = g directly.\n\u{2717} Precaution too vague.",
            examinerTip: "WAEC always asks for precautions \u{2014} must be specific, e.g. 'displace bob by small angle to ensure SHM'."
        ),
        AceQuestion(
            id: "waec_spring_01", topic: .spring, skillArea: .pdo, difficulty: .standard,
            marks: 4, curricula: wn,
            questionText: "A student plots extension e (y-axis) vs load W (x-axis) for a spring.\n(a) What is the relationship shown?\n(b) How is spring constant k obtained?\n(c) State the unit of k.\n(d) State ONE precaution.",
            modelAnswer: "(a) e is directly proportional to W (Hooke's Law).\n(b) k = 1/gradient (since e = W/k \u{2192} gradient = 1/k).\n(c) N/m or N/cm.\n(d) Any one: do not exceed elastic limit; wait for oscillation to stop; read extension from equilibrium position.",
            commonMistakes: "\u{2717} Saying k = gradient when e is on y-axis (k = 1/gradient in that case).\n\u{2717} Wrong units for k.",
            examinerTip: "WAEC spring questions have an axes trap. Check which variable is on which axis before stating how k relates to gradient."
        ),
        AceQuestion(
            id: "waec_ohm_01", topic: .ohmsLaw, skillArea: .ace, difficulty: .standard,
            marks: 4, curricula: wn,
            questionText: "A student plots V (y) vs I (x) for a cell with EMF E and internal resistance r. The graph is a straight line with negative gradient.\n(a) Write the equation of the line.\n(b) What does the y-intercept represent?\n(c) What does the magnitude of the gradient represent?\n(d) If y-intercept = 1.5 V and gradient = \u{2212}2.0 \u{03A9}, find E and r.",
            modelAnswer: "(a) V = E \u{2212} Ir\n(b) y-intercept = E (EMF of the cell)\n(c) Magnitude of gradient = r (internal resistance)\n(d) E = 1.5 V; r = 2.0 \u{03A9}",
            commonMistakes: "\u{2717} Confusing EMF with terminal voltage.\n\u{2717} Taking gradient as positive.",
            examinerTip: "V = E \u{2212} Ir is y = c \u{2212} mx: y-intercept = E, gradient magnitude = r."
        ),
        AceQuestion(
            id: "waec_refrac_01", topic: .refraction, skillArea: .planning, difficulty: .standard,
            marks: 4, curricula: wn,
            questionText: "Describe an experiment to determine the refractive index n of a glass prism using optical pins. State measurements and how n is calculated.",
            modelAnswer: "Setup: place prism on paper; use two pins on incident side; align two more pins with emergent ray; draw incident/emergent rays; draw normals at entry/exit; measure angles i and r.\nFor multiple readings: vary i; measure corresponding r.\nCalculation: n = sin i / sin r for each pair; OR plot sin i vs sin r \u{2192} gradient = n.\nPrecaution: sharp vertical pins; pins far apart for accuracy.",
            commonMistakes: "\u{2717} Measuring angle from surface instead of normal.\n\u{2717} Using only one pair of i and r.\n\u{2717} Not specifying angles from the normal.",
            examinerTip: "WAEC expects a graph of sin i vs sin r, not just one calculation. The gradient gives n."
        ),
        AceQuestion(
            id: "waec_plan_01", topic: .generalPlanning, skillArea: .planning, difficulty: .challenging,
            marks: 4, curricula: wn,
            questionText: "A student investigates T vs L for a pendulum.\n(a) How is T measured accurately?\n(b) What graph gives a straight line?\n(c) How is g found from the graph?\n(d) State TWO precautions.",
            modelAnswer: "(a) Time 20 complete oscillations; T = total/20; repeat and average.\n(b) Plot T\u{00B2} (y) vs L (x) \u{2014} straight line through origin.\n(c) Gradient = 4\u{03C0}\u{00B2}/g \u{2192} g = 4\u{03C0}\u{00B2}/gradient.\n(d) Any two: small angle (< 10\u{00B0}); same bob; count carefully; avoid draughts; fix string firmly.",
            commonMistakes: "\u{2717} Plotting T vs L (curve, not straight line).\n\u{2717} Not dividing by 20.\n\u{2717} Vague precautions.",
            examinerTip: "WAEC marks: (1) timing method, (2) graph axes, (3) use of gradient, (4) specific precautions. Cover each explicitly."
        ),

        // MARK: - NECO-specific

        AceQuestion(
            id: "neco_mmo_01", topic: .generalMeasurement, skillArea: .mmo, difficulty: .standard,
            marks: 2, curricula: [.neco],
            questionText: "NECO requires students to state the least count of each instrument.\n(a) State the least count of a metre rule graduated in mm.\n(b) State the least count of a vernier caliper with 10 vernier divisions.",
            modelAnswer: "(a) Least count = 1 mm = 0.1 cm\n(b) Least count = 1 mm \u{00F7} 10 = 0.1 mm = 0.01 cm",
            commonMistakes: "\u{2717} Stating 0.5 mm for metre rule (that is estimated precision, not least count).\n\u{2717} Confusing least count with zero error.",
            examinerTip: "NECO awards 1 mark specifically for stating least count of each instrument used. Always include it."
        ),
        AceQuestion(
            id: "neco_ace_01", topic: .ohmsLaw, skillArea: .ace, difficulty: .standard,
            marks: 4, curricula: [.neco],
            questionText: "A student recorded V (V): 1.0, 1.5, 2.0, 2.5, 3.0 and I (A): 0.20, 0.30, 0.40, 0.50, 0.62.\n(a) Identify the likely anomalous reading.\n(b) Find resistance R from the V-I graph gradient.\n(c) State one source of error.",
            modelAnswer: "(a) I = 0.62 A at V = 3.0 V is slightly high \u{2014} pattern suggests 0.60 A.\n(b) R = \u{0394}V/\u{0394}I = (3.0\u{2212}1.0)/(0.60\u{2212}0.20) = 2.0/0.40 = 5.0 \u{03A9} (use best-fit line, exclude anomaly).\n(c) Any one: contact resistance; wire heating up; parallax when reading meters.",
            commonMistakes: "\u{2717} Reading R from a single point (V/I) instead of graph gradient.\n\u{2717} Not checking for anomaly before drawing line.",
            examinerTip: "NECO resistance questions: check for anomalies first, graph second, gradient for R \u{2014} not a single V/I ratio."
        ),
        AceQuestion(
            id: "neco_plan_01", topic: .spring, skillArea: .planning, difficulty: .standard,
            marks: 5, curricula: [.neco],
            questionText: "A student uses a helical spring to verify Hooke's Law.\n(a) State the hypothesis.\n(b) Describe the procedure.\n(c) How is Hooke's Law verified from the results?\n(d) State the spring constant in terms of the graph.\n(e) State TWO precautions.",
            modelAnswer: "(a) Extension is directly proportional to applied force, provided elastic limit is not exceeded.\n(b) Clamp spring; measure natural length L\u{2080}; add masses in 50 g steps; record L; e = L \u{2212} L\u{2080}; tabulate F = mg and e for \u{2265}6 loads.\n(c) Plot e vs F \u{2014} straight line through origin \u{2192} Hooke's Law verified.\n(d) k = 1/gradient (e on y, F on x); unit N/m.\n(e) Any two: do not exceed elastic limit; allow spring to settle before reading; read scale at eye level.",
            commonMistakes: "\u{2717} Hypothesis misses the word 'proportional'.\n\u{2717} k = gradient without specifying axis orientation.\n\u{2717} Only 3\u{2013}4 data points.",
            examinerTip: "NECO planning: hypothesis (1), procedure (2), verification (1), spring constant (1), precautions (1 each). Answer each part explicitly."
        ),

        // MARK: - Skillset document questions (exam-technique notes)

        AceQuestion(
            id: "sk_prec_01", topic: .generalMeasurement, skillArea: .mmo, difficulty: .basic,
            marks: 1, curricula: allBoards,
            questionText: "A student records a metre rule reading as '2 cm'. The examiner deducts a mark. Explain why and state the correct recording.",
            modelAnswer: "The metre rule has smallest division 0.1 cm and must be recorded to 1 d.p.\nCorrect: 2.0 cm \u{2014} the trailing zero shows precision.",
            commonMistakes: "\u{2717} '2 cm' \u{2014} omits the trailing zero that shows precision\n\u{2717} '2.00 cm' \u{2014} overclaims precision",
            examinerTip: "For instruments, count DECIMAL PLACES not significant figures. '2.0 cm' is compulsory \u{2014} it proves you read to 0.1 cm."
        ),
        AceQuestion(
            id: "sk_prec_02", topic: .generalMeasurement, skillArea: .mmo, difficulty: .basic,
            marks: 2, curricula: allBoards,
            questionText: "State the precision each instrument must be recorded to, and give one example:\n(a) Ammeter f.s.d. 1 A\n(b) Thermometer (\u{2212}10 to 110\u{00B0}C)\n(c) Measuring cylinder 100 cm\u{00B3}",
            modelAnswer: "(a) 0.01 A (2 d.p.) e.g. 0.44 A or 0.50 A\n(b) 0.5\u{00B0}C (1 d.p.) e.g. 37.0\u{00B0}C or 21.5\u{00B0}C\n(c) 0.5 cm\u{00B3} (1 d.p.) e.g. 65.5 cm\u{00B3} or 80.0 cm\u{00B3}",
            commonMistakes: "\u{2717} Ammeter as '0.4 A' \u{2014} must be 0.40 A\n\u{2717} Thermometer as '37\u{00B0}C' \u{2014} must be 37.0\u{00B0}C\n\u{2717} Cylinder as '65 cm\u{00B3}' \u{2014} must be 65.5 or 65.0 cm\u{00B3}",
            examinerTip: "Scaled readings (ammeter, thermometer) \u{2192} half smallest division. Measurements (ruler) \u{2192} smallest division."
        ),
        AceQuestion(
            id: "sk_sf_01", topic: .generalMeasurement, skillArea: .pdo, difficulty: .standard,
            marks: 2, curricula: allBoards,
            questionText: "A student calculates density using mass = 120.45 g and volume = 45.8 cm\u{00B3}.\n(a) How many significant figures should the answer have?\n(b) Calculate density to the correct s.f.",
            modelAnswer: "(a) 3 significant figures \u{2014} volume (45.8 cm\u{00B3}) has fewest s.f.\n(b) D = 120.45 / 45.8 = 2.629\u{2026} \u{2248} 2.63 g/cm\u{00B3} (3 s.f.)",
            commonMistakes: "\u{2717} D = 2.629 g/cm\u{00B3} \u{2014} more s.f. than least precise measurement\n\u{2717} D = 2.6 g/cm\u{00B3} \u{2014} too few s.f.",
            examinerTip: "Identify measurement with FEWEST s.f. \u{2014} answer matches that. Mass 5 s.f., volume 3 s.f. \u{2192} answer 3 s.f."
        ),
        AceQuestion(
            id: "sk_tab_01", topic: .generalGraph, skillArea: .pdo, difficulty: .standard,
            marks: 2, curricula: allBoards,
            questionText: "A student uses column heading 'time (s)'. The examiner deducts a mark.\n(a) What is wrong?\n(b) Write the correct heading.",
            modelAnswer: "(a) Brackets are not accepted \u{2014} must use solidus (/) notation.\n(b) Correct: t / s",
            commonMistakes: "\u{2717} 'Time (s)' or 't(s)' \u{2014} brackets not accepted\n\u{2717} 'Time in seconds' \u{2014} not standard format",
            examinerTip: "Think of 't / s' as maths: if t = 23.4 s then t/s = 23.4 (a pure number). Only numbers go in data cells."
        ),
        AceQuestion(
            id: "sk_graph_01", topic: .generalGraph, skillArea: .pdo, difficulty: .standard,
            marks: 4, curricula: allBoards,
            questionText: "A common exam-technique checklist breaks graph-plotting marks into four areas. State these four areas.",
            modelAnswer: "1. Best-fit line: thin continuous line, balanced errors on both sides; not dot-to-dot.\n2. Labeled axes: quantity / unit (solidus), matching table headings.\n3. Correct plotting: crosses (\u{00D7}) of reasonable size, plotted accurately.\n4. Right scale: multiples of 2 or 5; data spans 5\u{00D7}7 or 7\u{00D7}5 big squares (\u{2265}2/3 of paper); no intervals of 3 or 7.",
            commonMistakes: "\u{2717} Dot-to-dot instead of best-fit line\n\u{2717} Axes labeled with brackets\n\u{2717} Scale intervals of 3 or 7\n\u{2717} Data points marked as dots not crosses",
            examinerTip: "These 4 criteria are checked independently. Score 3/4 even if the line is slightly off, as long as axes, points, and scale are correct."
        ),
        AceQuestion(
            id: "sk_grad_01", topic: .generalGraph, skillArea: .pdo, difficulty: .standard,
            marks: 4, curricula: allBoards,
            questionText: "Describe the 4 steps to calculate the gradient of a straight-line graph.",
            modelAnswer: "Step 1: Select two points ON the best-fit line, as far apart as possible. Mark with \u{00D7}.\nStep 2: Label both with coordinates (x\u{2081}, y\u{2081}) and (x\u{2082}, y\u{2082}).\nStep 3: Draw a dotted right-angled triangle spanning at least half the line.\nStep 4: gradient = (y\u{2082} \u{2212} y\u{2081})/(x\u{2082} \u{2212} x\u{2081}) with units (y-unit / x-unit).",
            commonMistakes: "\u{2717} Using data-table points instead of points on the line\n\u{2717} Small triangle (< half the line)\n\u{2717} No units on gradient\n\u{2717} No dotted triangle shown on graph",
            examinerTip: "Showing dotted triangle and coordinates is COMPULSORY. Triangle must span \u{2265} half the drawn line. Always include the unit."
        ),
        AceQuestion(
            id: "sk_conc_01", topic: .generalGraph, skillArea: .ace, difficulty: .standard,
            marks: 2, curricula: allBoards,
            questionText: "A student's F-x graph is a straight line through the origin.\n(a) State the conclusion about F and x.\n(b) If the line were straight but did NOT pass through the origin, what would the conclusion be?",
            modelAnswer: "(a) F is directly proportional to x (F \u{221D} x) \u{2014} straight line through origin.\n(b) F varies linearly with x (F = mx + c) but is NOT directly proportional \u{2014} y-intercept \u{2260} 0.",
            commonMistakes: "\u{2717} 'F increases with x' \u{2014} does not state proportionality\n\u{2717} Using 'proportional' when line does not pass through origin",
            examinerTip: "'Directly proportional' requires line through (0,0). 'Varies linearly' covers all straight-line cases. Never use 'proportional' for a non-zero y-intercept."
        ),
        AceQuestion(
            id: "sk_plan_01", topic: .generalPlanning, skillArea: .planning, difficulty: .challenging,
            marks: 6, curricula: allBoards,
            questionText: "Design an experiment to investigate how period T of a simple pendulum depends on length L. Include: (a) variables, (b) how T is measured, (c) 6 values of L, (d) table headings, (e) graph and how to find g, (f) one precaution.",
            modelAnswer: "(a) IV: L/cm; DV: T/s; CV: mass of bob, angle (<10\u{00B0}), same location.\n(b) Time 20 oscillations; T = t\u{2082}\u{2080}/20; repeat and average.\n(c) L = 10.0, 20.0, 30.0, 40.0, 50.0, 60.0 cm.\n(d) L/cm | t\u{2082}\u{2080}(1)/s | t\u{2082}\u{2080}(2)/s | t\u{2090}\u{1D65}\u{2091}/s | T/s | T\u{00B2}/s\u{00B2}\n(e) Plot T\u{00B2}/s\u{00B2} vs L/cm \u{2192} straight line through origin confirms T\u{00B2}\u{221D}L; gradient = 4\u{03C0}\u{00B2}/g \u{2192} g = 4\u{03C0}\u{00B2}/gradient.\n(f) Ensured angle < 10\u{00B0} to maintain SHM and avoid affecting period.",
            commonMistakes: "\u{2717} Not specifying 6 exact L values\n\u{2717} Bracket notation in headings instead of solidus\n\u{2717} Plotting T vs L (gives curve, not line)\n\u{2717} Stating g = gradient instead of g = 4\u{03C0}\u{00B2}/gradient\n\u{2717} Precaution without reason",
            examinerTip: "Planning: variables (1), measurement (1), 6 values (1), table (1), graph+gradient (2), precaution (1). Address each mark point explicitly."
        )
    ]

    static func forCurriculum(_ curriculum: Curriculum) -> [AceQuestion] {
        all.filter { $0.curricula.isEmpty || $0.curricula.contains(curriculum) }
    }

    static func forTopic(_ topic: AceTopic, curriculum: Curriculum? = nil) -> [AceQuestion] {
        let base = curriculum.map(forCurriculum) ?? all
        return base.filter { $0.topic == topic }
    }

    static func forSkill(_ skill: AceSkillArea, curriculum: Curriculum? = nil) -> [AceQuestion] {
        let base = curriculum.map(forCurriculum) ?? all
        return base.filter { $0.skillArea == skill }
    }
}
