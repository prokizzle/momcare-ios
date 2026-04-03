import SwiftUI

// MARK: - Supporting Types

private struct FeedingTypeEntry {
    let feedingType: Feeding.FeedingType
    let count: Int
    let percent: Int
}

private struct FeedingStats {
    let totalCount: Int
    let perDay: Double
    let avgDurationMinutes: Double?
    let typeEntries: [FeedingTypeEntry]
}

// MARK: - View

/// Feeding summary section rendered inside GrowthReportView.
struct GrowthReportFeedingSection: View {
    let feedings: [Feeding]
    let dateRange: ClosedRange<Date>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Feeding Summary")
                .font(.system(size: 16, weight: .semibold))

            let stats = feedingStats

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(stats.totalCount)")
                        .font(.system(size: 18, weight: .bold))
                    Text("Total")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.1f", stats.perDay))
                        .font(.system(size: 18, weight: .bold))
                    Text("Per day")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                if let avgMinutes = stats.avgDurationMinutes {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int(avgMinutes)) min")
                            .font(.system(size: 18, weight: .bold))
                        Text("Avg duration")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)

            Divider()

            HStack {
                Text("Type")
                    .frame(width: 110, alignment: .leading)
                Text("Count")
                    .frame(width: 60, alignment: .trailing)
                Text("Share")
                    .frame(width: 60, alignment: .trailing)
                Spacer()
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)

            ForEach(stats.typeEntries.indices, id: \.self) { idx in
                let entry = stats.typeEntries[idx]
                HStack {
                    Text(entry.feedingType.label)
                        .frame(width: 110, alignment: .leading)
                    Text("\(entry.count)")
                        .frame(width: 60, alignment: .trailing)
                    Text("\(entry.percent)%")
                        .frame(width: 60, alignment: .trailing)
                    Spacer()
                }
                .font(.system(size: 12))
                .padding(.vertical, 2)

                Divider()
                    .opacity(0.5)
            }
        }
    }

    // MARK: - Statistics

    private var feedingStats: FeedingStats {
        let total = feedings.count
        let dayComponents = Calendar.current.dateComponents(
            [.day],
            from: dateRange.lowerBound,
            to: dateRange.upperBound
        )
        let days = max(1, dayComponents.day ?? 1)
        let perDay = Double(total) / Double(days)

        var typeCounts: [Feeding.FeedingType: Int] = [:]
        for feeding in feedings {
            typeCounts[feeding.feedingType, default: 0] += 1
        }
        let typeEntries = typeCounts
            .sorted { $0.value > $1.value }
            .map { key, value in
                FeedingTypeEntry(
                    feedingType: key,
                    count: value,
                    percent: total > 0 ? value * 100 / total : 0
                )
            }

        let timedDurations = feedings.compactMap { feeding -> Double? in
            guard feeding.endTime != nil else { return nil }
            return feeding.duration / 60.0
        }
        let avgDuration: Double? = timedDurations.isEmpty
            ? nil
            : timedDurations.reduce(0, +) / Double(timedDurations.count)

        return FeedingStats(
            totalCount: total,
            perDay: perDay,
            avgDurationMinutes: avgDuration,
            typeEntries: typeEntries
        )
    }
}
