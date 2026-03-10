import Foundation

struct SelfCareCard: Identifiable, Sendable {
    var id: UUID
    var type: CardType
    var message: String
    var score: Double
    var relatedAction: SelfCareActionType?
    var timestamp: Date

    enum CardType: String, Sendable {
        case selfCareWindow
        case hydrationNudge
        case affirmation
        case pepTalk
        case checkIn
        case streak
        case gentleNudge
    }
}
