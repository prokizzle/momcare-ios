import Foundation

@MainActor
protocol Repository<Entity> {
    associatedtype Entity: Identifiable & Sendable

    func getAll() async throws -> [Entity]
    func getById(_ id: Entity.ID) async throws -> Entity?
    func create(_ entity: Entity) async throws -> Entity
    func update(_ entity: Entity) async throws -> Entity
    func delete(_ id: Entity.ID) async throws
}
