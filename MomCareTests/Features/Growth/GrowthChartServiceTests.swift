import Testing
import Foundation
@testable import MomCare

@Suite("GrowthChartService")
struct GrowthChartServiceTests {

    let service = GrowthChartService()

    @Test("Load WHO weight data for boys")
    func loadWeightBoys() throws {
        let data = try service.loadStandard(measurement: .weight, sex: .male)
        #expect(data.count == 25)
        #expect(data[0].month == 0)
        #expect(data[0].p50 > 0)
    }

    @Test("Load WHO weight data for girls")
    func loadWeightGirls() throws {
        let data = try service.loadStandard(measurement: .weight, sex: .female)
        #expect(data.count == 25)
    }

    @Test("Load WHO length data")
    func loadLength() throws {
        let data = try service.loadStandard(measurement: .length, sex: .male)
        #expect(data.count == 25)
        #expect(data[0].p50 > 40 && data[0].p50 < 60)
    }

    @Test("Load WHO head circumference data")
    func loadHead() throws {
        let data = try service.loadStandard(measurement: .headCircumference, sex: .female)
        #expect(data.count == 25)
    }

    @Test("Calculate percentile for 50th percentile value")
    func percentileAt50th() throws {
        let data = try service.loadStandard(measurement: .weight, sex: .male)
        let p50Value = data[3].p50
        let percentile = service.percentile(value: p50Value, ageMonths: 3, standard: data)
        #expect(percentile != nil)
        #expect(abs(percentile! - 50) < 5)
    }

    @Test("Percentile below p3 returns < 3")
    func percentileBelowP3() throws {
        let data = try service.loadStandard(measurement: .weight, sex: .male)
        let tinyValue = data[3].p3 - 500
        let percentile = service.percentile(value: tinyValue, ageMonths: 3, standard: data)
        #expect(percentile != nil)
        #expect(percentile! < 3)
    }

    @Test("Percentile above p97 returns > 97")
    func percentileAboveP97() throws {
        let data = try service.loadStandard(measurement: .weight, sex: .male)
        let hugeValue = data[3].p97 + 1000
        let percentile = service.percentile(value: hugeValue, ageMonths: 3, standard: data)
        #expect(percentile != nil)
        #expect(percentile! > 97)
    }

    @Test("Chart data returns percentile bands and baby points")
    func chartData() throws {
        let records = [
            GrowthRecord.fixture(date: .now, weightGrams: 5200),
            GrowthRecord.fixture(
                date: Calendar.current.date(byAdding: .month, value: -1, to: .now)!,
                weightGrams: 4500
            ),
        ]
        let dob = Calendar.current.date(byAdding: .month, value: -3, to: .now)!
        let result = try service.chartData(
            records: records,
            sex: .male,
            measurement: .weight,
            dateOfBirth: dob
        )
        #expect(!result.percentileBands.isEmpty)
        #expect(result.babyPoints.count == 2)
    }

    @Test("Age out of range returns nil percentile")
    func ageOutOfRange() throws {
        let data = try service.loadStandard(measurement: .weight, sex: .male)
        let percentile = service.percentile(value: 10000, ageMonths: 30, standard: data)
        #expect(percentile == nil)
    }

    @Test("Nil sex defaults to boys data")
    func nilSexDefaults() throws {
        let data = try service.loadStandard(measurement: .weight, sex: nil)
        #expect(data.count == 25)
    }
}
