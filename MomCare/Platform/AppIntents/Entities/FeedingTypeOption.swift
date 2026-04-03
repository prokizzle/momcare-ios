import AppIntents

/// Feeding types accessible from Siri/Shortcuts. Only breast and bottle are
/// supported because `FeedMethod` (the engine's input type) maps to left/right
/// breast side or bottle — solid and pumping cannot be started via a shortcut.
enum FeedingTypeOption: String, AppEnum {
    case breast
    case bottle

    nonisolated(unsafe) static var typeDisplayRepresentation: TypeDisplayRepresentation = "Feeding Type"

    nonisolated(unsafe) static var caseDisplayRepresentations: [FeedingTypeOption: DisplayRepresentation] = [
        .breast: "Breast",
        .bottle: "Bottle"
    ]

    /// Maps to the engine's `FeedMethod`. Breast defaults to left side.
    var feedMethod: FeedMethod {
        switch self {
        case .breast: return .left
        case .bottle: return .bottle
        }
    }
}
