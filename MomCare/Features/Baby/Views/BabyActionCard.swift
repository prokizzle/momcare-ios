import SwiftUI

enum BabyCardType: String, CaseIterable, Sendable {
    case nap, feeding, diaper

    var idleIcon: String {
        switch self {
        case .nap: "moon.stars.fill"
        case .feeding: "drop.fill"
        case .diaper: "circle.dotted"
        }
    }

    var idleLabel: String {
        switch self {
        case .nap: "Nap"
        case .feeding: "Feed"
        case .diaper: "Diaper"
        }
    }
}

@MainActor
struct BabyActionCard: View {
    let cardType: BabyCardType
    let babyId: UUID
    var sleepViewModel: SleepViewModel?
    var onSleepTimerRequested: (() -> Void)?
    @Environment(BabyActivityEngine.self) private var engine
    @State private var isAnimating = false
    @State private var showFeedingSelector = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            handleTap()
        } label: {
            cardContent
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background {
                    RoundedRectangle(cornerRadius: MCRadius.lg)
                        .fill(MCElevation.elevated)
                        .overlay { activeOverlay }
                }
                .scaleEffect(isAnimating ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showFeedingSelector) {
            FeedingSelectorSheet { method in
                Task { await engine.startFeeding(babyId: babyId, method: method) }
            }
        }
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var cardContent: some View {
        VStack(spacing: MCSpacing.xs) {
            switch cardType {
            case .nap:
                napContent
            case .feeding:
                feedingContent
            case .diaper:
                diaperContent
            }
        }
    }

    @ViewBuilder
    private var napContent: some View {
        if engine.isNapActive {
            Image(systemName: "moon.stars.fill")
                .font(.title2)
                .foregroundStyle(MCColor.baby)
            Text("Napping")
                .font(.caption2.bold())
            Text(engine.napElapsedFormatted)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        } else {
            Image(systemName: "moon.stars.fill")
                .font(.title2)
            Text("Nap")
                .font(.caption2)
        }
    }

    @ViewBuilder
    private var feedingContent: some View {
        if engine.isFeedingActive {
            Image(systemName: engine.feedMethod?.systemImage ?? "drop.fill")
                .font(.title2)
                .foregroundStyle(MCColor.feeding)
            Text("End Feed")
                .font(.caption2.bold())
            Text(engine.feedingElapsedFormatted)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        } else {
            Image(systemName: "drop.fill")
                .font(.title2)
            Text("Feed")
                .font(.caption2)
        }
    }

    @ViewBuilder
    private var diaperContent: some View {
        if engine.showDiaperOptions {
            HStack(spacing: MCSpacing.xs) {
                diaperOptionButton(.wet, label: "Wet")
                diaperOptionButton(.dirty, label: "Dirty")
                diaperOptionButton(.both, label: "Both")
            }
            .padding(.horizontal, MCSpacing.xs)
        } else {
            Image(systemName: "circle.dotted")
                .font(.title2)
            Text("Diaper")
                .font(.caption2)
        }
    }

    @ViewBuilder
    private func diaperOptionButton(_ type: Diaper.DiaperType, label: String) -> some View {
        Button {
            MCHaptic.tap()
            Task { await engine.selectDiaperType(type, babyId: babyId) }
        } label: {
            Text(label)
                .font(.caption2.bold())
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background {
                    RoundedRectangle(cornerRadius: MCRadius.sm)
                        .fill(MCColor.diaper.opacity(MCOpacity.medium))
                }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var activeOverlay: some View {
        switch cardType {
        case .nap where engine.isNapActive:
            RoundedRectangle(cornerRadius: MCRadius.lg).fill(MCColor.baby.opacity(MCOpacity.soft))
        case .feeding where engine.isFeedingActive:
            RoundedRectangle(cornerRadius: MCRadius.lg).fill(MCColor.feeding.opacity(MCOpacity.soft))
        default:
            EmptyView()
        }
    }

    private var accessibilityLabel: String {
        switch cardType {
        case .nap: engine.isNapActive ? "End nap, elapsed \(engine.napElapsedFormatted)" : "Start nap"
        case .feeding:
            engine.isFeedingActive ? "End feeding, elapsed \(engine.feedingElapsedFormatted)" : "Start feeding"
        case .diaper: "Log diaper change"
        }
    }

    private func handleTap() {
        MCHaptic.tap()
        withAnimation(reduceMotion ? nil : MCAnimation.quick) {
            isAnimating = true
        }
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            isAnimating = false
        }

        switch cardType {
        case .nap:
            if engine.isNapActive {
                onSleepTimerRequested?()
            } else {
                Task { await engine.startNap(babyId: babyId) }
            }
        case .feeding:
            if engine.isFeedingActive {
                Task { await engine.endFeeding(babyId: babyId) }
            } else {
                showFeedingSelector = true
            }
        case .diaper:
            engine.logDiaper(babyId: babyId)
        }
    }
}
