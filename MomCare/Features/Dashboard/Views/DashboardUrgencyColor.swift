import SwiftUI

extension DashboardViewModel.Urgency {
    var color: Color {
        switch self {
        case .safe: MCColor.Urgency.safe
        case .warning: MCColor.Urgency.warning
        case .urgent: MCColor.Urgency.urgent
        }
    }
}
