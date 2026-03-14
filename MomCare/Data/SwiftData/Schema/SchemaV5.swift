import Foundation
import SwiftData

enum SchemaV5: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(5, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            BabyModel.self,
            FeedingModel.self,
            SelfCareLogModel.self,
            SelfCareGridItemModel.self,
            ContentHistoryModel.self,
            DiaperModel.self,
            BabySleepModel.self,
            GrowthRecordModel.self
        ]
    }
}
