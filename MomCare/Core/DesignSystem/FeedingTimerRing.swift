import SwiftUI

/// Canvas-drawn radial progress ring for the feeding timer screen.
///
/// Drives its own TimelineView(.animation) so the arc updates at 60fps even though
/// the ViewModel ticks the formatted string only once per second.
@MainActor
struct FeedingTimerRing: View {
    let startTime: Date?
    let timerText: String

    private static let maxDuration: TimeInterval = 45 * 60  // 45-minute reference cycle
    private static let ringSize: CGFloat = 220
    private static let lineWidth: CGFloat = 8

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            ringLayer
            timerLabel
        }
        .frame(width: Self.ringSize, height: Self.ringSize)
    }

    // MARK: - Ring Layer

    @ViewBuilder
    private var ringLayer: some View {
        if reduceMotion {
            Canvas { ctx, size in
                drawRing(ctx, size: size, progress: currentProgress)
            }
        } else {
            TimelineView(.animation) { context in
                let elapsed = startTime.map { context.date.timeIntervalSince($0) } ?? 0
                let progress = CGFloat(min(elapsed / Self.maxDuration, 1.0))
                Canvas { ctx, size in
                    drawRing(ctx, size: size, progress: progress)
                }
            }
        }
    }

    private var currentProgress: CGFloat {
        guard let startTime else { return 0 }
        return CGFloat(min(Date.now.timeIntervalSince(startTime) / Self.maxDuration, 1.0))
    }

    // MARK: - Drawing

    private func drawRing(_ ctx: GraphicsContext, size: CGSize, progress: CGFloat) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2 - Self.lineWidth - 4
        let startAngle = Angle.degrees(-90)
        let fullEnd = Angle.degrees(270)

        // Background track
        let trackPath = Path { p in
            p.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: fullEnd, clockwise: false)
        }
        ctx.stroke(
            trackPath,
            with: .color(MCColor.feeding.opacity(0.15)),
            style: StrokeStyle(lineWidth: Self.lineWidth)
        )

        guard progress > 0 else { return }

        // Progress arc
        let progressAngle = startAngle + .degrees(360 * Double(progress))
        let progressPath = Path { p in
            p.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: progressAngle, clockwise: false)
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
            .foregroundStyle(.white)
            .contentTransition(.numericText())
            .animation(reduceMotion ? nil : .default, value: timerText)
            .accessibilityLabel("Timer: \(timerText)")
    }
}
