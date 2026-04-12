import SwiftUI

@MainActor
struct HealthEventsScreen: View {
    let babyId: UUID
    let dateOfBirth: Date
    @Bindable var viewModel: HealthEventsViewModel
    @State private var selectedVaccineName: String?

    var body: some View {
        ScrollView {
            VStack(spacing: MCSpacing.xl) {
                filterChips
                if !viewModel.upcomingVaccines.isEmpty {
                    upcomingVaccinesSection
                }
                if viewModel.filteredEvents.isEmpty {
                    emptyState
                } else {
                    timeline
                }
                addButton
            }
            .padding(.horizontal, MCSpacing.lg)
            .padding(.vertical, MCSpacing.lg)
        }
        .nightlightBackground()
        .navigationTitle("Health Events")
        .task {
            await viewModel.loadEvents(babyId: babyId)
            viewModel.loadUpcomingVaccines(dateOfBirth: dateOfBirth)
        }
        .sheet(isPresented: $viewModel.showAddSheet) {
            AddHealthEventView(
                babyId: babyId,
                dateOfBirth: dateOfBirth,
                viewModel: viewModel,
                prefillVaccineName: selectedVaccineName
            )
        }
        .onChange(of: viewModel.showAddSheet) { _, isShowing in
            if !isShowing { selectedVaccineName = nil }
        }
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MCSpacing.sm) {
                filterChip(label: "All", type: nil)
                ForEach(HealthEvent.EventType.allCases, id: \.self) { type in
                    filterChip(label: type.label, type: type)
                }
            }
            .padding(.horizontal, MCSpacing.xs)
        }
    }

    private func filterChip(label: String, type: HealthEvent.EventType?) -> some View {
        let isSelected = viewModel.selectedFilter == type
        return Button {
            MCHaptic.select()
            withAnimation(MCAnimation.quick) {
                viewModel.selectedFilter = type
            }
        } label: {
            HStack(spacing: MCSpacing.xs) {
                if let type {
                    Image(systemName: type.systemImage)
                        .font(.caption)
                }
                Text(label)
                    .font(MCTypography.caption)
            }
            .padding(.horizontal, MCSpacing.md)
            .padding(.vertical, MCSpacing.sm)
            .background(
                isSelected ? (type?.color ?? MCColor.accent) : MCElevation.surface,
                in: Capsule()
            )
            .foregroundStyle(isSelected ? .white : .secondary)
        }
        .accessibilityLabel("Filter by \(label)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Upcoming Vaccines

    private var upcomingVaccinesSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            HStack(spacing: MCSpacing.sm) {
                Image(systemName: "syringe.fill")
                    .foregroundStyle(MCColor.babyStatus)
                    .accessibilityHidden(true)
                Text("Upcoming Vaccines")
                    .font(MCTypography.headline)
                    .foregroundStyle(.white)
            }

            ForEach(viewModel.upcomingVaccines) { vaccine in
                HStack(spacing: MCSpacing.md) {
                    VStack(alignment: .leading, spacing: MCSpacing.xs) {
                        Text(vaccine.name)
                            .font(MCTypography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        Text("\(vaccine.ageMonths) months")
                            .font(MCTypography.caption)
                            .foregroundStyle(.secondary)
                        Text(vaccine.description)
                            .font(MCTypography.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(2)
                    }
                    Spacer()
                    Button {
                        MCHaptic.tap()
                        selectedVaccineName = vaccine.name
                        viewModel.showAddSheet = true
                    } label: {
                        Text("Log")
                            .font(MCTypography.button)
                            .foregroundStyle(.white)
                            .padding(.horizontal, MCSpacing.md)
                            .padding(.vertical, MCSpacing.sm)
                            .background(
                                MCColor.babyStatus,
                                in: RoundedRectangle(cornerRadius: MCRadius.sm)
                            )
                    }
                    .accessibilityLabel("Log \(vaccine.name) vaccine")
                }
                .padding(MCSpacing.md)
                .background(MCElevation.elevated, in: RoundedRectangle(cornerRadius: MCRadius.md))
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            illustration: .emptyFeeding,
            title: "No health events",
            message: "Track vaccines, illnesses, milestones, and doctor visits",
            actionTitle: "Add Event"
        ) {
            viewModel.showAddSheet = true
        }
        .padding(.vertical, MCSpacing.section)
    }

    // MARK: - Timeline

    private var timeline: some View {
        VStack(alignment: .leading, spacing: MCSpacing.xl) {
            ForEach(viewModel.groupedEvents, id: \.0) { month, events in
                VStack(alignment: .leading, spacing: MCSpacing.md) {
                    Text(month)
                        .font(MCTypography.title3)
                        .foregroundStyle(.white)

                    ForEach(events) { event in
                        NavigationLink {
                            HealthEventDetailView(event: event, viewModel: viewModel)
                        } label: {
                            eventRow(event)
                        }
                        .transition(MCTransition.listInsert)
                    }
                }
            }
        }
    }

    private func eventRow(_ event: HealthEvent) -> some View {
        HStack(spacing: MCSpacing.md) {
            Circle()
                .fill(event.eventType.color.opacity(MCOpacity.medium))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: event.eventType.systemImage)
                        .font(MCTypography.callout)
                        .foregroundStyle(event.eventType.color)
                }

            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                Text(event.title)
                    .font(MCTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(event.date.formatted(date: .abbreviated, time: .omitted))
                    .font(MCTypography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(MCSpacing.md)
        .background(MCElevation.surface, in: RoundedRectangle(cornerRadius: MCRadius.md))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.eventType.label): \(event.title)")
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            MCHaptic.tap()
            viewModel.showAddSheet = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .accessibilityHidden(true)
                Text("Add Health Event")
            }
            .font(MCTypography.button)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(MCColor.accent, in: RoundedRectangle(cornerRadius: MCRadius.lg))
        }
    }
}
