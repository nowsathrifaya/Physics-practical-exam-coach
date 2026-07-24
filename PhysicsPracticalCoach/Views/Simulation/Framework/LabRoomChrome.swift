//
//  LabRoomChrome.swift
//  PhysicsPracticalCoach
//
//  Shared visual dressing for the Virtual Lab's "getting ready" stages
//  (Introduction, Collect Apparatus, Set Up) — a soft classroom backdrop,
//  a whiteboard-styled instruction card (with an optional highlighted key
//  phrase, e.g. the quantity being measured), and a small friendly "Coach"
//  avatar. Inspired by a classic point-and-click lab scene, but drawn in
//  the app's own flat, hand-illustrated Canvas style rather than copying
//  any reference art.
//

import SwiftUI

// MARK: - Classroom backdrop

/// A soft two-tone backdrop — pale sky-blue "wall" above, warm wood-tone
/// "counter" strip below — with a few lightweight decorative touches
/// (a wall clock, a window) so the pre-experiment stages read as "a lab
/// room" rather than a plain system background.
struct LabRoomBackdrop: View {
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [Color(hex: "#DCEBFA"), Color(hex: "#EAF3FB")],
                    startPoint: .top, endPoint: .bottom
                )

                // Counter strip along the bottom third, echoing the wooden
                // bench that the apparatus actually sits on.
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [Color(hex: "#C99A63"), Color(hex: "#B98653")],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: max(geo.size.height * 0.16, 40))
                }

                HStack {
                    Spacer()
                    wallClock.padding(.top, 14).padding(.trailing, 18)
                }

                HStack {
                    windowPane.padding(.top, 18).padding(.leading, 18)
                    Spacer()
                }
            }
        }
        .ignoresSafeArea(edges: [])
    }

    private var wallClock: some View {
        ZStack {
            Circle().fill(Color.white).frame(width: 34, height: 34)
            Circle().stroke(Color(hex: "#8B6B3E"), lineWidth: 2.5).frame(width: 34, height: 34)
            Path { path in
                path.move(to: CGPoint(x: 17, y: 17))
                path.addLine(to: CGPoint(x: 17, y: 9))
            }
            .stroke(Color(hex: "#3A3A3A"), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
            Path { path in
                path.move(to: CGPoint(x: 17, y: 17))
                path.addLine(to: CGPoint(x: 23, y: 17))
            }
            .stroke(Color(hex: "#3A3A3A"), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        }
        .frame(width: 34, height: 34)
        .opacity(0.9)
    }

    private var windowPane: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.white.opacity(0.55))
            .frame(width: 46, height: 34)
            .overlay(
                RoundedRectangle(cornerRadius: 4).stroke(Color(hex: "#8B6B3E"), lineWidth: 2.5)
            )
            .overlay(Rectangle().fill(Color(hex: "#8B6B3E")).frame(width: 2.5))
            .overlay(Rectangle().fill(Color(hex: "#8B6B3E")).frame(height: 2.5))
            .opacity(0.85)
    }
}

// MARK: - Whiteboard instruction card

/// The day's instruction, styled like a classroom whiteboard: a wood-toned
/// frame around a white "board", with an optional key phrase picked out in
/// red marker — e.g. "Measure and record the mass of the **metal block**
/// in kg."
struct WhiteboardCard: View {
    var eyebrow: String? = nil
    let text: String
    /// A substring of `text` to render in red, like a teacher underlining
    /// the key term with a red marker. Matched case-sensitively; if not
    /// found, the whole line renders in plain ink.
    var highlight: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let eyebrow {
                Text(eyebrow.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(.secondary)
            }
            highlightedText
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(Color(hex: "#1F2A2E"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color(hex: "#8B6B3E"), lineWidth: 6)
        )
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
    }

    @ViewBuilder
    private var highlightedText: some View {
        if let highlight, let range = text.range(of: highlight) {
            let before = String(text[text.startIndex..<range.lowerBound])
            let match = String(text[range])
            let after = String(text[range.upperBound...])
            Text(before) + Text(match).foregroundStyle(.red) + Text(after)
        } else {
            Text(text)
        }
    }
}

// MARK: - Coach avatar

/// A small, friendly bust — round glasses, a lab coat collar — standing in
/// for a teacher/coach beside the instruction board. Deliberately simple
/// and generic (not a depiction of any real person), drawn with the same
/// flat-shape Canvas technique used for the apparatus line-art elsewhere
/// in the app.
struct LabCoachAvatar: View {
    var size: CGFloat = 52

    var body: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height

            // Lab coat shoulders
            var coat = Path()
            coat.addArc(center: CGPoint(x: w * 0.5, y: h * 1.05), radius: w * 0.52, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
            context.fill(coat, with: .color(.white))
            context.stroke(coat, with: .color(Color(hex: "#C7CDCF")), lineWidth: 1.5)

            // Collar
            var collar = Path()
            collar.move(to: CGPoint(x: w * 0.42, y: h * 0.82))
            collar.addLine(to: CGPoint(x: w * 0.5, y: h * 0.95))
            collar.addLine(to: CGPoint(x: w * 0.58, y: h * 0.82))
            context.stroke(collar, with: .color(Color(hex: "#8EA0C7")), lineWidth: 3)

            // Head
            let headRect = CGRect(x: w * 0.28, y: h * 0.12, width: w * 0.44, height: w * 0.44)
            context.fill(Path(ellipseIn: headRect), with: .color(Color(hex: "#F2C79E")))

            // Hair
            var hair = Path()
            hair.addArc(center: CGPoint(x: headRect.midX, y: headRect.minY + headRect.height * 0.32), radius: headRect.width * 0.52, startAngle: .degrees(190), endAngle: .degrees(350), clockwise: false)
            context.fill(hair, with: .color(Color(hex: "#6B5B45")))

            // Glasses
            let eyeY = headRect.midY + headRect.height * 0.06
            let lensRadius = headRect.width * 0.15
            let leftCenter = CGPoint(x: headRect.midX - headRect.width * 0.2, y: eyeY)
            let rightCenter = CGPoint(x: headRect.midX + headRect.width * 0.2, y: eyeY)
            var glasses = Path()
            glasses.addEllipse(in: CGRect(x: leftCenter.x - lensRadius, y: eyeY - lensRadius, width: lensRadius * 2, height: lensRadius * 2))
            glasses.addEllipse(in: CGRect(x: rightCenter.x - lensRadius, y: eyeY - lensRadius, width: lensRadius * 2, height: lensRadius * 2))
            glasses.move(to: CGPoint(x: leftCenter.x + lensRadius, y: eyeY))
            glasses.addLine(to: CGPoint(x: rightCenter.x - lensRadius, y: eyeY))
            context.stroke(glasses, with: .color(Color(hex: "#3A3A3A")), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))

            // Smile
            var smile = Path()
            smile.addArc(center: CGPoint(x: headRect.midX, y: headRect.midY + headRect.height * 0.28), radius: headRect.width * 0.14, startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
            context.stroke(smile, with: .color(Color(hex: "#8A5A3E")), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
