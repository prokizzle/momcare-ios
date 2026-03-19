import CoreSpotlight
import Foundation
import UniformTypeIdentifiers

/// Indexes MomCare content into Core Spotlight so babies and feedings
/// appear in system search.
///
/// Call `indexAll()` from `MomCareApp` after data loads. The indexer uses
/// `CSSearchableIndex.default()` which batches writes automatically.
@MainActor
final class SpotlightIndexer {
    static let shared = SpotlightIndexer()

    private let babyDomain = "com.feelingmindful.momcare.babies"
    private let feedingDomain = "com.feelingmindful.momcare.feedings"

    private init() {}

    // MARK: - Baby

    func indexBabies(_ babies: [Baby]) {
        let items = babies.map { makeItem(for: $0) }
        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error {
                #if DEBUG
                print("SpotlightIndexer: failed to index babies — \(error)")
                #endif
            }
        }
    }

    func removeBaby(id: UUID) {
        CSSearchableIndex.default().deleteSearchableItems(
            withIdentifiers: ["baby-\(id.uuidString)"]
        ) { _ in }
    }

    func removeAllBabies() {
        CSSearchableIndex.default().deleteSearchableItems(
            withDomainIdentifiers: [babyDomain]
        ) { _ in }
    }

    // MARK: - Feeding

    func indexFeedings(_ feedings: [Feeding]) {
        let items = feedings.map { makeItem(for: $0) }
        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error {
                #if DEBUG
                print("SpotlightIndexer: failed to index feedings — \(error)")
                #endif
            }
        }
    }

    func removeAllFeedings() {
        CSSearchableIndex.default().deleteSearchableItems(
            withDomainIdentifiers: [feedingDomain]
        ) { _ in }
    }

    // MARK: - Private helpers

    private func makeItem(for baby: Baby) -> CSSearchableItem {
        let attributes = CSSearchableItemAttributeSet(contentType: .item)
        attributes.title = baby.name
        attributes.contentDescription = "Baby in MomCare"
        attributes.keywords = ["baby", baby.name.lowercased(), "momcare"]

        let item = CSSearchableItem(
            uniqueIdentifier: "baby-\(baby.id.uuidString)",
            domainIdentifier: babyDomain,
            attributeSet: attributes
        )
        item.expirationDate = .distantFuture
        return item
    }

    private func makeItem(for feeding: Feeding) -> CSSearchableItem {
        let attributes = CSSearchableItemAttributeSet(contentType: .item)
        let typeName = feeding.feedingType.rawValue.capitalized
        attributes.title = "\(typeName) feeding"
        attributes.contentDescription = feeding.startTime.formatted(date: .abbreviated, time: .shortened)
        attributes.keywords = ["feeding", typeName.lowercased(), "momcare"]
        attributes.contentCreationDate = feeding.startTime

        let item = CSSearchableItem(
            uniqueIdentifier: "feeding-\(feeding.id.uuidString)",
            domainIdentifier: feedingDomain,
            attributeSet: attributes
        )
        return item
    }
}
