import Foundation
import SwiftData

enum SchemaV3: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(3, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            BabyModel.self,
            FeedingModel.self,
            SelfCareLogModel.self,
            SelfCareGridItemModel.self,
            ContentHistoryModel.self,
            DiaperModel.self
        ]
    }
}
