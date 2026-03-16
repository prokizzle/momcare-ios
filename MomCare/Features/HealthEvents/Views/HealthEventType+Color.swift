import SwiftUI

extension HealthEvent.EventType {
    var color: Color {
        switch self {
        case .vaccine: MCColor.babyStatus
        case .illness: MCColor.error
        case .milestone: MCColor.accent
        case .doctorVisit: MCColor.feeding
        case .allergy: MCColor.diaper
        }
    }
}
