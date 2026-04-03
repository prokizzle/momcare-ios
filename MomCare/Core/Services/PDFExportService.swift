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
    ///
    /// Uses `ImageRenderer.render { size, drawInContext in }` to draw directly into a
    /// `UIGraphicsPDFRenderer` context, avoiding the large intermediate UIImage allocation
    /// that `ImageRenderer.uiImage` would produce for long reports.
    ///
    /// - Note: Caller is responsible for pre-filtering and sorting `records` and `events`
    ///   to the desired date range before calling this method.
    func generateReport(
        baby: Baby,
        records: [GrowthRecord],
        events: [HealthEvent],
        dateRange: ClosedRange<Date>,
        feedings: [Feeding] = []
    ) async throws -> URL {
        // ImageRenderer is @MainActor — render directly into the PDF context on the main thread
        // to avoid allocating a full uncompressed UIImage intermediate.
        let pdfData: Data = try await MainActor.run {
            let reportView = GrowthReportView(
                baby: baby,
                records: records,
                events: events,
                dateRange: dateRange,
                feedings: feedings
            )
            let renderer = ImageRenderer(content: reportView.frame(width: 612))
            renderer.scale = 2.0

            var renderedData: Data?
            renderer.render { size, drawInContext in
                let pageRect = CGRect(origin: .zero, size: size)
                let pdfRenderer = UIGraphicsPDFRenderer(bounds: pageRect)
                renderedData = pdfRenderer.pdfData { context in
                    context.beginPage()
                    drawInContext(context.cgContext)
                }
            }
            guard let data = renderedData else {
                throw PDFExportError.renderFailed
            }
            return data
        }

        // File I/O is CPU/IO-bound — run off the main thread.
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

    private func writeTempFile(data: Data, filename: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)
            .appendingPathExtension("pdf")
        try data.write(to: url, options: .atomic)
        return url
    }

    /// Produces `{name}_GrowthReport_{YYYY-MM-DD}_{8-char-UUID}.pdf`.
    /// `cleanupOldExports()` depends on `_GrowthReport_` being present.
    /// Baby name is filtered to alphanumerics/hyphens/underscores and truncated to 40 chars;
    /// falls back to "Baby" when the filtered result is empty.
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
