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
