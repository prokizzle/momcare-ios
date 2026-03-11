import Foundation
import SwiftData

@Model
final class SelfCareLogModel {
    @Attribute(.unique) var id: UUID
    var actionTypeRaw: String
    var timestamp: Date
    var detailJSON: Data?
    var isSoftDeleted: Bool
    var createdAt: Date
    var updatedAt: Date

    init(from entity: SelfCareLog) {
        self.id = entity.id
        self.actionTypeRaw = entity.actionType.rawValue
        self.timestamp = entity.timestamp
        self.detailJSON = Self.encodeDetail(entity.detail)
        self.isSoftDeleted = false
        self.createdAt = entity.createdAt
        self.updatedAt = entity.updatedAt
    }

    func toEntity() -> SelfCareLog {
        SelfCareLog(
            id: id,
            actionType: SelfCareActionType(rawValue: actionTypeRaw) ?? .water,
            timestamp: timestamp,
            detail: Self.decodeDetail(detailJSON),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func update(from entity: SelfCareLog) {
        self.actionTypeRaw = entity.actionType.rawValue
        self.timestamp = entity.timestamp
        self.detailJSON = Self.encodeDetail(entity.detail)
        self.updatedAt = Date.now
    }

    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    private static func encodeDetail(_ detail: LogDetail?) -> Data? {
        guard let detail else { return nil }
        do {
            return try encoder.encode(detail)
        } catch {
            #if DEBUG
            print("SelfCareLogModel: failed to encode detail: \(error)")
            #endif
            return nil
        }
    }

    private static func decodeDetail(_ data: Data?) -> LogDetail? {
        guard let data else { return nil }
        do {
            return try decoder.decode(LogDetail.self, from: data)
        } catch {
            #if DEBUG
            print("SelfCareLogModel: failed to decode detail: \(error)")
            #endif
            return nil
        }
    }
}
