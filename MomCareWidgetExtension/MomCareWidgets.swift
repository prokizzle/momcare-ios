import ActivityKit
import SwiftUI
import WidgetKit

struct FeedingTimerEntry: TimelineEntry {
    let date: Date
    let lastFeedingTime: Date?
    let isFeeding: Bool
}

struct FeedingTimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> FeedingTimerEntry {
        FeedingTimerEntry(date: .now, lastFeedingTime: .now, isFeeding: false)
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (FeedingTimerEntry) -> Void) {
        completion(FeedingTimerEntry(date: .now, lastFeedingTime: .now, isFeeding: false))
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<FeedingTimerEntry>) -> Void) {
        let entry = FeedingTimerEntry(date: .now, lastFeedingTime: .now, isFeeding: false)
        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(15 * 60)))
        completion(timeline)
    }
}

struct FeedingTimerWidgetView: View {
    var entry: FeedingTimerEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Feeding", systemImage: "drop.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if let lastTime = entry.lastFeedingTime {
                Text(lastTime, style: .relative)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .contentTransition(.numericText())

                Text("since last feed")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("No feeds yet")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

@main
struct MomCareWidgets: WidgetBundle {
    var body: some Widget {
        FeedingTimerWidget()
        InProgressActivityLiveActivity()
    }
}

struct FeedingTimerWidget: Widget {
    let kind = "FeedingTimerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FeedingTimerProvider()) { entry in
            FeedingTimerWidgetView(entry: entry)
        }
        .configurationDisplayName("Feeding Timer")
        .description("See how long since the last feeding.")
        .supportedFamilies([.systemSmall])
    }
}
