//
//  GraphCoachDomain.swift
//  PhysicsPracticalCoach
//
//  Port of `domain.graph.GraphCoachDomain.kt`. Two responsibilities, kept
//  separate exactly as on Android: generating a deterministic dataset for a
//  given graph type + seed, and marking a student's entered gradient against
//  the least-squares gradient of that dataset.
//

import Foundation

struct GraphDatasetGenerator {
    func generate(
        type: GraphCoachType,
        seed: Int,
        pointCount: Int = 6,
        curriculum: Curriculum = .general
    ) -> GraphDataset {
        var rng = SeededRandomNumberGenerator(seed: seed)
        let noiseScale = noiseScale(for: curriculum)

        let (start, step, trueGradient, intercept): (Double, Double, Double, Double)
        switch type {
        case .forceExtension:
            (start, step, trueGradient, intercept) = (0.02, 0.02, 8.5 + rng.nextDouble(-0.4, 0.4), 0.0)
        case .currentVoltage:
            (start, step, trueGradient, intercept) = (0.1, 0.1, 4.7 + rng.nextDouble(-0.3, 0.3), 0.0)
        case .distanceTime:
            (start, step, trueGradient, intercept) = (1.0, 1.0, 1.8 + rng.nextDouble(-0.2, 0.2), 0.5)
        case .tSquaredVsLength:
            // T^2 vs L: gradient = 4pi^2/g ~ 4.027 s^2/m.
            (start, step, trueGradient, intercept) = (0.10, 0.10, 4.027 + rng.nextDouble(-0.05, 0.05), 0.0)
        case .sinIVsSinR:
            // sin i vs sin r: gradient = n (refractive index). Typical glass n ~ 1.50.
            (start, step, trueGradient, intercept) = (0.08, 0.08, 1.50 + rng.nextDouble(-0.03, 0.03), 0.0)
        case .potentialGradient:
            // V vs l for a potentiometer wire: gradient = potential gradient K = I x r, typically 1-2.5 V/m.
            (start, step, trueGradient, intercept) = (0.10, 0.10, 1.8 + rng.nextDouble(-0.3, 0.3), 0.0)
        case .reciprocalLensDistances:
            // 1/v vs 1/u for a converging lens: gradient ~ -1 (a check), y-intercept = 1/f.
            (start, step, trueGradient, intercept) = (0.02, 0.01, -1.0, 0.09 + rng.nextDouble(-0.02, 0.02))
        case .resistanceVsLength:
            // R vs l for a resistance wire: gradient = resistivity / cross-sectional area,
            // typically 8-20 ohm/m for a thin nichrome-like test wire.
            (start, step, trueGradient, intercept) = (0.10, 0.15, 12.0 + rng.nextDouble(-3.0, 3.0), 0.0)
        }

        var points: [GraphPoint] = []
        points.reserveCapacity(pointCount)
        for index in 0..<pointCount {
            let x = start + Double(index) * step
            let noise = rng.nextDouble(-0.08, 0.08) * step * noiseScale
            points.append(GraphPoint(x: round3(x), y: round3((trueGradient * x) + intercept + noise)))
        }
        return GraphDataset(type: type, seed: seed, points: points, expectedGradient: trueGradient)
    }

    /// Singapore O-Level and IGCSE practicals expect students to read off neat,
    /// low-scatter data; WAEC/NECO datasets in past papers tend to include more
    /// visible scatter for students to draw a best-fit line through, so we
    /// widen the simulated noise slightly.
    private func noiseScale(for curriculum: Curriculum) -> Double {
        switch curriculum {
        case .singapore, .igcse: return 1.0
        case .waec, .neco: return 1.6
        case .general: return 1.0
        }
    }

    private func round3(_ value: Double) -> Double {
        (value * 1000.0).rounded() / 1000.0
    }
}

struct GraphGradientMarker {
    private let toleranceFraction: Double

    init(toleranceFraction: Double = 0.12) {
        self.toleranceFraction = toleranceFraction
    }

    func mark(
        dataset: GraphDataset,
        studentGradient: Double?,
        curriculum: Curriculum = .general
    ) -> GraphGradientResult {
        let regressionPoints = dataset.points.map { RegressionPoint(x: $0.x, y: $0.y) }
        let regression = LinearRegression.fit(regressionPoints)
        let expected = regression.slope
        let def = dataset.type.definition
        let explanation = "Least-squares gradient = \(format(expected)) \(def.yUnit)/\(def.xUnit). "
            + def.gradientMeaning
            + " Use a large triangle on the best-fit line, not a point-to-point join."

        guard let studentGradient else {
            return GraphGradientResult(
                correct: false,
                score: 0,
                expectedGradient: expected,
                studentGradient: nil,
                feedback: [
                    "Enter your gradient before checking.",
                    "Expected gradient about \(format(expected)) \(def.yUnit)/\(def.xUnit)."
                ],
                explanation: explanation
            )
        }

        let tolerance = max(abs(expected), 0.05) * toleranceFraction * toleranceMultiplier(for: curriculum)
        let correct = abs(studentGradient - expected) <= tolerance
        let feedback: [String]
        if correct {
            feedback = [
                "Gradient within tolerance (+/- \(format(tolerance))).",
                "Expected about \(format(expected)) \(def.yUnit)/\(def.xUnit)."
            ]
        } else {
            feedback = [
                "Gradient outside tolerance. You entered \(format(studentGradient)).",
                "Expected about \(format(expected)) \(def.yUnit)/\(def.xUnit).",
                "Draw the regression line through the scatter trend, then measure rise/run with a large triangle."
            ]
        }
        return GraphGradientResult(
            correct: correct,
            score: correct ? 100 : 45,
            expectedGradient: expected,
            studentGradient: studentGradient,
            feedback: feedback,
            explanation: explanation
        )
    }

    /// Mirrors the wider scatter simulated for WAEC/NECO datasets with a
    /// matching wider tolerance.
    private func toleranceMultiplier(for curriculum: Curriculum) -> Double {
        switch curriculum {
        case .singapore, .igcse: return 1.0
        case .waec, .neco: return 1.4
        case .general: return 1.0
        }
    }

    private func format(_ value: Double) -> String {
        String(format: "%.3f", value)
    }
}

// MARK: - Practice modes

/// Which slice of the 7-step exam workflow a practice session focuses on.
/// `fullExam` walks all 7 steps in order; the others jump straight to the
/// relevant step(s) with earlier steps pre-filled, for focused drilling.
enum GraphCoachPracticeMode: String, CaseIterable, Identifiable {
    case fullExam
    case plotPoints
    case drawBestFit
    case calculateGradient
    case identifyErrors

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fullExam: return "Full Exam Practice"
        case .plotPoints: return "Plot Points"
        case .drawBestFit: return "Draw Best-Fit Line"
        case .calculateGradient: return "Calculate Gradient"
        case .identifyErrors: return "Identify Graph Errors"
        }
    }

    var systemImage: String {
        switch self {
        case .fullExam: return "checklist"
        case .plotPoints: return "hand.tap"
        case .drawBestFit: return "scribble.variable"
        case .calculateGradient: return "triangle"
        case .identifyErrors: return "magnifyingglass"
        }
    }

    /// The ordered wizard steps (1...7) this mode walks through. Steps
    /// before the first one here are treated as already-complete so the
    /// student can drill a single skill without redoing earlier steps.
    var steps: [Int] {
        switch self {
        case .fullExam: return [1, 2, 3, 4, 5, 6, 7]
        case .plotPoints: return [1, 2, 3, 4]
        case .drawBestFit: return [5]
        case .calculateGradient: return [6, 7]
        case .identifyErrors: return []
        }
    }
}

// MARK: - Exam tips

/// One practical-exam tip is shown each time Graph Coach opens, chosen at
/// random so repeat visits surface different advice over time.
enum GraphExamTips {
    static let all: [String] = [
        "Always use more than half the graph paper in both directions.",
        "Never force the best-fit line through every point — aim for balance, roughly equal points above and below.",
        "Include units on both axes, in brackets after the quantity label.",
        "Circle anomalous points only if the exam instructions ask you to.",
        "Choose a scale where each grid square is worth 1, 2 or 5 units — never an awkward multiple like 3 or 7.",
        "Plot points as neat, small crosses (×) so the exact position is unambiguous.",
        "For the gradient, pick two points far apart on the best-fit line itself, not two data points.",
        "Label each axis with the quantity and its unit, e.g. \"Extension / m\".",
        "Give your graph a clear title stating what is plotted against what."
    ]

    static func random() -> String { all.randomElement() ?? all[0] }
}

// MARK: - Find the Mistake mode

/// One deliberately-introduced flaw a rendered graph can contain, for the
/// "Identify Graph Errors" practice mode.
enum GraphMistakeKind: CaseIterable, Equatable, Hashable {
    case wrongScale
    case missingUnit
    case missingTitle
    case wrongAxisLabel
    case overFittedLine
    case wrongPlotting

    var shortLabel: String {
        switch self {
        case .wrongScale: return "Wrong scale"
        case .missingUnit: return "Missing unit"
        case .missingTitle: return "Missing title"
        case .wrongAxisLabel: return "Incorrect axis label"
        case .overFittedLine: return "Line forced through every point"
        case .wrongPlotting: return "Incorrect plotting"
        }
    }

    var explanation: String {
        switch self {
        case .wrongScale:
            return "The scale wastes graph paper — the plotted points are squeezed into a small corner instead of using more than half the grid."
        case .missingUnit:
            return "An axis label is missing its unit. Examiners require the label and its unit together, e.g. \"Time / s\"."
        case .missingTitle:
            return "The graph has no title. Every practical graph needs a title stating what is plotted against what."
        case .wrongAxisLabel:
            return "The axis label doesn't match the quantity actually plotted on that axis."
        case .overFittedLine:
            return "The line zig-zags through every single point instead of being a single straight best-fit line balanced through the trend."
        case .wrongPlotting:
            return "One point is plotted well away from where its x and y values actually place it."
        }
    }
}

struct GraphMistakeChallenge {
    let dataset: GraphDataset
    let definition: GraphCoachType.Definition
    let mistake: GraphMistakeKind
    let options: [GraphMistakeKind]
    /// Only populated when `mistake == .wrongPlotting` — the index of the
    /// point that was nudged off-trend, and its displayed (flawed) position.
    let flawedPointIndex: Int?
    let flawedPoint: GraphPoint?
}

struct GraphMistakeGenerator {
    private let datasetGenerator = GraphDatasetGenerator()

    func generate(type: GraphCoachType, curriculum: Curriculum) -> GraphMistakeChallenge {
        let seed = Int.random(in: 0...Int(Int32.max))
        let dataset = datasetGenerator.generate(type: type, seed: seed, curriculum: curriculum)
        let mistake = GraphMistakeKind.allCases.randomElement() ?? .missingUnit

        var options = [mistake]
        while options.count < 4 {
            if let candidate = GraphMistakeKind.allCases.randomElement(), !options.contains(where: { $0.shortLabel == candidate.shortLabel }) {
                options.append(candidate)
            }
        }
        options.shuffle()

        var flawedIndex: Int?
        var flawedPoint: GraphPoint?
        if mistake == .wrongPlotting, let maxY = dataset.points.map(\.y).max(), maxY > 0 {
            let index = Int.random(in: 0..<dataset.points.count)
            let original = dataset.points[index]
            flawedIndex = index
            flawedPoint = GraphPoint(x: original.x, y: max(0, original.y - maxY * 0.28))
        }

        return GraphMistakeChallenge(
            dataset: dataset, definition: type.definition, mistake: mistake,
            options: options, flawedPointIndex: flawedIndex, flawedPoint: flawedPoint
        )
    }
}
