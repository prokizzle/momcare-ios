import SwiftUI

@MainActor
struct SleepTimerView: View {
    let babyId: UUID
    var onEnd: ((BabySleep.SleepQuality?, BabySleep.SleepLocation?) -> Void)?

    @Environment(BabyActivityEngine.self) private var engine
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var sleepType: BabySleep.SleepType = .autoDetect()
    @State private var selectedLocation: BabySleep.SleepLocation?
    @State private var selectedQuality: BabySleep.SleepQuality?
    @State private var showLocationPicker = false
    @State private var showQualitySheet = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: MCSpacing.xxl) {
                sleepTypeChip
                timerDisplay
                locationPicker
                Spacer()
                endButton
            }
            .padding(.horizontal, MCSpacing.xl)
            .padding(.top, MCSpacing.section)
        }
        .sheet(isPresented: $showQualitySheet) {
            qualitySheet
        }
    }

    // MARK: - Sleep Type Chip

    private var sleepTypeChip: some View {
        Button {
            sleepType = sleepType == .nap ? .nighttime : .nap
            MCHaptic.toggle()
        } label: {
            HStack(spacing: MCSpacing.sm) {
                Image(systemName: sleepType.systemImage)
                    .font(.title2)
                Text(sleepType.label)
                    .font(MCTypography.cardTitle)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, MCSpacing.lg)
            .padding(.vertical, MCSpacing.sm)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .accessibilityLabel("Sleep type: \(sleepType.label). Tap to change.")
    }

    // MARK: - Timer Display

    private var timerDisplay: some View {
        Text(engine.napElapsedFormatted)
            .font(MCTypography.largeTimer)
            .monospacedDigit()
            .foregroundStyle(.white)
            .contentTransition(.numericText())
            .animation(reduceMotion ? nil : .default, value: engine.napElapsedFormatted)
            .accessibilityLabel("Timer: \(engine.napElapsedFormatted)")
    }

    // MARK: - Location Picker

    private var locationPicker: some View {
        VStack(spacing: MCSpacing.md) {
            Button {
                withAnimation {
                    showLocationPicker.toggle()
                }
                MCHaptic.tap()
            } label: {
                HStack(spacing: MCSpacing.sm) {
                    Image(systemName: "location.fill")
                        .font(.callout)
                    Text(selectedLocation?.label ?? "Add Location")
                        .font(.callout)
                    Image(systemName: showLocationPicker ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundStyle(selectedLocation != nil ? .white : .secondary)
                .padding(.horizontal, MCSpacing.lg)
                .padding(.vertical, MCSpacing.sm)
                .background(Color.white.opacity(0.1), in: Capsule())
            }
            .accessibilityLabel(selectedLocation != nil
                ? "Location: \(selectedLocation!.label). Tap to change."
                : "Add sleep location")

            if showLocationPicker {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MCSpacing.sm) {
                        ForEach(BabySleep.SleepLocation.allCases, id: \.self) { location in
                            locationChip(location)
                        }
                    }
                    .padding(.horizontal, MCSpacing.xs)
                }
            }
        }
    }

    private func locationChip(_ location: BabySleep.SleepLocation) -> some View {
        let isSelected = selectedLocation == location
        return Button {
            selectedLocation = isSelected ? nil : location
            MCHaptic.select()
        } label: {
            Text(location.label)
                .font(.callout)
                .foregroundStyle(.white)
                .padding(.horizontal, MCSpacing.md)
                .padding(.vertical, MCSpacing.sm)
                .background(
                    isSelected
                        ? MCColor.baby.opacity(0.3)
                        : Color.white.opacity(0.1),
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? MCColor.baby : Color.clear,
                            lineWidth: 2
                        )
                )
        }
        .accessibilityLabel(location.label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - End Button

    private var endButton: some View {
        Button {
            showQualitySheet = true
            MCHaptic.tap()
        } label: {
            Text("End Sleep")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(MCColor.baby)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.bottom, MCSpacing.xxl)
        .accessibilityLabel("End sleep session")
    }

    // MARK: - Quality Sheet

    private var qualitySheet: some View {
        VStack(spacing: MCSpacing.xl) {
            Text("How was this sleep?")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.top, MCSpacing.xl)

            VStack(spacing: MCSpacing.md) {
                ForEach(BabySleep.SleepQuality.allCases, id: \.self) { quality in
                    qualityRow(quality)
                }
            }

            Button {
                finishSleep(quality: nil)
            } label: {
                Text("Skip")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MCSpacing.md)
            }
            .accessibilityLabel("Skip quality rating")
        }
        .padding(.horizontal, MCSpacing.xl)
        .presentationDetents([.height(260)])
        .presentationBackground(Color.black)
    }

    private func qualityRow(_ quality: BabySleep.SleepQuality) -> some View {
        Button {
            MCHaptic.tap()
            finishSleep(quality: quality)
        } label: {
            HStack(spacing: MCSpacing.md) {
                Image(systemName: quality.systemImage)
                    .font(.title3)
                    .foregroundStyle(MCColor.baby)
                Text(quality.label)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, MCSpacing.lg)
            .padding(.vertical, MCSpacing.md)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityLabel("\(quality.label) sleep quality")
    }

    // MARK: - Finish

    private func finishSleep(quality: BabySleep.SleepQuality?) {
        selectedQuality = quality
        MCHaptic.success()
        showQualitySheet = false
        onEnd?(selectedQuality, selectedLocation)
        dismiss()
    }
}
