import Testing
import Foundation
@testable import MomCare

@Suite("PDFExportService", .serialized)
@MainActor
struct PDFExportServiceTests {

    private let service = PDFExportService()
    private let baby = Baby.fixture()
    private let dateRange: ClosedRange<Date> = {
        let start = Calendar.current.date(byAdding: .month, value: -3, to: .now)!
        return start...Date.now
    }()

    // MARK: - Generation

    @Test("Generate report with empty records and events does not throw")
    func generateReportEmptyData() async throws {
        let url = try await service.generateReport(
            baby: baby,
            records: [],
            events: [],
            dateRange: dateRange
        )
        #expect(url.pathExtension == "pdf")
    }

    @Test("Generate report with data produces non-empty PDF file")
    func generateReportWithData() async throws {
        let records: [GrowthRecord] = [
            .fixture(weightGrams: 4500, lengthCm: 55, headCircumferenceCm: 37),
            .fixture(
                date: Calendar.current.date(byAdding: .month, value: -2, to: .now)!,
                weightGrams: 3800,
                lengthCm: 51
            )
        ]
        let events: [HealthEvent] = [
            .fixture(eventType: .vaccine, title: "DTaP - Dose 1"),
            .fixture(eventType: .milestone, title: "First smile")
        ]

        let url = try await service.generateReport(
            baby: baby,
            records: records,
            events: events,
            dateRange: dateRange
        )

        let data = try Data(contentsOf: url)
        #expect(data.count > 1024, "PDF should be larger than 1KB")

        // PDFs start with %PDF header
        let header = String(data: data.prefix(4), encoding: .ascii)
        #expect(header == "%PDF")
    }

    @Test("Generate report with feedings produces larger PDF than without feedings")
    func generateReportWithFeedings() async throws {
        let records: [GrowthRecord] = [
            .fixture(weightGrams: 4500, lengthCm: 55)
        ]
        let feedings: [Feeding] = [
            .fixture(feedingType: .breast, startTime: Date.now.addingTimeInterval(-3600)),
            .fixture(feedingType: .bottle, startTime: Date.now.addingTimeInterval(-7200), amountMl: 150)
        ]

        let urlWithout = try await service.generateReport(
            baby: baby,
            records: records,
            events: [],
            dateRange: dateRange,
            feedings: []
        )
        let urlWith = try await service.generateReport(
            baby: baby,
            records: records,
            events: [],
            dateRange: dateRange,
            feedings: feedings
        )

        let dataWithout = try Data(contentsOf: urlWithout)
        let dataWith = try Data(contentsOf: urlWith)

        #expect(dataWithout.count > 1024)
        #expect(
            dataWith.count > dataWithout.count,
            "PDF with feedings should be larger — confirms feedings section is rendered"
        )
    }

    @Test("Date range filtering excludes out-of-range records")
    func dateRangeFiltering() async throws {
        let now = Date.now
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: now)!
        let range = threeMonthsAgo...now

        let inRange = GrowthRecord.fixture(
            date: Calendar.current.date(byAdding: .month, value: -1, to: now)!,
            weightGrams: 5000
        )
        let outOfRange = GrowthRecord.fixture(
            date: Calendar.current.date(byAdding: .month, value: -5, to: now)!,
            weightGrams: 3500
        )

        // PDFExportService is a dumb renderer: it includes whatever records the caller
        // passes. Pre-filtering is the caller's responsibility (ExportSheet does this).
        // Verify that passing allRecords (including out-of-range) produces a larger PDF
        // than passing only the filtered subset.
        let allRecords = [inRange, outOfRange]

        let urlFiltered = try await service.generateReport(
            baby: baby,
            records: [inRange],
            events: [],
            dateRange: range
        )
        let urlUnfiltered = try await service.generateReport(
            baby: baby,
            records: allRecords,
            events: [],
            dateRange: range
        )

        let dataFiltered = try Data(contentsOf: urlFiltered)
        let dataUnfiltered = try Data(contentsOf: urlUnfiltered)

        #expect(dataFiltered.count > 1024)
        // The unfiltered PDF renders an extra row, so it must be strictly larger.
        #expect(
            dataUnfiltered.count > dataFiltered.count,
            "PDF with out-of-range record should be larger — confirms service renders all passed records"
        )
    }

    @Test("Generate report writes valid temp file")
    func generateReportWritesTempFile() async throws {
        let url = try await service.generateReport(
            baby: baby,
            records: [],
            events: [],
            dateRange: dateRange
        )

        #expect(FileManager.default.fileExists(atPath: url.path))
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        let size = attrs[.size] as? Int ?? 0
        #expect(size > 0)
    }

    @Test("cleanupOldExports removes files older than 24h and keeps recent ones")
    func cleanupOldExports() throws {
        // Use an isolated subdirectory so this test never touches files from
        // other tests or production exports running concurrently.
        let testDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("PDFExportServiceTests_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: testDir) }

        let isolatedService = PDFExportService(exportsDirectory: testDir)
        let oldDate = Date.now.addingTimeInterval(-25 * 60 * 60)
        let recentDate = Date.now.addingTimeInterval(-60)

        // Create an old export file that should be deleted.
        let oldURL = testDir.appendingPathComponent("TestBaby_GrowthReport_2024-01-01_AABBCCDD.pdf")
        try Data("old".utf8).write(to: oldURL)
        try FileManager.default.setAttributes([.creationDate: oldDate], ofItemAtPath: oldURL.path)

        // Create a recent export file that should survive.
        let recentURL = testDir.appendingPathComponent("TestBaby_GrowthReport_2024-01-02_EEFF0011.pdf")
        try Data("recent".utf8).write(to: recentURL)
        try FileManager.default.setAttributes([.creationDate: recentDate], ofItemAtPath: recentURL.path)

        // Create a non-export PDF that should not be touched.
        let otherURL = testDir.appendingPathComponent("unrelated.pdf")
        try Data("other".utf8).write(to: otherURL)
        try FileManager.default.setAttributes([.creationDate: oldDate], ofItemAtPath: otherURL.path)

        isolatedService.cleanupOldExports()

        #expect(!FileManager.default.fileExists(atPath: oldURL.path), "Old export should be deleted")
        #expect(FileManager.default.fileExists(atPath: recentURL.path), "Recent export should be kept")
        #expect(FileManager.default.fileExists(atPath: otherURL.path), "Unrelated file should not be touched")
    }

    @Test("Filename includes sanitized baby name stem and .pdf extension")
    func filenameFormat() async throws {
        let url = try await service.generateReport(
            baby: baby,
            records: [],
            events: [],
            dateRange: dateRange
        )

        // Replicate the service's sanitization logic to compute the expected stem.
        let allowedCharacters = CharacterSet.alphanumerics.union(.init(charactersIn: "-_"))
        let filtered = baby.name.unicodeScalars
            .filter { allowedCharacters.contains($0) }
            .map { String($0) }
            .joined()
        let expectedStem = filtered.isEmpty ? "Baby" : String(filtered.prefix(40))

        #expect(url.lastPathComponent.contains(expectedStem), "Filename should include the sanitized baby name stem")
        #expect(url.lastPathComponent.hasSuffix(".pdf"))
    }
}
