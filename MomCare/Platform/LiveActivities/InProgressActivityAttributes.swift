import ActivityKit
import Foundation

struct InProgressActivityAttributes: ActivityAttributes {
    let babyName: String
    let activityType: String
    let activityIcon: String

    struct ContentState: Codable, Hashable {
        let startTime: Date
        let detail: String?
    }
}
