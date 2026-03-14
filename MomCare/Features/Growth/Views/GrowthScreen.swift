import Charts
import SwiftUI

@MainActor
struct GrowthScreen: View {
    let babyId: UUID
    let dateOfBirth: Date
    let biologicalSex: Baby.BiologicalSex?
    @Bindable var viewModel: GrowthViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: MCSpacing.xl) {
                measurementPicker
                chartSection
                percentileLabel
                addButton
                historySection
            }
            .padding(.horizontal, MCSpacing.lg)
            .padding(.vertical, MCSpacing.lg)
        }
        .navigationTitle("Growth")
        .task {
            await viewModel.loadRecords(babyId: babyId)
            viewModel.updateChartData(sex: biologicalSex, dateOfBirth: dateOfBirth)
        }
        .onChange(of: viewModel.selectedMeasurement) { _, _ in
            viewModel.updateChartData(sex: biologicalSex, dateOfBirth: dateOfBirth)
        }
        .onChange(of: viewModel.records) { _, _ in
            viewModel.updateChartData(sex: biologicalSex, dateOfBirth: dateOfBirth)
        }
        .sheet(isPresented: $viewModel.showAddSheet) {
            AddMeasurementView(babyId: babyId, viewModel: viewModel)
        }
    }

    // MARK: - Measurement Picker

    private var measurementPicker: some View {
        Picker("Measurement", selection: $viewModel.selectedMeasurement) {
            ForEach(GrowthChartService.MeasurementType.allCases, id: \.self) { type in
                Text(type.label).tag(type)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Chart

    @ViewBuilder
    private var chartSection: some View {
        if let chartData = viewModel.chartData, !chartData.percentileBands.isEmpty {
            Chart {
                // 3rd-97th percentile band (lightest)
                ForEach(chartData.percentileBands, id: \.month) { point in
                    AreaMark(
                        x: .value("Month", point.month),
                        yStart: .value("P3", displayValue(point.p3)),
                        yEnd: .value("P97", displayValue(point.p97))
                    )
                    .foregroundStyle(MCColor.accent.opacity(0.08))
                }

                // 15th-85th percentile band (medium)
                ForEach(chartData.percentileBands, id: \.month) { point in
                    AreaMark(
                        x: .value("Month", point.month),
                        yStart: .value("P15", displayValue(point.p15)),
                        yEnd: .value("P85", displayValue(point.p85))
                    )
                    .foregroundStyle(MCColor.accent.opacity(0.15))
                }

                // 50th percentile line (dashed)
                ForEach(chartData.percentileBands, id: \.month) { point in
                    LineMark(
                        x: .value("Month", point.month),
                        y: .value("P50", displayValue(point.p50))
                    )
                    .foregroundStyle(MCColor.accent.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }

                // Baby's data points
                ForEach(chartData.babyPoints, id: \.ageMonths) { point in
                    PointMark(
                        x: .value("Month", point.ageMonths),
                        y: .value("Value", displayValue(point.value))
                    )
                    .foregroundStyle(MCColor.accent)
                    .symbolSize(60)
                }

                // Baby's line connecting points
                ForEach(chartData.babyPoints, id: \.ageMonths) { point in
                    LineMark(
                        x: .value("Month", point.ageMonths),
                        y: .value("Value", displayValue(point.value))
                    )
                    .foregroundStyle(MCColor.accent)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
            .chartXAxisLabel("Age (months)")
            .chartYAxisLabel(yAxisLabel)
            .frame(height: 280)
            .accessibilityLabel(chartAccessibilityLabel)
        } else {
            emptyChartPlaceholder
        }
    }

    private var emptyChartPlaceholder: some View {
        VStack(spacing: MCSpacing.lg) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No measurements yet")
                .font(MCTypography.cardTitle)
                .foregroundStyle(.secondary)
            Text("Add your first measurement to see growth charts")
                .font(MCTypography.cardBody)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 280)
    }

    // MARK: - Percentile Label

    @ViewBuilder
    private var percentileLabel: some View {
        if let pct = viewModel.latestPercentile {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(MCColor.accent)
                Text("Latest: \(Int(pct))th percentile")
                    .font(MCTypography.cardTitle)
            }
            .padding(MCSpacing.md)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            MCHaptic.tap()
            viewModel.showAddSheet = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Measurement")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(MCColor.accent, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - History

    @ViewBuilder
    private var historySection: some View {
        if !viewModel.records.isEmpty {
            VStack(alignment: .leading, spacing: MCSpacing.md) {
                Text("History")
                    .font(MCTypography.cardTitle)

                ForEach(viewModel.records) { record in
                    HStack {
                        VStack(alignment: .leading, spacing: MCSpacing.xs) {
                            Text(record.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline.bold())
                            HStack(spacing: MCSpacing.md) {
                                if record.weightGrams != nil {
                                    Label(record.weightFormatted, systemImage: "scalemass.fill")
                                }
                                if record.lengthCm != nil {
                                    Label(record.lengthFormatted, systemImage: "ruler.fill")
                                }
                                if record.headCircumferenceCm != nil {
                                    Label(record.headCircumferenceFormatted, systemImage: "circle.dashed")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(MCSpacing.md)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    // MARK: - Helpers

    private func displayValue(_ value: Double) -> Double {
        switch viewModel.selectedMeasurement {
        case .weight:
            return Locale.current.measurementSystem == .metric ? value / 1000.0 : value / 453.592
        case .length, .headCircumference:
            return Locale.current.measurementSystem == .metric ? value : value / 2.54
        }
    }

    private var yAxisLabel: String {
        let isMetric = Locale.current.measurementSystem == .metric
        switch viewModel.selectedMeasurement {
        case .weight: return isMetric ? "kg" : "lbs"
        case .length: return isMetric ? "cm" : "in"
        case .headCircumference: return isMetric ? "cm" : "in"
        }
    }

    private var chartAccessibilityLabel: String {
        if let pct = viewModel.latestPercentile {
            "\(viewModel.selectedMeasurement.label) chart showing baby at \(Int(pct))th percentile"
        } else {
            "\(viewModel.selectedMeasurement.label) growth chart"
        }
    }
}
