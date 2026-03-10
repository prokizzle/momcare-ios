import Foundation
import SwiftData

@Model
final class ContentHistoryModel {
    @Attribute(.unique) var contentId: String
    var lastShownAt: Date

    init(contentId: String, lastShownAt: Date = .now) {
        self.contentId = contentId
        self.lastShownAt = lastShownAt
    }
}
