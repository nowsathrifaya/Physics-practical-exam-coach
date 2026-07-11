//
//  ApparatusVisuals.swift
//  PhysicsPracticalCoach
//
//  Bespoke, realistic Canvas renderings for all 9 apparatus types, replacing
//  the previous generic semicircular-dial / plain-bar placeholder (which also
//  silently drew nothing at all for the micrometer). Palette and instrument
//  geometry are ported from the Android custom Views (ui.apparatus.*View.kt)
//  so both platforms look like the same real physics apparatus rather than
//  schematic stand-ins.
//

import SwiftUI

enum ApparatusPalette {
    static let steelLight = Color(hex: "#EEF1F0")
    static let steelMid = Color(hex: "#C4CDCB")
    static let steelDark = Color(hex: "#8B9997")
    static let frame = Color(hex: "#5A6664")
    static let ink = Color(hex: "#1A2827")
    static let accent = Color(hex: "#D98B36")
    static let green = Color(hex: "#175C54")
    static let glassFill = Color(hex: "#D0EAE8")
    static let glassFillCyl = Color(hex: "#C8E8E6")
    static let mercuryRed = Color(hex: "#D42B2B")
    static let liquidBlue = Color(hex: "#4EA8DE")
    static let meniscusBlue = Color(hex: "#2E86C1")
    static let caseBackground = Color(hex: "#EBEEE8")
}

// MARK: - Vernier caliper

struct VernierCaliperCanvasView: View {
    let mainScaleCm: Double
    let vernierCoincidence: Int
    let zeroErrorCm: Double

    var body: some View {
        Canvas { context, size in
            let beamLeft: CGFloat = size.width * 0.07
            let beamRight: CGFloat = size.width * 0.96
            let beamTop: CGFloat = size.height * 0.40
            let beamBottom: CGFloat = beamTop + 24
            let fixedJawWidth: CGFloat = 20

            let scaleStartX = beamLeft + fixedJawWidth + 8
            let availablePx = (beamRight - 14) - scaleStartX
            let mmPx = max(availablePx / 90, 2.2)

            // Fixed jaw block (left, stationary)
            let fixedBlock = CGRect(x: beamLeft, y: beamTop - 12, width: fixedJawWidth, height: (beamBottom - beamTop) + 36)
            context.fill(Path(roundedRect: fixedBlock, cornerRadius: 3), with: .color(ApparatusPalette.steelDark))
            context.fill(Path(CGRect(x: beamLeft + 4, y: beamTop - 36, width: 8, height: 24)), with: .color(ApparatusPalette.steelDark))
            context.fill(Path(CGRect(x: beamLeft + 12, y: beamBottom + 24, width: 6, height: 18)), with: .color(ApparatusPalette.steelDark))

            // Beam body (steel gradient)
            let beamRect = CGRect(x: beamLeft, y: beamTop, width: beamRight - beamLeft, height: beamBottom - beamTop)
            context.fill(
                Path(roundedRect: beamRect, cornerRadius: 3),
                with: .linearGradient(Gradient(colors: [ApparatusPalette.steelLight, ApparatusPalette.steelMid]), startPoint: CGPoint(x: 0, y: beamRect.minY), endPoint: CGPoint(x: 0, y: beamRect.maxY))
            )
            context.stroke(Path(roundedRect: beamRect, cornerRadius: 3), with: .color(ApparatusPalette.steelDark), lineWidth: 1)

            // Main scale (cm labelled, mm ticks)
            var mainScale = Path()
            for mm in 0...90 {
                let x = scaleStartX + CGFloat(mm) * mmPx
                if x > beamRight - 10 { break }
                let isCm = mm % 10 == 0
                mainScale.move(to: CGPoint(x: x, y: beamTop))
                mainScale.addLine(to: CGPoint(x: x, y: beamTop + (isCm ? 12 : 6)))
            }
            context.stroke(mainScale, with: .color(ApparatusPalette.ink), lineWidth: 1)
            for cm in 0...9 {
                let x = scaleStartX + CGFloat(cm) * 10 * mmPx
                if x > beamRight - 10 { break }
                context.draw(Text("\(cm)").font(.system(size: 8)), at: CGPoint(x: x, y: beamTop - 8))
            }
            context.draw(Text("cm").font(.system(size: 8, weight: .bold)).foregroundColor(ApparatusPalette.ink), at: CGPoint(x: beamLeft + 10, y: beamTop - 18))

            // Moving jaw + slider position
            let vernierZeroMm = mainScaleCm * 10.0 + Double(vernierCoincidence) * 0.1
            let vernierZeroX = scaleStartX + CGFloat(vernierZeroMm) * mmPx
            let sliderWidth: CGFloat = 34
            let sliderLeft = min(max(vernierZeroX - 8, beamLeft), beamRight - sliderWidth)

            context.fill(Path(CGRect(x: vernierZeroX - 3, y: beamTop - 36, width: 6, height: 24)), with: .color(ApparatusPalette.steelDark))
            context.fill(Path(CGRect(x: vernierZeroX - 4, y: beamBottom + 24, width: 8, height: 18)), with: .color(ApparatusPalette.steelDark))

            let sliderRect = CGRect(x: sliderLeft, y: beamTop - 8, width: sliderWidth, height: (beamBottom - beamTop) + 26)
            context.fill(
                Path(roundedRect: sliderRect, cornerRadius: 4),
                with: .linearGradient(Gradient(colors: [ApparatusPalette.steelMid, ApparatusPalette.steelDark]), startPoint: CGPoint(x: 0, y: sliderRect.minY), endPoint: CGPoint(x: 0, y: sliderRect.maxY))
            )
            context.stroke(Path(roundedRect: sliderRect, cornerRadius: 4), with: .color(ApparatusPalette.steelDark), lineWidth: 1)

            var grip = Path()
            for i in 0..<3 {
                let gx = sliderLeft + 8 + CGFloat(i) * 5
                grip.move(to: CGPoint(x: gx, y: sliderRect.maxY - 14))
                grip.addLine(to: CGPoint(x: gx, y: sliderRect.maxY - 4))
            }
            context.stroke(grip, with: .color(ApparatusPalette.frame), lineWidth: 1.2)
            context.fill(Path(ellipseIn: CGRect(x: sliderRect.maxX - 12, y: sliderRect.maxY - 12, width: 6, height: 6)), with: .color(ApparatusPalette.frame))

            // Vernier scale — accent tick at the coincidence, green elsewhere
            let vernierPitchPx = (9 * mmPx) / 10
            var vernierScale = Path()
            for i in 0...10 where i != vernierCoincidence {
                let x = vernierZeroX + CGFloat(i) * vernierPitchPx
                vernierScale.move(to: CGPoint(x: x, y: beamTop))
                vernierScale.addLine(to: CGPoint(x: x, y: beamTop + 6))
            }
            context.stroke(vernierScale, with: .color(ApparatusPalette.green), lineWidth: 1)

            let matchX = vernierZeroX + CGFloat(vernierCoincidence) * vernierPitchPx
            var matchTick = Path()
            matchTick.move(to: CGPoint(x: matchX, y: beamTop))
            matchTick.addLine(to: CGPoint(x: matchX, y: beamTop + 12))
            context.stroke(matchTick, with: .color(ApparatusPalette.accent), lineWidth: 2)
        }
        .overlay(alignment: .bottom) {
            Text(zeroErrorCm == 0 ? "Zero error: none" : "Zero error: \(zeroErrorCm > 0 ? "+" : "")\(String(format: "%.2f", zeroErrorCm)) cm")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.bottom, 6)
        }
        .accessibilityLabel("Vernier caliper reading diagram")
    }
}

// MARK: - Micrometer screw gauge

struct MicrometerCanvasView: View {
    let sleeveWholeMm: Int
    let showHalfMm: Bool
    let thimbleHundredths: Int
    let zeroErrorMm: Double

    var body: some View {
        Canvas { context, size in
            let centerY = size.height * 0.42
            let sleeveHalfHeight: CGFloat = 14
            let thimbleRadius = min(size.height * 0.32, 56)

            let frameLeft: CGFloat = 8
            let sleeveLeft: CGFloat = 44

            // C-frame, anvil, spindle
            var framePath = Path()
            framePath.move(to: CGPoint(x: frameLeft + 14, y: centerY - 28))
            framePath.addQuadCurve(to: CGPoint(x: frameLeft + 14, y: centerY + 28), control: CGPoint(x: frameLeft - 6, y: centerY))
            context.stroke(framePath, with: .color(ApparatusPalette.frame), lineWidth: 6)
            context.fill(Path(roundedRect: CGRect(x: frameLeft + 10, y: centerY - 4, width: 14, height: 8), cornerRadius: 1.5), with: .color(ApparatusPalette.frame))
            context.fill(Path(roundedRect: CGRect(x: frameLeft + 22, y: centerY - 2.5, width: max(sleeveLeft - frameLeft - 20, 4), height: 5), cornerRadius: 1.5), with: .color(ApparatusPalette.steelDark))

            // Sleeve (fixed barrel, linear scale)
            let sleeveRight = size.width * 0.55
            let sleeveRect = CGRect(x: sleeveLeft, y: centerY - sleeveHalfHeight, width: sleeveRight - sleeveLeft, height: sleeveHalfHeight * 2)
            context.fill(
                Path(roundedRect: sleeveRect, cornerRadius: 4),
                with: .linearGradient(Gradient(colors: [ApparatusPalette.steelLight, ApparatusPalette.steelMid]), startPoint: CGPoint(x: 0, y: sleeveRect.minY), endPoint: CGPoint(x: 0, y: sleeveRect.maxY))
            )
            context.stroke(Path(roundedRect: sleeveRect, cornerRadius: 4), with: .color(ApparatusPalette.steelDark), lineWidth: 1.4)

            let mmPx = max((sleeveRight - sleeveLeft - 16) / 25, 4)
            let scaleOriginX = sleeveLeft + 8
            for mm in 0...25 {
                let x = scaleOriginX + CGFloat(mm) * mmPx
                if x > sleeveRight - 4 { break }
                let isMatch = mm == sleeveWholeMm
                var tick = Path()
                tick.move(to: CGPoint(x: x, y: centerY - sleeveHalfHeight))
                tick.addLine(to: CGPoint(x: x, y: centerY))
                context.stroke(tick, with: .color(isMatch ? ApparatusPalette.accent : ApparatusPalette.ink), lineWidth: isMatch ? 2 : 1)
                if mm % 5 == 0 {
                    context.draw(Text("\(mm)").font(.system(size: 7)), at: CGPoint(x: x, y: centerY - sleeveHalfHeight - 7))
                }
                if mm < 25 {
                    let halfX = x + mmPx / 2
                    let halfMatch = showHalfMm && mm == sleeveWholeMm
                    var htick = Path()
                    htick.move(to: CGPoint(x: halfX, y: centerY))
                    htick.addLine(to: CGPoint(x: halfX, y: centerY + sleeveHalfHeight))
                    context.stroke(htick, with: .color(halfMatch ? ApparatusPalette.accent : ApparatusPalette.green), lineWidth: halfMatch ? 2 : 1)
                }
            }
            context.draw(Text("mm").font(.system(size: 8, weight: .bold)).foregroundColor(ApparatusPalette.ink), at: CGPoint(x: sleeveLeft + 6, y: centerY - sleeveHalfHeight - 16))

            // Reference line into the thimble
            let thimbleCenterX = size.width * 0.76
            var refLine = Path()
            refLine.move(to: CGPoint(x: sleeveLeft, y: centerY))
            refLine.addLine(to: CGPoint(x: thimbleCenterX, y: centerY))
            context.stroke(refLine, with: .color(ApparatusPalette.ink), lineWidth: 1.4)

            // Thimble (rotating drum, 50 divisions, current reading sits at the reference line)
            let thimbleRect = CGRect(x: thimbleCenterX - thimbleRadius, y: centerY - thimbleRadius, width: thimbleRadius * 2, height: thimbleRadius * 2)
            context.fill(
                Path(ellipseIn: thimbleRect),
                with: .linearGradient(Gradient(colors: [ApparatusPalette.steelMid, ApparatusPalette.steelDark]), startPoint: CGPoint(x: 0, y: thimbleRect.minY), endPoint: CGPoint(x: 0, y: thimbleRect.maxY))
            )
            context.stroke(Path(ellipseIn: thimbleRect), with: .color(ApparatusPalette.steelDark), lineWidth: 1.4)

            let degreesPerDivision = 360.0 / 50.0
            for d in 0..<50 {
                let angleDeg = 180.0 + Double(d - thimbleHundredths) * degreesPerDivision
                let rad = angleDeg * .pi / 180
                let isMajor = d % 5 == 0
                let isMatch = d == thimbleHundredths
                let outerR = thimbleRadius - 3
                let innerR = outerR - (isMajor ? 11 : 6)
                let x1 = thimbleCenterX + CGFloat(cos(rad)) * innerR
                let y1 = centerY + CGFloat(sin(rad)) * innerR
                let x2 = thimbleCenterX + CGFloat(cos(rad)) * outerR
                let y2 = centerY + CGFloat(sin(rad)) * outerR
                var tick = Path()
                tick.move(to: CGPoint(x: x1, y: y1))
                tick.addLine(to: CGPoint(x: x2, y: y2))
                let tickColor: Color = isMatch ? ApparatusPalette.accent : (isMajor ? ApparatusPalette.ink : ApparatusPalette.ink.opacity(0.55))
                context.stroke(tick, with: .color(tickColor), lineWidth: isMatch ? 2 : 1)
                if isMajor {
                    let labelR = outerR - 17
                    let lx = thimbleCenterX + CGFloat(cos(rad)) * labelR
                    let ly = centerY + CGFloat(sin(rad)) * labelR
                    context.draw(Text("\(d)").font(.system(size: 7)), at: CGPoint(x: lx, y: ly))
                }
            }
            context.fill(Path(ellipseIn: CGRect(x: thimbleCenterX - thimbleRadius - 2, y: centerY - 2, width: 4, height: 4)), with: .color(ApparatusPalette.accent))
        }
        .overlay(alignment: .bottom) {
            Text(zeroErrorMm == 0 ? "Zero error: none" : "Zero error: \(zeroErrorMm > 0 ? "+" : "")\(String(format: "%.2f", zeroErrorMm)) mm")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.bottom, 6)
        }
        .accessibilityLabel("Micrometer reading diagram")
    }
}

// MARK: - Ammeter / voltmeter (shared dial gauge)

struct DialGaugeCanvasView: View {
    let unitLabel: String
    let maxReading: Double
    let needleReading: Double

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height * 0.66)
            let radius = min(size.width, size.height) * 0.40

            let caseRect = CGRect(x: center.x - radius - 16, y: center.y - radius - 22, width: (radius + 16) * 2, height: radius + 44)
            context.fill(Path(roundedRect: caseRect, cornerRadius: 10), with: .color(ApparatusPalette.caseBackground))
            context.stroke(Path(roundedRect: caseRect, cornerRadius: 10), with: .color(ApparatusPalette.steelDark), lineWidth: 1.4)

            var arc = Path()
            arc.addArc(center: center, radius: radius, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            context.stroke(arc, with: .color(ApparatusPalette.ink), lineWidth: 2)

            let divisions = maxReading <= 1.0 ? 10 : 50
            let majorEvery = max(divisions / 5, 1)
            for i in 0...divisions {
                let fraction = Double(i) / Double(divisions)
                let angle = 180.0 + fraction * 180.0
                let rad = angle * .pi / 180
                let isMajor = i % majorEvery == 0
                let inner = radius - (isMajor ? 14 : 8)
                let x1 = center.x + CGFloat(cos(rad)) * inner
                let y1 = center.y + CGFloat(sin(rad)) * inner
                let x2 = center.x + CGFloat(cos(rad)) * radius
                let y2 = center.y + CGFloat(sin(rad)) * radius
                var tick = Path()
                tick.move(to: CGPoint(x: x1, y: y1))
                tick.addLine(to: CGPoint(x: x2, y: y2))
                context.stroke(tick, with: .color(ApparatusPalette.ink), lineWidth: isMajor ? 1.6 : 1)
                if isMajor {
                    let value = maxReading * fraction
                    let labelR = radius - 26
                    let lx = center.x + CGFloat(cos(rad)) * labelR
                    let ly = center.y + CGFloat(sin(rad)) * labelR
                    let text = value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(format: "%.1f", value)
                    context.draw(Text(text).font(.system(size: 9)), at: CGPoint(x: lx, y: ly))
                }
            }

            let needleFraction = max(0, min(1, needleReading / maxReading))
            let needleAngleRad = (180.0 + needleFraction * 180.0) * .pi / 180
            let needleEnd = CGPoint(x: center.x + CGFloat(cos(needleAngleRad)) * (radius - 10), y: center.y + CGFloat(sin(needleAngleRad)) * (radius - 10))
            var needle = Path()
            needle.move(to: center)
            needle.addLine(to: needleEnd)
            context.stroke(needle, with: .color(ApparatusPalette.mercuryRed), lineWidth: 2.5)
            context.fill(Path(ellipseIn: CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8)), with: .color(ApparatusPalette.ink))

            context.draw(Text(unitLabel).font(.system(size: 14, weight: .bold)).foregroundColor(ApparatusPalette.green), at: CGPoint(x: center.x, y: center.y - radius - 8))
            let maxText = maxReading.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", maxReading) : String(format: "%.1f", maxReading)
            context.draw(Text("0 – \(maxText) \(unitLabel)").font(.system(size: 10)), at: CGPoint(x: center.x, y: center.y + 18))
        }
        .accessibilityLabel("\(unitLabel == "A" ? "Ammeter" : "Voltmeter") reading diagram")
    }
}

// MARK: - Newton meter (spring balance)

struct NewtonMeterCanvasView: View {
    let maxReading: Double
    let pointerReading: Double

    var body: some View {
        Canvas { context, size in
            let cx = size.width * 0.42
            let bodyW = size.width * 0.22
            let topY: CGFloat = 18
            let bodyH = size.height - 46
            let scaleTopY = topY + size.height * 0.14
            let scaleBotY = topY + bodyH - size.height * 0.06
            let scaleH = scaleBotY - scaleTopY

            let bodyRect = CGRect(x: cx - bodyW / 2, y: topY, width: bodyW, height: bodyH)
            context.fill(Path(roundedRect: bodyRect, cornerRadius: 10), with: .color(ApparatusPalette.glassFill))
            context.stroke(Path(roundedRect: bodyRect, cornerRadius: 10), with: .color(ApparatusPalette.green), lineWidth: 2)

            var hookLine = Path()
            hookLine.move(to: CGPoint(x: cx, y: topY - 12))
            hookLine.addLine(to: CGPoint(x: cx, y: topY))
            context.stroke(hookLine, with: .color(ApparatusPalette.frame), lineWidth: 2.6)
            var hookArc = Path()
            hookArc.addArc(center: CGPoint(x: cx, y: topY - 18), radius: 7, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: true)
            context.stroke(hookArc, with: .color(ApparatusPalette.frame), lineWidth: 2.6)

            // Spring coils
            let springTopY = topY + size.height * 0.05
            let springBotY = scaleTopY
            var spring = Path()
            let coils = 6
            let halfW: CGFloat = 7
            let segH = (springBotY - springTopY) / CGFloat(coils * 2 + 2)
            spring.move(to: CGPoint(x: cx, y: springTopY))
            spring.addLine(to: CGPoint(x: cx, y: springTopY + segH))
            for i in 0..<coils {
                spring.addLine(to: CGPoint(x: cx + halfW, y: springTopY + segH + CGFloat(i * 2 + 1) * segH))
                spring.addLine(to: CGPoint(x: cx - halfW, y: springTopY + segH + CGFloat(i * 2 + 2) * segH))
            }
            spring.addLine(to: CGPoint(x: cx, y: springBotY))
            context.stroke(spring, with: .color(ApparatusPalette.green), lineWidth: 2)

            // Scale ticks (linear, vertical)
            let majorStep = maxReading == 1.0 ? 0.2 : 0.5
            let minorStep = majorStep / 5
            var v = 0.0
            while v <= maxReading + 0.0005 {
                let fraction = v / maxReading
                let y = scaleBotY - CGFloat(fraction) * scaleH
                let remainder = v.truncatingRemainder(dividingBy: majorStep)
                let isMajor = remainder < 0.001 || (majorStep - remainder) < 0.001
                var tick = Path()
                tick.move(to: CGPoint(x: cx + bodyW / 2 - 2, y: y))
                tick.addLine(to: CGPoint(x: cx + bodyW / 2 + (isMajor ? 10 : 5), y: y))
                context.stroke(tick, with: .color(isMajor ? ApparatusPalette.ink : ApparatusPalette.ink.opacity(0.5)), lineWidth: isMajor ? 1.6 : 1)
                if isMajor {
                    context.draw(Text(String(format: "%.1f", v)).font(.system(size: 9)), at: CGPoint(x: cx + bodyW / 2 + 22, y: y))
                }
                v += minorStep
            }

            let pointerFraction = max(0, min(1, pointerReading / maxReading))
            let pointerY = scaleBotY - CGFloat(pointerFraction) * scaleH
            var pointer = Path()
            pointer.move(to: CGPoint(x: cx - bodyW / 2 + 2, y: pointerY))
            pointer.addLine(to: CGPoint(x: cx + bodyW / 2 + 2, y: pointerY))
            context.stroke(pointer, with: .color(ApparatusPalette.mercuryRed), lineWidth: 2)

            context.draw(Text("N").font(.system(size: 13, weight: .bold)).foregroundColor(ApparatusPalette.green), at: CGPoint(x: cx, y: scaleTopY - 10))
            context.draw(Text(String(format: "%.2f N", pointerReading)).font(.system(size: 11, weight: .semibold)), at: CGPoint(x: cx, y: topY + bodyH + 16))
        }
        .accessibilityLabel("Newton meter reading diagram")
    }
}

// MARK: - Thermometer

struct ThermometerCanvasView: View {
    let bulbTempC: Double
    let scaleMinC: Int
    let scaleMaxC: Int

    var body: some View {
        Canvas { context, size in
            let cx = size.width * 0.36
            let tubeWidth: CGFloat = 14
            let bulbRadius: CGFloat = 15
            let topY: CGFloat = 22
            let bottomY = size.height - bulbRadius - 14
            let tubeHeight = bottomY - topY
            let rangeC = Double(scaleMaxC - scaleMinC)

            let tubeRect = CGRect(x: cx - tubeWidth / 2, y: topY, width: tubeWidth, height: bottomY - topY)
            context.fill(Path(roundedRect: tubeRect, cornerRadius: tubeWidth / 2), with: .color(ApparatusPalette.glassFill))
            context.stroke(Path(roundedRect: tubeRect, cornerRadius: tubeWidth / 2), with: .color(ApparatusPalette.green), lineWidth: 2)

            let liquidFraction = max(0, min(1, (bulbTempC - Double(scaleMinC)) / rangeC))
            let liquidTopY = bottomY - tubeHeight * CGFloat(liquidFraction)
            let mercuryRect = CGRect(x: cx - tubeWidth / 2 + 3, y: liquidTopY, width: tubeWidth - 6, height: bottomY - liquidTopY)
            context.fill(Path(mercuryRect), with: .color(ApparatusPalette.mercuryRed))

            let bulbRect = CGRect(x: cx - bulbRadius, y: bottomY - bulbRadius * 0.5, width: bulbRadius * 2, height: bulbRadius * 2)
            context.fill(Path(ellipseIn: bulbRect), with: .color(ApparatusPalette.mercuryRed))
            context.stroke(Path(ellipseIn: bulbRect), with: .color(ApparatusPalette.green), lineWidth: 2)

            let majorStep = rangeC <= 20 ? 2 : (rangeC <= 50 ? 5 : 10)
            let minorStep = max(majorStep / 2, 1)
            var temp = scaleMinC
            while temp <= scaleMaxC {
                let fraction = Double(temp - scaleMinC) / rangeC
                let y = bottomY - tubeHeight * CGFloat(fraction)
                let isMajor = (temp - scaleMinC) % majorStep == 0
                var tick = Path()
                tick.move(to: CGPoint(x: cx + tubeWidth / 2, y: y))
                tick.addLine(to: CGPoint(x: cx + tubeWidth / 2 + (isMajor ? 11 : 6), y: y))
                context.stroke(tick, with: .color(isMajor ? ApparatusPalette.ink : ApparatusPalette.ink.opacity(0.5)), lineWidth: isMajor ? 1.6 : 1)
                if isMajor {
                    context.draw(Text("\(temp)°").font(.system(size: 9)), at: CGPoint(x: cx + tubeWidth / 2 + 24, y: y))
                }
                temp += minorStep
            }
            context.draw(Text("°C").font(.system(size: 12, weight: .bold)).foregroundColor(ApparatusPalette.green), at: CGPoint(x: cx, y: topY - 12))
        }
        .accessibilityLabel("Thermometer reading diagram")
    }
}

// MARK: - Measuring cylinder

struct MeasuringCylinderCanvasView: View {
    let maxVolumeCm3: Int
    let liquidLevelCm3: Double
    let minorDivisionCm3: Double

    var body: some View {
        Canvas { context, size in
            let cx = size.width * 0.40
            let tubeW = size.width * 0.20
            let topY = size.height * 0.08
            let botY = size.height * 0.86
            let scaleH = botY - topY
            let maxV = Double(maxVolumeCm3)
            let minorDiv = max(minorDivisionCm3, 0.1)

            let liquidFraction = max(0, min(1, liquidLevelCm3 / maxV))
            let liquidTopY = botY - scaleH * CGFloat(liquidFraction)
            context.fill(Path(CGRect(x: cx - tubeW / 2 + 2, y: liquidTopY, width: tubeW - 4, height: botY - liquidTopY)), with: .color(ApparatusPalette.liquidBlue.opacity(0.7)))

            var meniscus = Path()
            let depth: CGFloat = 6
            meniscus.move(to: CGPoint(x: cx - tubeW / 2 + 2, y: liquidTopY))
            meniscus.addCurve(to: CGPoint(x: cx + tubeW / 2 - 2, y: liquidTopY), control1: CGPoint(x: cx - tubeW / 4, y: liquidTopY + depth), control2: CGPoint(x: cx + tubeW / 4, y: liquidTopY + depth))
            context.stroke(meniscus, with: .color(ApparatusPalette.meniscusBlue), lineWidth: 1.6)

            context.fill(Path(roundedRect: CGRect(x: cx - tubeW / 2, y: topY, width: tubeW, height: botY - topY), cornerRadius: 3), with: .color(ApparatusPalette.glassFillCyl.opacity(0.35)))
            var walls = Path()
            walls.move(to: CGPoint(x: cx - tubeW / 2, y: topY))
            walls.addLine(to: CGPoint(x: cx - tubeW / 2, y: botY))
            walls.move(to: CGPoint(x: cx + tubeW / 2, y: topY))
            walls.addLine(to: CGPoint(x: cx + tubeW / 2, y: botY))
            walls.move(to: CGPoint(x: cx - tubeW / 2, y: botY))
            walls.addLine(to: CGPoint(x: cx + tubeW / 2, y: botY))
            context.stroke(walls, with: .color(ApparatusPalette.green), lineWidth: 1.8)

            let majorStep = 10.0
            var v = 0.0
            while v <= maxV + 0.001 {
                let fraction = v / maxV
                let y = botY - scaleH * CGFloat(fraction)
                let isMajor = v.truncatingRemainder(dividingBy: majorStep) < 0.001
                let isMinor = v.truncatingRemainder(dividingBy: minorDiv) < 0.001
                if isMajor {
                    var tick = Path()
                    tick.move(to: CGPoint(x: cx + tubeW / 2, y: y))
                    tick.addLine(to: CGPoint(x: cx + tubeW / 2 + 10, y: y))
                    context.stroke(tick, with: .color(ApparatusPalette.ink), lineWidth: 1.6)
                    context.draw(Text("\(Int(v))").font(.system(size: 9)), at: CGPoint(x: cx + tubeW / 2 + 22, y: y))
                } else if isMinor {
                    var tick = Path()
                    tick.move(to: CGPoint(x: cx + tubeW / 2, y: y))
                    tick.addLine(to: CGPoint(x: cx + tubeW / 2 + 6, y: y))
                    context.stroke(tick, with: .color(ApparatusPalette.ink.opacity(0.5)), lineWidth: 1)
                }
                v += minorDiv
            }

            let readY = liquidTopY + 6
            var arrow = Path()
            arrow.move(to: CGPoint(x: cx + tubeW / 2 + 36, y: readY))
            arrow.addLine(to: CGPoint(x: cx + tubeW / 2 + 4, y: readY))
            context.stroke(arrow, with: .color(ApparatusPalette.mercuryRed), lineWidth: 1.6)
            var arrowHead = Path()
            arrowHead.move(to: CGPoint(x: cx + tubeW / 2 + 4, y: readY))
            arrowHead.addLine(to: CGPoint(x: cx + tubeW / 2 + 11, y: readY - 4))
            arrowHead.addLine(to: CGPoint(x: cx + tubeW / 2 + 11, y: readY + 4))
            arrowHead.closeSubpath()
            context.fill(arrowHead, with: .color(ApparatusPalette.mercuryRed))

            context.draw(Text("cm³").font(.system(size: 11, weight: .bold)).foregroundColor(ApparatusPalette.green), at: CGPoint(x: cx, y: topY - 10))
        }
        .accessibilityLabel("Measuring cylinder reading diagram")
    }
}

// MARK: - Burette

struct BuretteCanvasView: View {
    let readingCm3: Double

    var body: some View {
        Canvas { context, size in
            let cx = size.width * 0.42
            let tubeW = size.width * 0.13
            let topY = size.height * 0.06
            let botY = size.height * 0.80
            let scaleH = botY - topY

            let liquidFraction = max(0, min(1, readingCm3 / 50.0))
            let liquidBotY = topY + scaleH * CGFloat(liquidFraction)
            context.fill(Path(CGRect(x: cx - tubeW / 2 + 2, y: topY, width: tubeW - 4, height: liquidBotY - topY)), with: .color(ApparatusPalette.liquidBlue.opacity(0.7)))

            var meniscus = Path()
            let depth: CGFloat = 5
            meniscus.move(to: CGPoint(x: cx - tubeW / 2 + 2, y: liquidBotY))
            meniscus.addCurve(to: CGPoint(x: cx + tubeW / 2 - 2, y: liquidBotY), control1: CGPoint(x: cx - tubeW / 4, y: liquidBotY + depth), control2: CGPoint(x: cx + tubeW / 4, y: liquidBotY + depth))
            context.stroke(meniscus, with: .color(ApparatusPalette.meniscusBlue), lineWidth: 1.4)

            var walls = Path()
            walls.move(to: CGPoint(x: cx - tubeW / 2, y: topY))
            walls.addLine(to: CGPoint(x: cx - tubeW / 2, y: botY))
            walls.move(to: CGPoint(x: cx + tubeW / 2, y: topY))
            walls.addLine(to: CGPoint(x: cx + tubeW / 2, y: botY))
            context.stroke(walls, with: .color(ApparatusPalette.green), lineWidth: 1.6)

            context.fill(Path(CGRect(x: cx - tubeW / 2 - 3, y: botY - 6, width: tubeW + 6, height: 8)), with: .color(ApparatusPalette.steelDark))

            var v = 0.0
            while v <= 50.001 {
                let fraction = v / 50.0
                let y = topY + scaleH * CGFloat(fraction)
                let isMajor = v.truncatingRemainder(dividingBy: 1.0) < 0.001
                if isMajor {
                    var tick = Path()
                    tick.move(to: CGPoint(x: cx + tubeW / 2, y: y))
                    tick.addLine(to: CGPoint(x: cx + tubeW / 2 + 9, y: y))
                    context.stroke(tick, with: .color(ApparatusPalette.ink), lineWidth: 1.4)
                    if Int(v) % 5 == 0 {
                        context.draw(Text("\(Int(v))").font(.system(size: 8)), at: CGPoint(x: cx + tubeW / 2 + 20, y: y))
                    }
                }
                v += 0.5
            }

            let readY = liquidBotY + 6
            var arrow = Path()
            arrow.move(to: CGPoint(x: cx + tubeW / 2 + 32, y: readY))
            arrow.addLine(to: CGPoint(x: cx + tubeW / 2 + 4, y: readY))
            context.stroke(arrow, with: .color(ApparatusPalette.mercuryRed), lineWidth: 1.4)
            var arrowHead = Path()
            arrowHead.move(to: CGPoint(x: cx + tubeW / 2 + 4, y: readY))
            arrowHead.addLine(to: CGPoint(x: cx + tubeW / 2 + 10, y: readY - 3.5))
            arrowHead.addLine(to: CGPoint(x: cx + tubeW / 2 + 10, y: readY + 3.5))
            arrowHead.closeSubpath()
            context.fill(arrowHead, with: .color(ApparatusPalette.mercuryRed))

            context.draw(Text("0 cm³").font(.system(size: 9)).foregroundColor(ApparatusPalette.mercuryRed), at: CGPoint(x: cx - tubeW / 2 - 28, y: topY))
        }
        .overlay(alignment: .bottom) {
            Text("Scale reads 0 (top) → 50 (bottom)")
                .font(.caption2)
                .foregroundStyle(.orange)
                .padding(.bottom, 4)
        }
        .accessibilityLabel("Burette reading diagram")
    }
}

// MARK: - Stopwatch

struct StopwatchCanvasView: View {
    let minutes: Int
    let seconds: Int
    let tenths: Int

    var body: some View {
        Canvas { context, size in
            let cx = size.width / 2
            let cy = size.height * 0.46
            let radius = min(size.width, size.height) * 0.40

            let faceRect = CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2)
            context.fill(Path(ellipseIn: faceRect), with: .color(ApparatusPalette.caseBackground))
            context.stroke(Path(ellipseIn: faceRect), with: .color(ApparatusPalette.frame), lineWidth: 4)

            for i in 0..<60 {
                let angleDeg = Double(i) * 6 - 90
                let rad = angleDeg * .pi / 180
                let isMajor = i % 5 == 0
                let outerR = radius - 3
                let innerR = outerR - (isMajor ? 11 : 6)
                let x1 = cx + CGFloat(cos(rad)) * innerR
                let y1 = cy + CGFloat(sin(rad)) * innerR
                let x2 = cx + CGFloat(cos(rad)) * outerR
                let y2 = cy + CGFloat(sin(rad)) * outerR
                var tick = Path()
                tick.move(to: CGPoint(x: x1, y: y1))
                tick.addLine(to: CGPoint(x: x2, y: y2))
                context.stroke(tick, with: .color(isMajor ? ApparatusPalette.ink : ApparatusPalette.ink.opacity(0.5)), lineWidth: isMajor ? 1.8 : 1)
                if isMajor {
                    let labelR = outerR - 17
                    let lx = cx + CGFloat(cos(rad)) * labelR
                    let ly = cy + CGFloat(sin(rad)) * labelR
                    context.draw(Text("\(i)").font(.system(size: 9)), at: CGPoint(x: lx, y: ly))
                }
            }

            let minuteFraction = (Double(minutes) + Double(seconds) / 60.0) / 60.0
            let minRad = (minuteFraction * 360 - 90) * .pi / 180
            let minLen = radius * 0.48
            var minHand = Path()
            minHand.move(to: CGPoint(x: cx, y: cy))
            minHand.addLine(to: CGPoint(x: cx + CGFloat(cos(minRad)) * minLen, y: cy + CGFloat(sin(minRad)) * minLen))
            context.stroke(minHand, with: .color(ApparatusPalette.green), lineWidth: 3)

            let secondFraction = (Double(seconds) + Double(tenths) / 10.0) / 60.0
            let secRad = (secondFraction * 360 - 90) * .pi / 180
            let secLen = radius * 0.72
            let tailLen = radius * 0.16
            var secHand = Path()
            secHand.move(to: CGPoint(x: cx - CGFloat(cos(secRad)) * tailLen, y: cy - CGFloat(sin(secRad)) * tailLen))
            secHand.addLine(to: CGPoint(x: cx + CGFloat(cos(secRad)) * secLen, y: cy + CGFloat(sin(secRad)) * secLen))
            context.stroke(secHand, with: .color(ApparatusPalette.accent), lineWidth: 2)

            context.fill(Path(ellipseIn: CGRect(x: cx - 3, y: cy - 3, width: 6, height: 6)), with: .color(ApparatusPalette.frame))

            let displayStr = String(format: "%02d:%02d.%d", minutes, seconds, tenths)
            context.draw(Text(displayStr).font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundColor(ApparatusPalette.green), at: CGPoint(x: cx, y: cy + radius * 0.55))
        }
        .accessibilityLabel("Stopwatch reading diagram")
    }
}
