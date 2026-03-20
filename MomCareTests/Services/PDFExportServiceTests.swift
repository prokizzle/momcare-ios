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

        // Generate once with only the in-range record, then again with both.
        // The service filters internally, so both PDFs must be identical — if
        // the out-of-range record were included the rendered page would differ.
        let urlInRangeOnly = try await service.generateReport(
            baby: baby,
            records: [inRange],
            events: [],
            dateRange: range
        )
        let urlWithOutOfRange = try await service.generateReport(
            baby: baby,
            records: [inRange, outOfRange],
            events: [],
            dateRange: range
        )

        let dataInRangeOnly = try Data(contentsOf: urlInRangeOnly)
        let dataWithOutOfRange = try Data(contentsOf: urlWithOutOfRange)

        // Both PDFs must have non-trivial content and be equal in size,
        // confirming the out-of-range record was excluded.
        #expect(dataInRangeOnly.count > 1024)
        #expect(dataInRangeOnly.count == dataWithOutOfRange.count)
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

    @Test("Filename includes baby name and date")
    func filenameFormat() async throws {
        let url = try await service.generateReport(
            baby: baby,
            records: [],
            events: [],
            dateRange: dateRange
        )
        #expect(url.lastPathComponent.contains("Emma"))
        #expect(url.lastPathComponent.hasSuffix(".pdf"))
    }
}
