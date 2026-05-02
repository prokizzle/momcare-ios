import SwiftUI

/// Canvas-drawn radial progress ring for the feeding timer screen.
///
/// Drives its own TimelineView(.animation) so the arc updates at 60fps even though
/// the ViewModel ticks the formatted string only once per second.
@MainActor
struct FeedingTimerRing: View {
    let startTime: Date?
    let timerText: String
    var maxDuration: TimeInterval = 45 * 60

    private static let ringSize: CGFloat = 300
    private static let lineWidth: CGFloat = 6

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .fill(MCGradient.glow(color: MCColor.feeding, radius: 150))
                .blur(radius: 2)
            ringLayer
            timerLabel
        }
        .frame(width: Self.ringSize, height: Self.ringSize)
    }

    // MARK: - Ring Layer

    @ViewBuilder
    private var ringLayer: some View {
        if let startTime, !reduceMotion {
            TimelineView(.animation) { context in
                let elapsed = context.date.timeIntervalSince(startTime)
                let progress = CGFloat(max(0, min(elapsed / maxDuration, 1.0)))
                Canvas { ctx, size in
                    drawRing(ctx, size: size, progress: progress)
                }
            }
        } else {
            Canvas { ctx, size in
                drawRing(ctx, size: size, progress: currentProgress)
            }
        }
    }

    private var currentProgress: CGFloat {
        guard let startTime else { return 0 }
        return CGFloat(max(0, min(Date.now.timeIntervalSince(startTime) / maxDuration, 1.0)))
    }

    // MARK: - Drawing

    private func drawRing(_ ctx: GraphicsContext, size: CGSize, progress: CGFloat) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2 - Self.lineWidth - 4
        let startAngle = Angle.degrees(-90)
        let fullEnd = Angle.degrees(270)

        // Background track
        let trackPath = Path { path in
            path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: fullEnd, clockwise: false)
        }
        ctx.stroke(
            trackPath,
            with: .color(MCColor.feeding.opacity(0.15)),
            style: StrokeStyle(lineWidth: Self.lineWidth)
        )

        guard progress > 0 else { return }

        // Progress arc
        let progressAngle = startAngle + .degrees(360 * Double(progress))
        let progressPath = Path { path in
            path.addArc(
                center: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: progressAngle,
                clockwise: false
            )
        }
        ctx.stroke(
            progressPath,
            with: .color(MCColor.feeding),
            style: StrokeStyle(lineWidth: Self.lineWidth, lineCap: .round)
        )

        // Tip glow: outer halo + solid dot at the arc endpoint
        let rad = progressAngle.radians
        let tipX = center.x + CGFloat(cos(rad)) * radius
        let tipY = center.y + CGFloat(sin(rad)) * radius
        let dotR = Self.lineWidth / 2
        let haloRect = CGRect(x: tipX - dotR - 5, y: tipY - dotR - 5, width: (dotR + 5) * 2, height: (dotR + 5) * 2)
        let dotRect = CGRect(x: tipX - dotR, y: tipY - dotR, width: dotR * 2, height: dotR * 2)
        ctx.fill(Path(ellipseIn: haloRect), with: .color(MCColor.feeding.opacity(0.25)))
        ctx.fill(Path(ellipseIn: dotRect), with: .color(MCColor.feeding))
    }

    // MARK: - Center Label

    private var timerLabel: some View {
        Text(timerText)
            .font(MCTypography.timer)
            .monospacedDigit()
            .foregroundStyle(.primary)
            .contentTransition(.numericText())
            .animation(reduceMotion ? nil : .default, value: timerText)
            .accessibilityLabel(Text("Timer"))
            .accessibilityValue(Text(timerText))
    }
}
