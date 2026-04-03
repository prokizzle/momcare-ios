import Foundation
import SwiftData

/// Creates a ModelContainer pointing at the shared App Group SQLite store.
///
/// Background App Intents run in a separate process and cannot access the main
/// app's in-memory container. This helper recreates the exact same configuration
/// — group container, schema, and migration plan — so reads/writes land in the
/// same database file.
enum IntentModelContainer {
    static func make() throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV6.self)
        let config = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier("group.com.feelingmindful.momcare"),
            cloudKitDatabase: .none
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: MomCareMigrationPlan.self,
            configurations: config
        )
    }
}
