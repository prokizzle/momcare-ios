import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Next Action

enum NextAction {
    case feedingInProgress(startTime: Date, detail: String?)
    case napInProgress(startTime: Date)
    case timeToFeed(lastFeedTime: Date)
    case vaccineDue(name: String, ageMonths: Int)
    case selfCareItem(name: String, icon: String, lastDoneDescription: String)
    case allGood(lastFeedTime: Date?)

    var icon: String {
        switch self {
        case .feedingInProgress: "drop.fill"
        case .napInProgress: "moon.fill"
        case .timeToFeed: "drop.fill"
        case .vaccineDue: "syringe.fill"
        case .selfCareItem(_, let icon, _): icon
        case .allGood: "checkmark.circle.fill"
        }
    }

    var title: String {
        switch self {
        case .feedingInProgress(_, let detail):
            detail != nil ? "Feeding: \(detail!)" : "Feeding in progress"
        case .napInProgress: "Nap in progress"
        case .timeToFeed: "Time to feed"
        case .vaccineDue(let name, _): name
        case .selfCareItem(let name, _, _): name
        case .allGood: "All good"
        }
    }

    var subtitle: String {
        switch self {
        case .feedingInProgress: "Timer running"
        case .napInProgress: "Sleeping now"
        case .timeToFeed(let lastFeedTime):
            "Last fed \(lastFeedTime.formatted(.relative(presentation: .named)))"
        case .vaccineDue(_, let ageMonths): "Due at \(ageMonths) months"
        case .selfCareItem(_, _, let desc): desc
        case .allGood(let lastFeedTime):
            if let lastFeedTime {
                "Fed \(lastFeedTime.formatted(.relative(presentation: .named)))"
            } else {
                "Nothing needs attention"
            }
        }
    }

    var tintColor: Color {
        switch self {
        case .feedingInProgress: .blue
        case .napInProgress: .indigo
        case .timeToFeed: .orange
        case .vaccineDue: .red
        case .selfCareItem: .mint
        case .allGood: .green
        }
    }

    var isTimerActive: Bool {
        switch self {
        case .feedingInProgress, .napInProgress: true
        default: false
        }
    }

    var timerStartTime: Date? {
        switch self {
        case .feedingInProgress(let startTime, _): startTime
        case .napInProgress(let startTime): startTime
        default: nil
        }
    }
}

// MARK: - Timeline Entry & Provider

struct NextActionEntry: TimelineEntry {
    let date: Date
    let action: NextAction
    let secondaryActions: [NextAction]
}

struct NextActionProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextActionEntry {
        NextActionEntry(
            date: .now,
            action: .allGood(lastFeedTime: .now.addingTimeInterval(-3600)),
            secondaryActions: []
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping @Sendable (NextActionEntry) -> Void
    ) {
        let action = determineNextAction()
        let secondary = determineSecondaryActions(excluding: action)
        completion(NextActionEntry(date: .now, action: action, secondaryActions: secondary))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping @Sendable (Timeline<NextActionEntry>) -> Void
    ) {
        let action = determineNextAction()
        let secondary = determineSecondaryActions(excluding: action)
        let entry = NextActionEntry(date: .now, action: action, secondaryActions: secondary)
        let refreshDate: Date = if action.isTimerActive {
            .now.addingTimeInterval(60)
        } else {
            .now.addingTimeInterval(15 * 60)
        }
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    private func determineNextAction() -> NextAction {
        if SharedDataManager.isFeedingInProgress,
           let startTime = SharedDataManager.feedingStartTime {
            return .feedingInProgress(startTime: startTime, detail: SharedDataManager.feedingDetail)
        }
        if SharedDataManager.isNapInProgress,
           let startTime = SharedDataManager.napStartTime {
            return .napInProgress(startTime: startTime)
        }
        if let lastFeedingTime = SharedDataManager.lastFeedingTime,
           Date.now.timeIntervalSince(lastFeedingTime) > 3 * 3600 {
            return .timeToFeed(lastFeedTime: lastFeedingTime)
        }
        if let vaccineName = SharedDataManager.nextVaccineName,
           let ageMonths = SharedDataManager.nextVaccineAgeMonths {
            return .vaccineDue(name: vaccineName, ageMonths: ageMonths)
        }
        if let item = oldestUndoneSelfCareItem() {
            return .selfCareItem(
                name: item.name, icon: item.icon,
                lastDoneDescription: lastDoneDescription(for: item)
            )
        }
        return .allGood(lastFeedTime: SharedDataManager.lastFeedingTime)
    }

    private func determineSecondaryActions(excluding primary: NextAction) -> [NextAction] {
        var actions: [NextAction] = []
        if !primary.isTimerActive {
            if SharedDataManager.isFeedingInProgress,
               let startTime = SharedDataManager.feedingStartTime {
                actions.append(.feedingInProgress(
                    startTime: startTime, detail: SharedDataManager.feedingDetail
                ))
            }
            if SharedDataManager.isNapInProgress,
               let startTime = SharedDataManager.napStartTime {
                actions.append(.napInProgress(startTime: startTime))
            }
        }
        if case .timeToFeed = primary {} else if let last = SharedDataManager.lastFeedingTime,
           Date.now.timeIntervalSince(last) > 3 * 3600 {
            actions.append(.timeToFeed(lastFeedTime: last))
        }
        if case .vaccineDue = primary {} else if let name = SharedDataManager.nextVaccineName,
           let months = SharedDataManager.nextVaccineAgeMonths {
            actions.append(.vaccineDue(name: name, ageMonths: months))
        }
        if case .selfCareItem = primary {} else if let item = oldestUndoneSelfCareItem() {
            actions.append(.selfCareItem(
                name: item.name, icon: item.icon,
                lastDoneDescription: lastDoneDescription(for: item)
            ))
        }
        return Array(actions.prefix(2))
    }

    private func oldestUndoneSelfCareItem() -> SharedSelfCareItem? {
        SharedDataManager.selfCareItems.filter { !$0.isDone }
            .sorted { lhs, rhs in
                switch (lhs.lastDoneDate, rhs.lastDoneDate) {
                case (nil, nil): return false
                case (nil, _): return true
                case (_, nil): return false
                case (let left?, let right?): return left < right
                }
            }.first
    }

    private func lastDoneDescription(for item: SharedSelfCareItem) -> String {
        guard let lastDone = item.lastDoneDate else { return "Not done today" }
        let calendar = Calendar.current
        if calendar.isDateInToday(lastDone) { return "Not done today" }
        let days = calendar.dateComponents([.day], from: lastDone, to: .now).day ?? 0
        if days == 1 { return "Last done yesterday" }
        return "Last done \(days) days ago"
    }
}

// MARK: - Widget Views

struct SmallNextActionView: View {
    let entry: NextActionEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: entry.action.icon)
                .font(.title2)
                .foregroundStyle(entry.action.tintColor)
            Text(entry.action.title)
                .font(.custom("Nunito-SemiBold", size: 15))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            if let startTime = entry.action.timerStartTime {
                Text(startTime, style: .timer)
                    .font(.caption).foregroundStyle(.secondary).monospacedDigit()
            } else {
                Text(entry.action.subtitle)
                    .font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct MediumNextActionView: View {
    let entry: NextActionEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: entry.action.icon)
                    .font(.title2)
                    .foregroundStyle(entry.action.tintColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.action.title)
                        .font(.custom("Nunito-SemiBold", size: 15))
                        .lineLimit(1)
                    if let startTime = entry.action.timerStartTime {
                        Text(startTime, style: .timer)
                            .font(.caption).foregroundStyle(.secondary).monospacedDigit()
                    } else {
                        Text(entry.action.subtitle)
                            .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                Spacer()
            }
            if !entry.secondaryActions.isEmpty {
                Divider()
                HStack(spacing: 16) {
                    ForEach(
                        Array(entry.secondaryActions.enumerated()), id: \.offset
                    ) { _, action in
                        HStack(spacing: 4) {
                            Image(systemName: action.icon)
                                .font(.caption).foregroundStyle(action.tintColor)
                            Text(action.title)
                                .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        }
                    }
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct NextActionEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: NextActionEntry

    var body: some View {
        switch family {
        case .systemMedium: MediumNextActionView(entry: entry)
        default: SmallNextActionView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration & Bundle

struct NextActionWidget: Widget {
    let kind = "NextActionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextActionProvider()) { entry in
            NextActionEntryView(entry: entry)
        }
        .configurationDisplayName("Next Action")
        .description("See what needs your attention right now.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct MomCareWidgets: WidgetBundle {
    var body: some Widget {
        NextActionWidget()
        InProgressActivityLiveActivity()
    }
}
