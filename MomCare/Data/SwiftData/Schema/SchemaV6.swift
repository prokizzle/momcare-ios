import Foundation
import SwiftData

enum SchemaV6: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(6, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            BabyModel.self,
            FeedingModel.self,
            SelfCareLogModel.self,
            SelfCareGridItemModel.self,
            ContentHistoryModel.self,
            DiaperModel.self,
            BabySleepModel.self,
            GrowthRecordModel.self,
            HealthEventModel.self
        ]
    }
}
