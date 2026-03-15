import SwiftUI

@MainActor
struct HealthEventDetailView: View {
    let event: HealthEvent
    @Bindable var viewModel: HealthEventsViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MCSpacing.xl) {
                typeBadge
                titleSection
                dateSection
                if let notes = event.notes, !notes.isEmpty {
                    notesSection(notes)
                }
                deleteButton
            }
            .padding(.horizontal, MCSpacing.lg)
            .padding(.vertical, MCSpacing.lg)
        }
        .nightlightBackground()
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete Event",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteEvent(id: event.id)
                    MCHaptic.success()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this health event? This cannot be undone.")
        }
    }

    // MARK: - Type Badge

    private var typeBadge: some View {
        HStack(spacing: MCSpacing.sm) {
            Image(systemName: event.eventType.systemImage)
                .font(.system(size: 14))
            Text(event.eventType.label)
                .font(MCTypography.badge)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, MCSpacing.md)
        .padding(.vertical, MCSpacing.sm)
        .background(
            event.eventType.color.opacity(MCOpacity.strong),
            in: Capsule()
        )
    }

    // MARK: - Title

    private var titleSection: some View {
        Text(event.title)
            .font(MCTypography.title2)
            .foregroundStyle(.white)
    }

    // MARK: - Date

    private var dateSection: some View {
        HStack(spacing: MCSpacing.sm) {
            Image(systemName: "calendar")
                .foregroundStyle(.secondary)
            Text(formattedDateRange)
                .font(MCTypography.body)
                .foregroundStyle(.secondary)
        }
        .padding(MCSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MCElevation.surface, in: RoundedRectangle(cornerRadius: MCRadius.md))
    }

    private var formattedDateRange: String {
        let startFormatted = event.date.formatted(date: .abbreviated, time: .omitted)
        if let endDate = event.endDate {
            let endFormatted = endDate.formatted(date: .abbreviated, time: .omitted)
            return "\(startFormatted) - \(endFormatted)"
        }
        return startFormatted
    }

    // MARK: - Notes

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("Notes")
                .font(MCTypography.headline)
                .foregroundStyle(.white)
            Text(notes)
                .font(MCTypography.body)
                .foregroundStyle(.secondary)
        }
        .padding(MCSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MCElevation.surface, in: RoundedRectangle(cornerRadius: MCRadius.md))
    }

    // MARK: - Delete

    private var deleteButton: some View {
        Button {
            MCHaptic.tap()
            showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete Event")
            }
            .font(MCTypography.button)
            .foregroundStyle(MCColor.error)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                MCColor.error.opacity(MCOpacity.soft),
                in: RoundedRectangle(cornerRadius: MCRadius.lg)
            )
        }
    }
}
