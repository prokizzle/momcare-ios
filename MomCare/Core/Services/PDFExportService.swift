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

final class PDFExportService: Sendable {

    // MARK: - Report Generation

    /// Renders a growth report PDF and writes it to a temporary file.
    /// Returns the file URL, suitable for use with ShareLink or UIActivityViewController.
    /// ImageRenderer capture runs on MainActor; PDF encoding and file I/O run off-main.
    ///
    /// - Note: Caller is responsible for pre-filtering and sorting `records` and `events`
    ///   to the desired date range before calling this method.
    func generateReport(
        baby: Baby,
        records: [GrowthRecord],
        events: [HealthEvent],
        dateRange: ClosedRange<Date>
    ) async throws -> URL {
        // ImageRenderer is @MainActor — capture the UIImage on the main thread.
        let image: UIImage = try await MainActor.run {
            let reportView = GrowthReportView(
                baby: baby,
                records: records,
                events: events,
                dateRange: dateRange
            )
            let renderer = ImageRenderer(content: reportView.frame(width: 612))
            renderer.scale = 2.0
            guard let uiImage = renderer.uiImage else {
                throw PDFExportError.renderFailed
            }
            return uiImage
        }

        // PDF encoding and file I/O are CPU/IO-bound — run off the main thread.
        let pdfData = renderToPDF(image: image)
        return try writeTempFile(data: pdfData, filename: reportFilename(baby: baby))
    }

    // MARK: - Cleanup

    /// Removes export PDFs from the temp directory that are older than 24 hours.
    /// Call on app launch or when the export sheet is dismissed.
    func cleanupOldExports() {
        let tempDir = FileManager.default.temporaryDirectory
        let cutoff = Date.now.addingTimeInterval(-24 * 60 * 60)
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: tempDir,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ) else { return }

        for url in contents where url.pathExtension == "pdf" && url.lastPathComponent.contains("_GrowthReport_") {
            let created = (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantFuture
            if created < cutoff {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    // MARK: - Private Helpers

    private func renderToPDF(image: UIImage) -> Data {
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
        // Allow only alphanumerics, hyphens, and underscores to prevent filesystem issues.
        let allowedCharacters = CharacterSet.alphanumerics.union(.init(charactersIn: "-_"))
        let filtered = baby.name.unicodeScalars
            .filter { allowedCharacters.contains($0) }
            .map { String($0) }
            .joined()
        let stem = filtered.isEmpty ? "Baby" : String(filtered.prefix(40))
        let uniqueSuffix = UUID().uuidString.prefix(8)
        return "\(stem)_GrowthReport_\(date)_\(uniqueSuffix)"
    }
}
