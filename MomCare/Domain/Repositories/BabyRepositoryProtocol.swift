import Foundation

protocol BabyRepositoryProtocol: Repository where Entity == Baby {
    func getActiveBabies() async throws -> [Baby]
}
