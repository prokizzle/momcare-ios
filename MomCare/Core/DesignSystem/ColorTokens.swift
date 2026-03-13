import SwiftUI

enum MCColor {
    static let accent = Color.accentColor
    static let feeding = Color("FeedingColor")
    static let selfCare = Color("SelfCareColor")
    static let babyStatus = Color("BabyStatusColor")
    static let diaper = Color("DiaperColor")
    static let baby = Color("BabyColor")

    static let error = Color.red

    enum Urgency {
        static let safe = Color.green
        static let warning = Color.yellow
        static let urgent = Color.orange
    }
}
