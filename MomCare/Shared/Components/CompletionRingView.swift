import SwiftUI

@MainActor
struct CompletionRingView: View {
    let percentage: Double  // 0.0 – 1.0
    var size: CGFloat = 56
    var lineWidth: CGFloat = 5
    var color: Color = MCColor.selfCare

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clampedPercentage: Double {
        min(max(percentage, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: clampedPercentage)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 0.5),
                    value: clampedPercentage
                )
        }
        .frame(width: size, height: size)
        .accessibilityLabel(Text("Self-care completion"))
        .accessibilityValue(Text("\(Int(clampedPercentage * 100)) percent"))
    }
}

#Preview("50% complete") {
    CompletionRingView(percentage: 0.5)
        .padding()
}

#Preview("100% complete") {
    CompletionRingView(percentage: 1.0, color: .green)
        .padding()
}
