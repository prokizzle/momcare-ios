import Charts
import SwiftUI

@MainActor
struct GrowthScreen: View {
    let babyId: UUID
    let dateOfBirth: Date
    let biologicalSex: Baby.BiologicalSex?
    let baby: Baby
    let healthEvents: [HealthEvent]
    @Bindable var viewModel: GrowthViewModel

    @State private var showExport = false

    var body: some View {
        ScrollView {
            VStack(spacing: MCSpacing.xl) {
                measurementPicker
                measurementHero
                chartSection
                addButton
                historySection
            }
            .padding(.horizontal, MCSpacing.lg)
            .padding(.vertical, MCSpacing.lg)
        }
        .navigationTitle("Growth")
        .ambientBackground()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    MCHaptic.tap()
                    showExport = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Export growth report")
            }
        }
        .sheet(isPresented: $showExport) {
            ExportSheet(
                baby: baby,
                records: viewModel.records,
                events: healthEvents,
                feedings: viewModel.feedings
            )
        }
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
            AddMeasurementView(babyId: babyId, dateOfBirth: dateOfBirth, viewModel: viewModel)
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
                    .foregroundStyle(MCColor.accent.opacity(MCOpacity.whisper))
                }

                // 15th-85th percentile band (medium)
                ForEach(chartData.percentileBands, id: \.month) { point in
                    AreaMark(
                        x: .value("Month", point.month),
                        yStart: .value("P15", displayValue(point.p15)),
                        yEnd: .value("P85", displayValue(point.p85))
                    )
                    .foregroundStyle(MCColor.accent.opacity(MCOpacity.medium))
                }

                // 50th percentile line (dashed)
                ForEach(chartData.percentileBands, id: \.month) { point in
                    LineMark(
                        x: .value("Month", point.month),
                        y: .value("P50", displayValue(point.p50))
                    )
                    .foregroundStyle(MCColor.accent.opacity(MCOpacity.strong))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }

                // Baby's data points
                ForEach(chartData.babyPoints) { point in
                    PointMark(
                        x: .value("Month", point.ageMonths),
                        y: .value("Value", displayValue(point.value))
                    )
                    .foregroundStyle(MCColor.accent)
                    .symbolSize(60)
                }

                // Baby's line connecting points
                ForEach(chartData.babyPoints) { point in
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
            .padding(MCSpacing.lg)
            .background(MCElevation.surface, in: RoundedRectangle(cornerRadius: MCRadius.xl))
        } else {
            emptyChartPlaceholder
        }
    }

    private var emptyChartPlaceholder: some View {
        VStack(spacing: MCSpacing.lg) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("No measurements yet")
                .font(MCTypography.title3)
                .foregroundStyle(.secondary)
            Text("Add your first measurement to see growth charts")
                .font(MCTypography.callout)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 280)
    }

    // MARK: - Measurement Hero

    @ViewBuilder
    private var measurementHero: some View {
        if let latestRecord {
            VStack(alignment: .leading, spacing: MCSpacing.md) {
                HStack {
                    Text(viewModel.selectedMeasurement.label)
                        .mcBadge()
                        .foregroundStyle(MCColor.accent)
                    Spacer()
                    Text("WHO 0-24 mo")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColor.Foreground.level3)
                }

                HStack(alignment: .center, spacing: MCSpacing.md) {
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text(selectedMeasurementValue(record: latestRecord))
                            .font(MCTypography.display)
                            .foregroundStyle(MCColor.Foreground.level1)
                            .monospacedDigit()
                        Text(latestRecord.date.formatted(date: .abbreviated, time: .shortened))
                            .font(MCTypography.footnote)
                            .foregroundStyle(MCColor.Foreground.level3)
                    }

                    Spacer(minLength: 0)

                    if let pct = viewModel.latestPercentile {
                        percentileOrb(percentile: pct)
                    }
                }
            }
            .padding(MCSpacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: MCRadius.xl)
                    .fill(MCElevation.elevated)
                    .overlay {
                        RoundedRectangle(cornerRadius: MCRadius.xl)
                            .stroke(MCColor.accent.opacity(MCOpacity.soft), lineWidth: 1)
                    }
                    .shadow(color: MCColor.accent.opacity(MCOpacity.soft), radius: 24)
            }
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
                    .accessibilityHidden(true)
                Text("Add Measurement")
            }
            .font(MCTypography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(MCColor.accent, in: RoundedRectangle(cornerRadius: MCRadius.lg))
        }
    }

    private func percentileOrb(percentile: Double) -> some View {
        ZStack {
            Circle()
                .stroke(MCColor.accent.opacity(MCOpacity.soft), lineWidth: 6)
            Circle()
                .trim(from: 0, to: min(max(percentile / 100, 0), 1))
                .stroke(MCColor.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(Int(percentile))")
                    .font(MCTypography.title2)
                    .foregroundStyle(MCColor.Foreground.level1)
                    .monospacedDigit()
                Text("pct")
                    .font(MCTypography.caption)
                    .foregroundStyle(MCColor.Foreground.level3)
            }
        }
        .frame(width: 96, height: 96)
        .accessibilityLabel("\(Int(percentile))th percentile")
    }

    // MARK: - History

    @ViewBuilder
    private var historySection: some View {
        if !viewModel.records.isEmpty {
            VStack(alignment: .leading, spacing: MCSpacing.md) {
                Text("History")
                    .font(MCTypography.title3)

                ForEach(viewModel.records) { record in
                    HStack {
                        VStack(alignment: .leading, spacing: MCSpacing.xs) {
                            Text(record.date.formatted(date: .abbreviated, time: .omitted))
                                .font(MCTypography.subheadline).fontWeight(.bold)
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
                            .font(MCTypography.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(MCSpacing.md)
                    .background(MCElevation.surface, in: RoundedRectangle(cornerRadius: MCRadius.md))
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

    private var latestRecord: GrowthRecord? {
        viewModel.records.max { $0.date < $1.date }
    }

    private func selectedMeasurementValue(record: GrowthRecord) -> String {
        switch viewModel.selectedMeasurement {
        case .weight:
            return record.weightFormatted
        case .length:
            return record.lengthFormatted
        case .headCircumference:
            return record.headCircumferenceFormatted
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
