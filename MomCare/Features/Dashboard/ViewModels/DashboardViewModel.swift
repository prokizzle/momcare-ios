import Foundation
import SwiftUI

@Observable
@MainActor
final class DashboardViewModel {

    // MARK: - Urgency

    enum Urgency {
        case safe       // < 2 hours since last feeding
        case warning    // 2–3 hours
        case urgent     // > 3 hours or no feeding recorded

        var color: Color {
            switch self {
            case .safe: MCColor.Urgency.safe
            case .warning: MCColor.Urgency.warning
            case .urgent: MCColor.Urgency.urgent
            }
        }

        var label: String {
            switch self {
            case .safe: "All good"
            case .warning: "Feeding soon"
            case .urgent: "Feeding overdue"
            }
        }
    }

    // MARK: - Smart Suggestion

    struct SmartSuggestion: Identifiable, Sendable {
        let id: UUID
        let message: String
        let actionTab: AppTab?

        init(message: String, actionTab: AppTab? = nil) {
            self.id = UUID()
            self.message = message
            self.actionTab = actionTab
        }
    }

    // MARK: - State

    private(set) var lastFeeding: Feeding?
    private(set) var inProgressFeeding: Feeding?
    private(set) var dailySummary: DailySummary = .empty
    private(set) var suggestions: [SmartSuggestion] = []
    private(set) var isLoading = false
    private(set) var dismissedSuggestionIds: Set<UUID> = []

    var visibleSuggestions: [SmartSuggestion] {
        suggestions.filter { !dismissedSuggestionIds.contains($0.id) }
    }

    var urgency: Urgency {
        guard let last = lastFeeding, !last.isInProgress else {
            return inProgressFeeding != nil ? .safe : .urgent
        }
        let hoursSince = Date.now.timeIntervalSince(last.endTime ?? last.startTime) / 3600
        switch hoursSince {
        case ..<2: return .safe
        case 2..<3: return .warning
        default: return .urgent
        }
    }

    var timeSinceLastFeeding: TimeInterval? {
        guard let last = lastFeeding, let endTime = last.endTime else { return nil }
        return Date.now.timeIntervalSince(endTime)
    }

    // MARK: - Dependencies

    private let feedingRepository: any FeedingRepositoryProtocol
    private let selfCareRepository: any SelfCareRepositoryProtocol

    // MARK: - Init

    init(
        feedingRepository: any FeedingRepositoryProtocol,
        selfCareRepository: any SelfCareRepositoryProtocol
    ) {
        self.feedingRepository = feedingRepository
        self.selfCareRepository = selfCareRepository
    }

    // MARK: - Load

    func loadDashboard(babyId: UUID?) async {
        isLoading = true
        defer { isLoading = false }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadFeedingData(babyId: babyId) }
            group.addTask { await self.loadSelfCareData() }
        }

        suggestions = generateSuggestions()
    }

    private func loadFeedingData(babyId: UUID?) async {
        guard let babyId else { return }
        do {
            inProgressFeeding = try await feedingRepository.getInProgressFeeding(babyId: babyId)
            let recent = try await feedingRepository.getFeedingsForBaby(babyId, limit: 1)
            lastFeeding = recent.first
        } catch {
            // Non-fatal: dashboard degrades gracefully
        }
    }

    private func loadSelfCareData() async {
        do {
            let todayLogs = try await selfCareRepository.getLogsForDate(.now)
            let gridItems = try await selfCareRepository.getGridItems()
            let visibleItems = gridItems.filter { $0.isVisible }

            let completedTypes = Set(todayLogs.map { $0.actionType })

            let waterGlasses = todayLogs
                .compactMap { log -> Int? in
                    guard case .water(let glasses) = log.detail else { return nil }
                    return glasses
                }
                .reduce(0, +)

            let mealsToday = todayLogs.filter { $0.actionType == .meal }.count

            dailySummary = DailySummary(
                completedActionTypes: completedTypes,
                waterGlassesToday: waterGlasses,
                mealsToday: mealsToday,
                visibleActionCount: max(visibleItems.count, 1)
            )
        } catch {
            // Non-fatal: summary stays at .empty
        }
    }

    // MARK: - Suggestions

    func generateSuggestions() -> [SmartSuggestion] {
        var result: [SmartSuggestion] = []

        // Feeding urgency nudge
        if urgency == .urgent && inProgressFeeding == nil {
            result.append(SmartSuggestion(
                message: "Baby may be due for a feeding soon.",
                actionTab: .baby
            ))
        }

        // Hydration nudge (fewer than 4 glasses)
        if dailySummary.waterGlassesToday < 4 {
            let glasses = dailySummary.waterGlassesToday
            let message = glasses == 0
                ? "No water logged today. Staying hydrated helps your milk supply."
                : "Only \(glasses) glass\(glasses == 1 ? "" : "es") of water today. You're doing great — keep it up."
            result.append(SmartSuggestion(message: message, actionTab: .selfCare))
        }

        // Meal nudge (no meals)
        if dailySummary.mealsToday == 0 {
            result.append(SmartSuggestion(
                message: "No meals logged yet. Remember to fuel yourself too.",
                actionTab: .selfCare
            ))
        }

        // Self-care encouragement when doing well
        if dailySummary.completionPercentage >= 0.7 && result.isEmpty {
            result.append(SmartSuggestion(
                message: "You're taking great care of yourself today. Keep it up.",
                actionTab: nil
            ))
        }

        return result
    }

    func dismissSuggestion(_ suggestion: SmartSuggestion) {
        dismissedSuggestionIds.insert(suggestion.id)
    }
}
