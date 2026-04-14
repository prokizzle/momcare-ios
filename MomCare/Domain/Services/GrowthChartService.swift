import Foundation

struct GrowthChartService: Sendable {

    nonisolated(unsafe) let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    enum MeasurementType: String, CaseIterable, Sendable {
        case weight, length, headCircumference

        var label: String {
            switch self {
            case .weight: "Weight"
            case .length: "Length"
            case .headCircumference: "Head"
            }
        }

        var systemImage: String {
            switch self {
            case .weight: "scalemass.fill"
            case .length: "ruler.fill"
            case .headCircumference: "circle.dashed"
            }
        }
    }

    struct WHODataPoint: Codable, Sendable {
        let month: Int
        let p3: Double
        let p15: Double
        let p50: Double
        let p85: Double
        let p97: Double
    }

    struct GrowthChartData: Sendable {
        let percentileBands: [WHODataPoint]
        let babyPoints: [BabyDataPoint]
    }

    struct BabyDataPoint: Identifiable, Sendable {
        let id: UUID
        let ageMonths: Double
        let value: Double
        let percentile: Double?
    }

    // MARK: - Load WHO Data

    func loadStandard(measurement: MeasurementType, sex: Baby.BiologicalSex?) throws -> [WHODataPoint] {
        let sexKey: String
        switch sex {
        case .male: sexKey = "boys"
        case .female: sexKey = "girls"
        default: sexKey = "boys"
        }

        let measurementKey: String
        switch measurement {
        case .weight: measurementKey = "weight"
        case .length: measurementKey = "length"
        case .headCircumference: measurementKey = "head"
        }

        let fileName = "\(measurementKey)_\(sexKey)"

        guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
            throw GrowthChartError.dataNotFound(fileName)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([WHODataPoint].self, from: data)
    }

    // MARK: - Percentile Calculation

    func percentile(value: Double, ageMonths: Int, standard: [WHODataPoint]) -> Double? {
        guard let point = standard.first(where: { $0.month == ageMonths }) else {
            return nil
        }

        let knownPercentiles: [(percentile: Double, value: Double)] = [
            (3, point.p3),
            (15, point.p15),
            (50, point.p50),
            (85, point.p85),
            (97, point.p97)
        ]

        // Below p3
        if value <= knownPercentiles[0].value {
            let ratio = value / knownPercentiles[0].value
            return max(0.1, 3 * ratio)
        }

        // Above p97
        if value >= knownPercentiles[4].value {
            let excess = value - knownPercentiles[4].value
            let range = knownPercentiles[4].value - knownPercentiles[3].value
            guard range > 0 else { return 99 }
            return min(99.9, 97 + 3 * (excess / range))
        }

        // Interpolate between known percentiles
        for index in 0..<(knownPercentiles.count - 1) {
            let lower = knownPercentiles[index]
            let upper = knownPercentiles[index + 1]
            if value >= lower.value && value <= upper.value {
                let range = upper.value - lower.value
                guard range > 0 else { return lower.percentile }
                let fraction = (value - lower.value) / range
                return lower.percentile + fraction * (upper.percentile - lower.percentile)
            }
        }

        return nil
    }

    // MARK: - Chart Data

    func chartData(
        records: [GrowthRecord],
        sex: Baby.BiologicalSex?,
        measurement: MeasurementType,
        dateOfBirth: Date
    ) throws -> GrowthChartData {
        let standard = try loadStandard(measurement: measurement, sex: sex)

        let babyPoints: [BabyDataPoint] = records.compactMap { record in
            let value: Double?
            switch measurement {
            case .weight: value = record.weightGrams
            case .length: value = record.lengthCm
            case .headCircumference: value = record.headCircumferenceCm
            }
            guard let value else { return nil }

            let ageMonths = record.ageInMonths(dateOfBirth: dateOfBirth)
            let pct = percentile(value: value, ageMonths: ageMonths, standard: standard)

            let days = Calendar.current.dateComponents([.day], from: dateOfBirth, to: record.date).day ?? 0
            let fractionalMonths = Double(days) / 30.44

            return BabyDataPoint(id: record.id, ageMonths: fractionalMonths, value: value, percentile: pct)
        }.sorted { $0.ageMonths < $1.ageMonths }

        return GrowthChartData(percentileBands: standard, babyPoints: babyPoints)
    }
}

enum GrowthChartError: Error, LocalizedError {
    case dataNotFound(String)

    var errorDescription: String? {
        switch self {
        case .dataNotFound(let name): "WHO data file not found: \(name)"
        }
    }
}
