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
/// approximate P3/P50/P97 reference curves anchored to baby.dateOfBirth.
struct GrowthReportChartSection: View {
    let baby: Baby
    let records: [GrowthRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Growth Chart")
                .font(.system(size: 16, weight: .semibold))

            let sorted = records.sorted { $0.date < $1.date }
            let hasWeight = sorted.contains { $0.weightGrams != nil }
            let hasLength = sorted.contains { $0.lengthCm != nil }

            if hasWeight {
                Text("Weight (dashed = WHO P3/P50/P97)")
                    .font(.system(size: 11))
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
                Text("Length (dashed = WHO P3/P50/P97)")
                    .font(.system(size: 11))
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

    // MARK: - WHO 2006 Reference Curves

    private var weightReferencePoints: [ReferencePoint] {
        // WHO 2006 weight-for-age in grams (approximate, combined M/F).
        let table: [ReferenceRow] = [
            ReferenceRow(month: 0, pct3: 2500, pct50: 3300, pct97: 4200),
            ReferenceRow(month: 1, pct3: 3400, pct50: 4500, pct97: 5700),
            ReferenceRow(month: 3, pct3: 5100, pct50: 6400, pct97: 7900),
            ReferenceRow(month: 6, pct3: 6400, pct50: 7900, pct97: 9800),
            ReferenceRow(month: 9, pct3: 7200, pct50: 9000, pct97: 11100),
            ReferenceRow(month: 12, pct3: 7800, pct50: 9600, pct97: 11900),
            ReferenceRow(month: 18, pct3: 8800, pct50: 10900, pct97: 13700),
            ReferenceRow(month: 24, pct3: 9700, pct50: 12000, pct97: 15300)
        ]
        return referencePoints(from: table)
    }

    private var lengthReferencePoints: [ReferencePoint] {
        // WHO 2006 length-for-age in cm (approximate, combined M/F).
        let table: [ReferenceRow] = [
            ReferenceRow(month: 0, pct3: 46.1, pct50: 49.9, pct97: 53.7),
            ReferenceRow(month: 3, pct3: 57.3, pct50: 61.4, pct97: 65.5),
            ReferenceRow(month: 6, pct3: 63.3, pct50: 67.6, pct97: 71.9),
            ReferenceRow(month: 9, pct3: 67.5, pct50: 72.0, pct97: 76.5),
            ReferenceRow(month: 12, pct3: 71.0, pct50: 75.7, pct97: 80.5),
            ReferenceRow(month: 18, pct3: 76.0, pct50: 82.3, pct97: 88.5),
            ReferenceRow(month: 24, pct3: 81.0, pct50: 87.8, pct97: 94.6)
        ]
        return referencePoints(from: table)
    }

    private func referencePoints(from table: [ReferenceRow]) -> [ReferencePoint] {
        let maxMonths = min(baby.ageInMonths + 3, 24)
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
