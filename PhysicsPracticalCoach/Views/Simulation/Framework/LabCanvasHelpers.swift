//
//  LabCanvasHelpers.swift
//  PhysicsPracticalCoach
//
//  Small, dependency-free drawing functions that operate directly on a
//  SwiftUI `GraphicsContext`. Every lab experiment's apparatus Canvas calls
//  into these instead of re-deriving tick-mark math each time — a ruler
//  drawn for Pendulum's string length looks and behaves identically to one
//  drawn for Hooke's Law's spring extension or Density's cylinder depth.
//
//  ANDROID PORTING NOTE: these correspond to free functions taking an
//  Android `Canvas` + `Paint` and doing the same tick-mark loop math — the
//  geometry here (tick spacing, major/minor mark heights) is the
//  specification to copy exactly so a ruler looks the same on both
//  platforms.
//

import SwiftUI

enum LabCanvasHelpers {

    /// Draws a vertical ruler with major ticks every 5th minor division,
    /// used for any experiment measuring a vertical length (pendulum string,
    /// spring extension, liquid depth). `maxValue`/`unit` label the ruler;
    /// `minorStep` is the value each small tick represents.
    static func drawVerticalRuler(
        context: GraphicsContext,
        originX: CGFloat,
        topY: CGFloat,
        heightPx: CGFloat,
        maxValue: Double,
        minorStep: Double,
        color: Color = Color(hex: "#8B9997")
    ) {
        var path = Path()
        path.move(to: CGPoint(x: originX, y: topY))
        path.addLine(to: CGPoint(x: originX, y: topY + heightPx))

        var mark = 0
        let totalMarks = Int((maxValue / minorStep).rounded())
        while mark <= totalMarks {
            let fraction = CGFloat(mark) / CGFloat(totalMarks)
            let y = topY + fraction * heightPx
            let tickLength: CGFloat = mark % 5 == 0 ? 16 : 8
            path.move(to: CGPoint(x: originX - tickLength, y: y))
            path.addLine(to: CGPoint(x: originX, y: y))
            mark += 1
        }
        context.stroke(path, with: .color(color), lineWidth: 2)
    }

    /// Draws a horizontal ruler with major ticks every 5th minor division,
    /// used for any experiment measuring a horizontal length along a wire
    /// (potentiometer jockey position, resistance-wire length).
    static func drawHorizontalRuler(
        context: GraphicsContext,
        originY: CGFloat,
        leftX: CGFloat,
        widthPx: CGFloat,
        maxValue: Double,
        minorStep: Double,
        color: Color = Color(hex: "#8B9997")
    ) {
        var path = Path()
        path.move(to: CGPoint(x: leftX, y: originY))
        path.addLine(to: CGPoint(x: leftX + widthPx, y: originY))

        var mark = 0
        let totalMarks = Int((maxValue / minorStep).rounded())
        while mark <= totalMarks {
            let fraction = CGFloat(mark) / CGFloat(totalMarks)
            let x = leftX + fraction * widthPx
            let tickLength: CGFloat = mark % 5 == 0 ? 16 : 8
            path.move(to: CGPoint(x: x, y: originY))
            path.addLine(to: CGPoint(x: x, y: originY + tickLength))
            mark += 1
        }
        context.stroke(path, with: .color(color), lineWidth: 2)
    }

    /// Draws a protractor-style arc with degree tick marks every 10 degrees,
    /// used for any experiment measuring an angle (pendulum release angle,
    /// refraction angle of incidence, moments' beam tilt). Pass
    /// `minorTickStepDeg` to add shorter intermediate ticks (e.g. every 5
    /// degrees) for finer by-eye reading \u{2014} existing callers are unaffected
    /// since it defaults to `nil` (10-degree ticks only).
    static func drawProtractorArc(
        context: GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        startDeg: Double = -90,
        endDeg: Double = 90,
        color: Color = Color(hex: "#8B9997"),
        minorTickStepDeg: Double? = nil
    ) {
        var arc = Path()
        arc.addArc(
            center: center, radius: radius,
            startAngle: .degrees(startDeg), endAngle: .degrees(endDeg),
            clockwise: false
        )
        context.stroke(arc, with: .color(color), lineWidth: 1.5)

        var deg = startDeg
        while deg <= endDeg {
            let rad = deg * .pi / 180
            let inner = CGPoint(x: center.x + (radius - 8) * cos(rad), y: center.y + (radius - 8) * sin(rad))
            let outer = CGPoint(x: center.x + radius * cos(rad), y: center.y + radius * sin(rad))
            var tick = Path()
            tick.move(to: inner)
            tick.addLine(to: outer)
            context.stroke(tick, with: .color(color), lineWidth: 1)
            deg += 10
        }

        if let minorStep = minorTickStepDeg, minorStep > 0, minorStep < 10 {
            var minorDeg = startDeg
            while minorDeg <= endDeg {
                if Int((minorDeg - startDeg).rounded()) % 10 != 0 {
                    let rad = minorDeg * .pi / 180
                    let inner = CGPoint(x: center.x + (radius - 4) * cos(rad), y: center.y + (radius - 4) * sin(rad))
                    let outer = CGPoint(x: center.x + radius * cos(rad), y: center.y + radius * sin(rad))
                    var tick = Path()
                    tick.move(to: inner)
                    tick.addLine(to: outer)
                    context.stroke(tick, with: .color(color.opacity(0.7)), lineWidth: 0.75)
                }
                minorDeg += minorStep
            }
        }
    }

    /// Draws a small curved arc between two directions from a shared vertex
    /// \u{2014} the "which angle am I measuring" indicator used next to a
    /// protractor reading, exactly like the curved angle mark in a textbook
    /// ray diagram. Distinct from `drawProtractorArc`: no tick marks, no
    /// degree scale, just the arc itself plus an optional short label at its
    /// midpoint.
    static func drawAngleIndicatorArc(
        context: GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        startDeg: Double,
        endDeg: Double,
        color: Color = .primary,
        label: String? = nil,
        labelSize: CGFloat = 12
    ) {
        var arc = Path()
        arc.addArc(
            center: center, radius: radius,
            startAngle: .degrees(startDeg), endAngle: .degrees(endDeg),
            clockwise: false
        )
        context.stroke(arc, with: .color(color), lineWidth: 1.5)

        if let label {
            let midDeg = (startDeg + endDeg) / 2
            let midRad = midDeg * .pi / 180
            let labelRadius = radius + 13
            let point = CGPoint(x: center.x + labelRadius * cos(midRad), y: center.y + labelRadius * sin(midRad))
            drawLabel(context: context, text: label, at: point, size: labelSize, weight: .semibold, color: color)
        }
    }

    /// Draws a filled circular "bob"/weight with an optional warning color,
    /// used for pendulum bobs, hanging masses, and moments' weights.
    static func drawWeight(
        context: GraphicsContext,
        center: CGPoint,
        radiusPx: CGFloat,
        color: Color
    ) {
        context.fill(
            Path(ellipseIn: CGRect(x: center.x - radiusPx, y: center.y - radiusPx, width: radiusPx * 2, height: radiusPx * 2)),
            with: .color(color)
        )
    }

    /// Draws centred label text at a point — thin wrapper so every
    /// experiment's on-canvas labels (length readout, angle readout, current
    /// value) use the same font weight/size convention.
    static func drawLabel(
        context: GraphicsContext,
        text: String,
        at point: CGPoint,
        size: CGFloat = 15,
        weight: Font.Weight = .regular,
        color: Color = .primary
    ) {
        context.draw(
            Text(text).font(.system(size: size, weight: weight)).foregroundColor(color),
            at: point
        )
    }
}
