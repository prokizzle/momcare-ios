import ActivityKit
import SwiftUI
import WidgetKit

struct InProgressActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: InProgressActivityAttributes.self) { context in
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.attributes.activityIcon)
                        .font(.title2)
                        .foregroundStyle(.tint)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.attributes.babyName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(context.state.startTime, style: .timer)
                            .font(.system(.title, design: .rounded).monospacedDigit())
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let detail = context.state.detail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Button(intent: EndActivityIntent(activityType: context.attributes.activityType)) {
                        Text("End \(context.attributes.activityType.capitalized)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(.tint, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            } compactLeading: {
                Image(systemName: context.attributes.activityIcon)
                    .foregroundStyle(.tint)
            } compactTrailing: {
                Text(context.state.startTime, style: .timer)
                    .monospacedDigit()
                    .frame(width: 56)
            } minimal: {
                Image(systemName: context.attributes.activityIcon)
                    .foregroundStyle(.tint)
            }
        }
    }

    @ViewBuilder
    private func lockScreenView(
        context: ActivityViewContext<InProgressActivityAttributes>
    ) -> some View {
        HStack(spacing: 16) {
            Image(systemName: context.attributes.activityIcon)
                .font(.title)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.babyName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(context.state.startTime, style: .timer)
                    .font(.system(.title, design: .rounded).monospacedDigit())
                    .foregroundStyle(.primary)
                if let detail = context.state.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(intent: EndActivityIntent(activityType: context.attributes.activityType)) {
                Image(systemName: "stop.circle.fill")
                    .font(.title)
                    .foregroundStyle(.tint)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .activityBackgroundTint(.black.opacity(0.6))
    }
}
