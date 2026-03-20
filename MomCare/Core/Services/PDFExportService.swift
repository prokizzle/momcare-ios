import SwiftUI
import UIKit

enum PDFExportError: LocalizedError {
    case renderFailed

    var errorDescription: String? {
        switch self {
        case .renderFailed: "Failed to render the report. Please try again."
        }
    }
}

@MainActor
final class PDFExportService {

    // MARK: - Report Generation

    /// Renders a growth report PDF and writes it to a temporary file.
    /// Returns the file URL, suitable for use with ShareLink or UIActivityViewController.
    func generateReport(
        baby: Baby,
        records: [GrowthRecord],
        events: [HealthEvent],
        dateRange: ClosedRange<Date>
    ) async throws -> URL {
        let filteredRecords = records
            .filter { dateRange.contains($0.date) }
            .sorted { $0.date < $1.date }
        let filteredEvents = events
            .filter { dateRange.contains($0.date) }
            .sorted { $0.date < $1.date }

        let reportView = GrowthReportView(
            baby: baby,
            records: filteredRecords,
            events: filteredEvents,
            dateRange: dateRange
        )

        let pdfData = try renderToPDF(view: reportView)
        return try writeTempFile(data: pdfData, filename: reportFilename(baby: baby))
    }

    // MARK: - Private Helpers

    private func renderToPDF<V: View>(view: V) throws -> Data {
        // Render the SwiftUI view to a high-resolution image first, then
        // embed it into a PDF page. This is more reliable than trying to
        // drive a CGPDFContext from within ImageRenderer.render.
        let renderer = ImageRenderer(content: view.frame(width: 612))
        renderer.scale = 2.0

        guard let image = renderer.uiImage else {
            throw PDFExportError.renderFailed
        }

        let pageWidth: CGFloat = 612  // US Letter: 8.5in at 72 dpi
        let pageHeight = image.size.height * (pageWidth / image.size.width)
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let pdfRenderer = UIGraphicsPDFRenderer(bounds: pageRect)
        return pdfRenderer.pdfData { context in
            context.beginPage()
            image.draw(in: pageRect)
        }
    }

    private func writeTempFile(data: Data, filename: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)
            .appendingPathExtension("pdf")
        try data.write(to: url, options: .atomic)
        return url
    }

    private func reportFilename(baby: Baby) -> String {
        let date = Date.now.formatted(.iso8601.year().month().day())
        let safeName = baby.name.components(separatedBy: .whitespacesAndNewlines).joined()
        return "\(safeName)_GrowthReport_\(date)"
    }
}
