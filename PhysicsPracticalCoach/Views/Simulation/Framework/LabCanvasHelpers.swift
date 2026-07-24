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
    /// Formats a ruler value without unnecessary trailing zeros — "0.30"
    /// stays as "0.3", "20" stays as "20", so labels read cleanly at any
    /// step size from 0.01 m to 20 cm³.
    private static func formatRulerValue(_ value: Double) -> String {
        if value == value.rounded() { return String(Int(value)) }
        return String(format: "%.2f", value).replacingOccurrences(of: #"0+$"#, with: "", options: .regularExpression).replacingOccurrences(of: #"\.$"#, with: "", options: .regularExpression)
    }

    static func drawVerticalRuler(
        context: GraphicsContext,
        originX: CGFloat,
        topY: CGFloat,
        heightPx: CGFloat,
        maxValue: Double,
        minorStep: Double,
        unit: String = "",
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
            let isMajor = mark % 5 == 0
            let tickLength: CGFloat = isMajor ? 16 : 8
            path.move(to: CGPoint(x: originX - tickLength, y: y))
            path.addLine(to: CGPoint(x: originX, y: y))
            if isMajor {
                drawLabel(context: context, text: formatRulerValue(Double(mark) * minorStep), at: CGPoint(x: originX - tickLength - 15, y: y), size: 9, color: color)
            }
            mark += 1
        }
        context.stroke(path, with: .color(color), lineWidth: 2)

        if !unit.isEmpty {
            drawLabel(context: context, text: "/ \(unit)", at: CGPoint(x: originX - 15, y: topY - 12), size: 9, weight: .semibold, color: color)
        }
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
        unit: String = "",
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
            let isMajor = mark % 5 == 0
            let tickLength: CGFloat = isMajor ? 16 : 8
            path.move(to: CGPoint(x: x, y: originY))
            path.addLine(to: CGPoint(x: x, y: originY + tickLength))
            if isMajor {
                drawLabel(context: context, text: formatRulerValue(Double(mark) * minorStep), at: CGPoint(x: x, y: originY + tickLength + 10), size: 9, color: color)
            }
            mark += 1
        }
        context.stroke(path, with: .color(color), lineWidth: 2)

        if !unit.isEmpty {
            drawLabel(context: context, text: "/ \(unit)", at: CGPoint(x: leftX + widthPx + 16, y: originY + 8), size: 9, weight: .semibold, color: color)
        }
    }

    /// Draws a protractor-style arc with degree tick marks every 10 degrees,
    /// used for any experiment measuring an angle (pendulum release angle,
    /// refraction angle of incidence, moments' beam tilt). Pass
    /// `minorTickStepDeg` to add shorter intermediate ticks (e.g. every 5
    /// degrees) for finer by-eye reading — existing callers are unaffected
    /// since it defaults to `nil` (10-degree ticks only).
    /// Bezel ring + shaded semicircular face for an analogue dial gauge —
    /// drawn underneath the tick marks/needle so the gauge reads as a real
    /// instrument face rather than ticks floating on a flat background.
    /// Shared by the ammeter/voltmeter `DialGaugeView` copies in
    /// OhmsLawLabView, PotentiometerLabView, and ResistanceWireLabView.
    static func drawGaugeFace(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        var face = Path()
        face.addArc(center: center, radius: radius + 6, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
        face.addLine(to: CGPoint(x: center.x - radius - 6, y: center.y))
        face.closeSubpath()
        context.fill(
            face,
            with: .radialGradient(
                Gradient(colors: [Color(.systemBackground), Color(.secondarySystemBackground)]),
                center: CGPoint(x: center.x, y: center.y - radius * 0.3), startRadius: 0, endRadius: radius * 1.3
            )
        )
        var bezel = Path()
        bezel.addArc(center: center, radius: radius + 6, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
        context.stroke(bezel, with: .color(Color(hex: "#8B9997")), lineWidth: 2.5)
        var baseline = Path()
        baseline.move(to: CGPoint(x: center.x - radius - 6, y: center.y))
        baseline.addLine(to: CGPoint(x: center.x + radius + 6, y: center.y))
        context.stroke(baseline, with: .color(Color(hex: "#5A6664")), lineWidth: 1.5)
    }

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
    /// — the "which angle am I measuring" indicator used next to a
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
    /// Draws a slotted mass — the actual apparatus used in these
    /// experiments — rather than a flat, featureless circle. A metallic
    /// radial gradient plus a rim highlight suggest a real metal disc, and
    /// the notch + hook are the two details that make it read as "a mass"
    /// rather than an arbitrary dot at a glance.
    static func drawWeight(
        context: GraphicsContext,
        center: CGPoint,
        radiusPx: CGFloat,
        color: Color
    ) {
        let rect = CGRect(x: center.x - radiusPx, y: center.y - radiusPx, width: radiusPx * 2, height: radiusPx * 2)

        // Below this size, this is being used as a pivot pin or anchor
        // point, not a visible slotted mass — the hook/slot detail would
        // just be noise at a few pixels across, so keep it a simple
        // shaded dot instead.
        guard radiusPx >= 10 else {
            context.fill(
                Path(ellipseIn: rect),
                with: .radialGradient(Gradient(colors: [color.opacity(0.6), color]), center: CGPoint(x: center.x - radiusPx * 0.3, y: center.y - radiusPx * 0.3), startRadius: 0, endRadius: radiusPx * 1.3)
            )
            context.stroke(Path(ellipseIn: rect), with: .color(.black.opacity(0.25)), lineWidth: 0.75)
            return
        }

        // Hook loop above the disc.
        var hook = Path()
        hook.addArc(center: CGPoint(x: center.x, y: center.y - radiusPx - 4), radius: 3.5, startAngle: .degrees(-40), endAngle: .degrees(220), clockwise: false)
        context.stroke(hook, with: .color(color.opacity(0.9)), lineWidth: 2)

        // Disc body — radial gradient gives it a rounded, metallic feel
        // instead of a flat silhouette.
        context.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(
                Gradient(colors: [color.opacity(0.55), color, color.opacity(0.85)]),
                center: CGPoint(x: center.x - radiusPx * 0.3, y: center.y - radiusPx * 0.3),
                startRadius: 0, endRadius: radiusPx * 1.4
            )
        )
        context.stroke(Path(ellipseIn: rect), with: .color(.black.opacity(0.25)), lineWidth: 1)

        // Rim highlight — a light arc near the top-left, the classic cheap
        // "this is shiny metal" cue.
        var highlight = Path()
        highlight.addArc(center: center, radius: radiusPx * 0.72, startAngle: .degrees(200), endAngle: .degrees(280), clockwise: false)
        context.stroke(highlight, with: .color(.white.opacity(0.5)), lineWidth: radiusPx * 0.18)

        // The slot — a real slotted mass has a narrow notch cut from the
        // edge partway to the centre so it can be hung without unthreading
        // a hook. Stops short of dead centre, since callers draw the mass
        // label (e.g. "100 g") right at `center`.
        var slot = Path()
        slot.move(to: CGPoint(x: center.x - radiusPx * 0.14, y: center.y - radiusPx))
        slot.addLine(to: CGPoint(x: center.x - radiusPx * 0.14, y: center.y - radiusPx * 0.3))
        slot.addLine(to: CGPoint(x: center.x + radiusPx * 0.14, y: center.y - radiusPx * 0.3))
        slot.addLine(to: CGPoint(x: center.x + radiusPx * 0.14, y: center.y - radiusPx))
        context.fill(slot, with: .color(Color(.systemGroupedBackground)))
        context.stroke(slot, with: .color(.black.opacity(0.2)), lineWidth: 0.75)
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
