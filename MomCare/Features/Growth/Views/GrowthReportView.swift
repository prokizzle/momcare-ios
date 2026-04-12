import SwiftUI

/// A print-ready SwiftUI view used as the source for PDF rendering.
/// Always uses a light color scheme regardless of app appearance.
struct GrowthReportView: View {
    let baby: Baby
    let records: [GrowthRecord]
    let events: [HealthEvent]
    let dateRange: ClosedRange<Date>
    let feedings: [Feeding]

    init(
        baby: Baby,
        records: [GrowthRecord],
        events: [HealthEvent],
        dateRange: ClosedRange<Date>,
        feedings: [Feeding] = []
    ) {
        self.baby = baby
        self.records = records
        self.events = events
        self.dateRange = dateRange
        self.feedings = feedings
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            Divider().padding(.vertical, 16)

            if !records.isEmpty {
                GrowthReportChartSection(baby: baby, records: records)
                Divider().padding(.vertical, 16)
                growthSection
                Divider().padding(.vertical, 16)
            }

            if !feedings.isEmpty {
                GrowthReportFeedingSection(feedings: feedings, dateRange: dateRange)
                Divider().padding(.vertical, 16)
            }

            if !events.isEmpty {
                healthEventsSection
                Divider().padding(.vertical, 16)
            }

            if records.isEmpty && feedings.isEmpty && events.isEmpty {
                emptyState
            }

            Spacer(minLength: 0)
            footerSection
        }
        .padding(36)
        .background(Color.white)
        .foregroundStyle(Color.black)
        .colorScheme(.light)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Growth Report")
                        .font(.system(size: 24, weight: .bold)) // Fixed size for PDF layout
                    Text(baby.name)
                        .font(.system(size: 18, weight: .semibold)) // Fixed size for PDF layout
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 40)) // Fixed size for PDF layout
                    .foregroundStyle(.pink.opacity(0.7))
                    .accessibilityHidden(true)
            }

            HStack(spacing: 16) {
                Label(
                    "DOB: \(baby.dateOfBirth.formatted(date: .abbreviated, time: .omitted))",
                    systemImage: "calendar"
                )
                Label("Age: \(baby.ageString)", systemImage: "person.fill")
            }
            .font(.system(size: 13)) // Fixed size for PDF layout
            .foregroundStyle(.secondary)

            Text(dateRangeLabel)
                .font(.system(size: 12)) // Fixed size for PDF layout
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
        }
    }

    // MARK: - Growth Measurements

    private var growthSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Growth Measurements")
                .font(.system(size: 16, weight: .semibold)) // Fixed size for PDF layout

            HStack {
                Text("Date")
                    .frame(width: 110, alignment: .leading)
                Text("Weight")
                    .frame(width: 90, alignment: .trailing)
                Text("Length")
                    .frame(width: 90, alignment: .trailing)
                Text("Head Circ.")
                    .frame(width: 90, alignment: .trailing)
                Spacer()
                Text("Notes")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.system(size: 11, weight: .semibold)) // Fixed size for PDF layout
            .foregroundStyle(.secondary)
            .padding(.bottom, 4)

            Divider()

            ForEach(records.sorted { $0.date < $1.date }) { record in
                HStack {
                    Text(record.date.formatted(date: .abbreviated, time: .omitted))
                        .frame(width: 110, alignment: .leading)
                    Text(record.weightFormatted)
                        .frame(width: 90, alignment: .trailing)
                    Text(record.lengthFormatted)
                        .frame(width: 90, alignment: .trailing)
                    Text(record.headCircumferenceFormatted)
                        .frame(width: 90, alignment: .trailing)
                    Spacer()
                    Text(record.notes ?? "")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.secondary)
                }
                .font(.system(size: 12)) // Fixed size for PDF layout
                .padding(.vertical, 3)

                Divider()
                    .opacity(0.5)
            }
        }
    }

    // MARK: - Health Events

    private var healthEventsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Health Events")
                .font(.system(size: 16, weight: .semibold)) // Fixed size for PDF layout

            ForEach(events.sorted { $0.date < $1.date }) { event in
                HStack(alignment: .top, spacing: 10) {
                    Text(event.date.formatted(date: .abbreviated, time: .omitted))
                        .frame(width: 110, alignment: .leading)
                        .foregroundStyle(.secondary)
                    Text("[\(event.eventType.label)]")
                        .frame(width: 90, alignment: .leading)
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title)
                            .fontWeight(.medium)
                        if let notes = event.notes, !notes.isEmpty {
                            Text(notes)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .font(.system(size: 12)) // Fixed size for PDF layout
                .padding(.vertical, 3)

                Divider()
                    .opacity(0.5)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        Text("No records in the selected date range.")
            .font(.system(size: 13)) // Fixed size for PDF layout
            .foregroundStyle(.secondary)
            .padding(.vertical, 20)
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Text("Generated by MomCare")
            Spacer()
            Text(Date.now.formatted(date: .abbreviated, time: .shortened))
        }
        .font(.system(size: 10)) // Fixed size for PDF layout
        .foregroundStyle(.tertiary)
        .padding(.top, 16)
    }

    // MARK: - Helpers

    private var dateRangeLabel: String {
        let start = dateRange.lowerBound.formatted(date: .abbreviated, time: .omitted)
        let end = dateRange.upperBound.formatted(date: .abbreviated, time: .omitted)
        return "Report period: \(start) – \(end)"
    }
}

#Preview {
    GrowthReportView(
        baby: .fixture(),
        records: [
            .fixture(weightGrams: 3200, lengthCm: 49, headCircumferenceCm: 33),
            .fixture(
                date: Calendar.current.date(byAdding: .month, value: -1, to: .now)!,
                weightGrams: 4500,
                lengthCm: 54
            )
        ],
        events: [
            .fixture(eventType: .vaccine, title: "DTaP - Dose 1"),
            .fixture(eventType: .milestone, title: "First smile")
        ],
        dateRange: Calendar.current.date(byAdding: .month, value: -3, to: .now)!...Date.now,
        feedings: [
            .fixture(feedingType: .breast),
            .fixture(feedingType: .bottle),
            .fixture(feedingType: .breast)
        ]
    )
}
