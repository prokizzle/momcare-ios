import Charts
import SwiftUI

// MARK: - Supporting Types

private struct ReferenceRow {
    let month: Int
    let pct3: Double
    let pct50: Double
    let pct97: Double
}

private struct ReferencePoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let percentile: String
}

// MARK: - View

/// Growth chart section rendered inside GrowthReportView.
/// Weight and length use separate charts because their Y-axis scales
/// are incompatible (grams vs centimetres). Each chart overlays WHO 2006
/// P3/P50/P97 reference curves anchored to baby.dateOfBirth.
/// Sex-specific tables are used when biologicalSex is known; a combined-sex
/// approximation is used as a fallback when sex is nil.
struct GrowthReportChartSection: View {
    let baby: Baby
    let records: [GrowthRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Growth Chart")
                .font(.system(size: 16, weight: .semibold)) // Fixed size for PDF layout

            let sorted = records.sorted { $0.date < $1.date }
            let hasWeight = sorted.contains { $0.weightGrams != nil }
            let hasLength = sorted.contains { $0.lengthCm != nil }

            if hasWeight {
                Text("Weight (dashed = WHO P3/P50/P97 \(sexLabel))")
                    .font(.system(size: 11)) // Fixed size for PDF layout
                    .foregroundStyle(.secondary)

                Chart {
                    // Group by percentile so Swift Charts draws continuous lines.
                    ForEach(["P3", "P50", "P97"], id: \.self) { percentile in
                        ForEach(weightReferencePoints.filter { $0.percentile == percentile }) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Weight (g)", point.value),
                                series: .value("Percentile", percentile)
                            )
                            .foregroundStyle(Color.gray.opacity(0.4))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 2]))
                        }
                    }
                    ForEach(sorted) { record in
                        if let grams = record.weightGrams {
                            LineMark(
                                x: .value("Date", record.date),
                                y: .value("Weight (g)", grams),
                                series: .value("Series", "Baby")
                            )
                            .foregroundStyle(Color.black)
                            .symbol(.circle)
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Date", record.date),
                                y: .value("Weight (g)", grams)
                            )
                            .foregroundStyle(Color.black)
                            .symbolSize(30)
                        }
                    }
                }
                .frame(height: 140)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            }

            if hasLength {
                Text("Length (dashed = WHO P3/P50/P97 \(sexLabel))")
                    .font(.system(size: 11)) // Fixed size for PDF layout
                    .foregroundStyle(.secondary)

                Chart {
                    // Group by percentile so Swift Charts draws continuous lines.
                    ForEach(["P3", "P50", "P97"], id: \.self) { percentile in
                        ForEach(lengthReferencePoints.filter { $0.percentile == percentile }) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Length (cm)", point.value),
                                series: .value("Percentile", percentile)
                            )
                            .foregroundStyle(Color.gray.opacity(0.4))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 2]))
                        }
                    }
                    ForEach(sorted) { record in
                        if let lengthCm = record.lengthCm {
                            LineMark(
                                x: .value("Date", record.date),
                                y: .value("Length (cm)", lengthCm),
                                series: .value("Series", "Baby")
                            )
                            .foregroundStyle(Color.gray)
                            .symbol(.square)
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Date", record.date),
                                y: .value("Length (cm)", lengthCm)
                            )
                            .foregroundStyle(Color.gray)
                            .symbolSize(30)
                        }
                    }
                }
                .frame(height: 140)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    /// Human-readable sex qualifier used in chart subtitles.
    private var sexLabel: String {
        switch baby.biologicalSex {
        case .male: return "(male)"
        case .female: return "(female)"
        case .other, .preferNotToSay, nil: return "(approx., combined M/F)"
        }
    }

    // MARK: - WHO 2006 Reference Curves

    private var weightReferencePoints: [ReferencePoint] {
        let table: [ReferenceRow]
        switch baby.biologicalSex {
        case .male:                          table = weightTableMale
        case .female:                        table = weightTableFemale
        case .other, .preferNotToSay, nil:   table = weightTableCombined
        }
        return referencePoints(from: table)
    }

    private var lengthReferencePoints: [ReferencePoint] {
        let table: [ReferenceRow]
        switch baby.biologicalSex {
        case .male:                          table = lengthTableMale
        case .female:                        table = lengthTableFemale
        case .other, .preferNotToSay, nil:   table = lengthTableCombined
        }
        return referencePoints(from: table)
    }

    // MARK: Weight tables (WHO 2006, grams)

    private var weightTableMale: [ReferenceRow] {[
        ReferenceRow(month: 0, pct3: 2500, pct50: 3300, pct97: 4300),
        ReferenceRow(month: 1, pct3: 3400, pct50: 4500, pct97: 5700),
        ReferenceRow(month: 3, pct3: 5000, pct50: 6400, pct97: 7900),
        ReferenceRow(month: 6, pct3: 6400, pct50: 7900, pct97: 9800),
        ReferenceRow(month: 9, pct3: 7200, pct50: 9000, pct97: 11000),
        ReferenceRow(month: 12, pct3: 7700, pct50: 9600, pct97: 11800),
        ReferenceRow(month: 18, pct3: 8800, pct50: 10900, pct97: 13700),
        ReferenceRow(month: 24, pct3: 9800, pct50: 12200, pct97: 15300)
    ]}

    private var weightTableFemale: [ReferenceRow] {[
        ReferenceRow(month: 0, pct3: 2400, pct50: 3200, pct97: 4200),
        ReferenceRow(month: 1, pct3: 3200, pct50: 4200, pct97: 5500),
        ReferenceRow(month: 3, pct3: 4800, pct50: 6100, pct97: 7600),
        ReferenceRow(month: 6, pct3: 5700, pct50: 7300, pct97: 9300),
        ReferenceRow(month: 9, pct3: 6500, pct50: 8400, pct97: 10600),
        ReferenceRow(month: 12, pct3: 7000, pct50: 8900, pct97: 11500),
        ReferenceRow(month: 18, pct3: 7900, pct50: 10200, pct97: 13200),
        ReferenceRow(month: 24, pct3: 8700, pct50: 11500, pct97: 14800)
    ]}

    /// Combined-sex fallback when biologicalSex is unknown.
    private var weightTableCombined: [ReferenceRow] {[
        ReferenceRow(month: 0, pct3: 2500, pct50: 3300, pct97: 4200),
        ReferenceRow(month: 1, pct3: 3400, pct50: 4500, pct97: 5700),
        ReferenceRow(month: 3, pct3: 5100, pct50: 6400, pct97: 7900),
        ReferenceRow(month: 6, pct3: 6400, pct50: 7900, pct97: 9800),
        ReferenceRow(month: 9, pct3: 7200, pct50: 9000, pct97: 11100),
        ReferenceRow(month: 12, pct3: 7800, pct50: 9600, pct97: 11900),
        ReferenceRow(month: 18, pct3: 8800, pct50: 10900, pct97: 13700),
        ReferenceRow(month: 24, pct3: 9700, pct50: 12000, pct97: 15300)
    ]}

    // MARK: Length tables (WHO 2006, cm)

    private var lengthTableMale: [ReferenceRow] {[
        ReferenceRow(month: 0, pct3: 46.3, pct50: 49.9, pct97: 53.4),
        ReferenceRow(month: 3, pct3: 58.0, pct50: 61.4, pct97: 64.9),
        ReferenceRow(month: 6, pct3: 64.0, pct50: 67.6, pct97: 71.3),
        ReferenceRow(month: 9, pct3: 68.4, pct50: 72.0, pct97: 75.7),
        ReferenceRow(month: 12, pct3: 71.7, pct50: 75.7, pct97: 79.8),
        ReferenceRow(month: 18, pct3: 76.9, pct50: 82.3, pct97: 87.7),
        ReferenceRow(month: 24, pct3: 82.3, pct50: 87.8, pct97: 93.3)
    ]}

    private var lengthTableFemale: [ReferenceRow] {[
        ReferenceRow(month: 0, pct3: 45.6, pct50: 49.1, pct97: 52.9),
        ReferenceRow(month: 3, pct3: 56.9, pct50: 60.6, pct97: 64.3),
        ReferenceRow(month: 6, pct3: 62.5, pct50: 65.7, pct97: 69.8),
        ReferenceRow(month: 9, pct3: 66.9, pct50: 70.1, pct97: 75.0),
        ReferenceRow(month: 12, pct3: 70.3, pct50: 74.0, pct97: 79.2),
        ReferenceRow(month: 18, pct3: 75.6, pct50: 80.7, pct97: 86.4),
        ReferenceRow(month: 24, pct3: 80.0, pct50: 86.4, pct97: 93.1)
    ]}

    /// Combined-sex fallback when biologicalSex is unknown.
    private var lengthTableCombined: [ReferenceRow] {[
        ReferenceRow(month: 0, pct3: 46.1, pct50: 49.9, pct97: 53.7),
        ReferenceRow(month: 3, pct3: 57.3, pct50: 61.4, pct97: 65.5),
        ReferenceRow(month: 6, pct3: 63.3, pct50: 67.6, pct97: 71.9),
        ReferenceRow(month: 9, pct3: 67.5, pct50: 72.0, pct97: 76.5),
        ReferenceRow(month: 12, pct3: 71.0, pct50: 75.7, pct97: 80.5),
        ReferenceRow(month: 18, pct3: 76.0, pct50: 82.3, pct97: 88.5),
        ReferenceRow(month: 24, pct3: 81.0, pct50: 87.8, pct97: 94.6)
    ]}

    // MARK: - Reference Point Calculation

    /// Builds `ReferencePoint` values from a table, trimmed to the window
    /// of the baby's actual records plus a 3-month lookahead. Deriving the
    /// window from the latest record date (rather than the baby's current age)
    /// keeps the export chart appropriately scoped when the report covers a
    /// short date range.
    private func referencePoints(from table: [ReferenceRow]) -> [ReferencePoint] {
        let lastRecordDate = records.map(\.date).max() ?? .now
        let monthsFromBirth = Calendar.current.dateComponents(
            [.month], from: baby.dateOfBirth, to: lastRecordDate
        ).month ?? 0
        let maxMonths = min(max(monthsFromBirth, 0) + 3, 24)
        return table.filter { $0.month <= maxMonths }.flatMap { row -> [ReferencePoint] in
            guard let date = Calendar.current.date(
                byAdding: .month,
                value: row.month,
                to: baby.dateOfBirth
            ) else { return [] }
            return [
                ReferencePoint(date: date, value: row.pct3, percentile: "P3"),
                ReferencePoint(date: date, value: row.pct50, percentile: "P50"),
                ReferencePoint(date: date, value: row.pct97, percentile: "P97")
            ]
        }
    }
}
