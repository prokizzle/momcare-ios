import Foundation

struct SelfCareCard: Identifiable, Sendable, Equatable {
    var id: UUID
    var type: CardType
    var message: String
    var score: Double
    var relatedAction: SelfCareActionType?
    var timestamp: Date
    var contentId: String?

    init(
        id: UUID = UUID(),
        type: CardType,
        message: String,
        score: Double,
        relatedAction: SelfCareActionType? = nil,
        timestamp: Date,
        contentId: String? = nil
    ) {
        self.id = id
        self.type = type
        self.message = message
        self.score = score
        self.relatedAction = relatedAction
        self.timestamp = timestamp
        self.contentId = contentId
    }

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
