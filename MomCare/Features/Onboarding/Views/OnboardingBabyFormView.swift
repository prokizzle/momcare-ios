import DSKit
import PhotosUI
import Pow
import SkeletonUI
import SwiftUI

@MainActor
struct OnboardingBabyFormView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showOptionalDetails = false
    @State private var showSuccess = false
    @State private var showSkeleton = true

    var body: some View {
        ScrollView {
            DSVStack(spacing: .custom(MCSpacing.xl)) {
                header
                previewCard
                requiredFields
                optionalFields
                errorDisplay
                submitButton
            }
            .padding(.horizontal, MCSpacing.xl)
            .padding(.vertical, MCSpacing.section)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                showSkeleton = false
            }
        }
        .onChange(of: selectedPhoto) { _, newItem in
            guard let newItem else {
                viewModel.photoLoadError = nil
                return
            }
            Task.detached {
                do {
                    let data = try await newItem.loadTransferable(type: Data.self)
                    await MainActor.run {
                        viewModel.babyPhotoData = data
                        viewModel.photoLoadError = nil
                    }
                } catch {
                    await MainActor.run {
                        viewModel.photoLoadError = "Failed to load photo. Please try again."
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: MCSpacing.lg) {
            Image(systemName: "figure.and.child.holdinghands")
                .font(.system(size: 56))
                .foregroundStyle(MCColor.accent)

            DSText("Add your baby")
                .font(.title.bold())
                .foregroundStyle(.white)

            DSText("Tell us about your little one")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    // MARK: - Preview Card

    private var previewCard: some View {
        HStack(spacing: MCSpacing.lg) {
            Group {
                if viewModel.babyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("B")
                        .font(.title2.bold())
                        .foregroundStyle(.white.opacity(0.3))
                } else {
                    Text(String(viewModel.babyName.prefix(1)).uppercased())
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 48, height: 48)
            .background(MCColor.accent.opacity(0.3), in: Circle())

            VStack(alignment: .leading, spacing: MCSpacing.xs) {
                Text(viewModel.babyName.isEmpty ? "Baby's name" : viewModel.babyName)
                    .font(.headline)
                    .foregroundStyle(viewModel.babyName.isEmpty ? .white.opacity(0.3) : .white)

                Text(viewModel.babyDateOfBirth.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()
        }
        .padding(MCSpacing.lg)
        .background(MCElevation.surface, in: RoundedRectangle(cornerRadius: MCRadius.lg))
        .skeleton(isEnabled: showSkeleton) { _ in
                RoundedRectangle(cornerRadius: MCRadius.md)
                    .fill(MCElevation.elevated)
                    .frame(height: 16)
            }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Baby preview: \(viewModel.babyName.isEmpty ? "No name entered" : viewModel.babyName)")
        .changeEffect(
            .spray(origin: UnitPoint(x: 0.5, y: 0.5)) {
                Image(systemName: "star.fill")
                    .foregroundStyle(MCColor.accent)
            },
            value: showSuccess
        )
    }

    // MARK: - Required Fields

    private var requiredFields: some View {
        DSVStack(spacing: .custom(MCSpacing.lg)) {
            formField(title: "Name") {
                TextField("Baby's name", text: $viewModel.babyName)
                    .textContentType(.name)
                    .foregroundStyle(.white)
            }

            formField(title: "Birthday") {
                DatePicker(
                    "Birthday",
                    selection: $viewModel.babyDateOfBirth,
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .labelsHidden()
                .tint(MCColor.accent)
            }
        }
    }

    // MARK: - Optional Fields

    private var optionalFields: some View {
        DisclosureGroup(isExpanded: $showOptionalDetails) {
            VStack(spacing: MCSpacing.lg) {
                formField(title: "Biological Sex") {
                    Picker("Biological Sex", selection: $viewModel.babyBiologicalSex) {
                        Text("Not specified").tag(nil as Baby.BiologicalSex?)
                        ForEach(Baby.BiologicalSex.allCases, id: \.self) { sex in
                            Text(sex.displayName).tag(sex as Baby.BiologicalSex?)
                        }
                    }
                    .tint(.white)
                }

                formField(title: "Feeding Method") {
                    Picker("Feeding Method", selection: $viewModel.babyFeedingMethod) {
                        ForEach(Baby.FeedingMethod.allCases, id: \.self) { method in
                            Text(method.displayName).tag(method)
                        }
                    }
                    .tint(.white)
                }

                formField(title: "Birth weight (g)") {
                    TextField("Optional", text: $viewModel.babyBirthWeight)
                        .keyboardType(.decimalPad)
                        .foregroundStyle(.white)
                }

                formField(title: "Birth length (cm)") {
                    TextField("Optional", text: $viewModel.babyBirthLength)
                        .keyboardType(.decimalPad)
                        .foregroundStyle(.white)
                }

                formField(title: "Head circumference (cm)") {
                    TextField("Optional", text: $viewModel.babyBirthHeadCircumference)
                        .keyboardType(.decimalPad)
                        .foregroundStyle(.white)
                }

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack {
                        Image(systemName: "photo")
                            .foregroundStyle(MCColor.accent)
                        Text("Choose Photo")
                            .foregroundStyle(.white)
                        Spacer()
                        if viewModel.babyPhotoData != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(MCColor.accent)
                        }
                    }
                    .padding(MCSpacing.lg)
                    .background(MCElevation.elevated, in: RoundedRectangle(cornerRadius: MCRadius.md))
                }
                .accessibilityLabel("Choose baby photo")

                if let photoError = viewModel.photoLoadError {
                    Text(photoError)
                        .font(.footnote)
                        .foregroundStyle(MCColor.error)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, MCSpacing.lg)
        } label: {
            DSText("Additional Details")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .tint(.white.opacity(0.5))
    }

    // MARK: - Error

    @ViewBuilder
    private var errorDisplay: some View {
        if let error = viewModel.babyError {
            Text(error)
                .font(.footnote)
                .foregroundStyle(MCColor.error)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Submit

    private var submitButton: some View {
        Button {
            MCHaptic.tap()
            Task {
                await viewModel.submitBaby()
                if viewModel.babySubmitSucceeded {
                    showSuccess = true
                    MCHaptic.success()
                    try? await Task.sleep(for: .seconds(1.2))
                    viewModel.advance()
                }
            }
        } label: {
            Text("Add Baby")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    viewModel.babyFormIsValid ? MCColor.accent : MCColor.accent.opacity(0.3),
                    in: RoundedRectangle(cornerRadius: MCRadius.lg)
                )
        }
        .disabled(!viewModel.babyFormIsValid)
    }

    // MARK: - Helpers

    private func formField<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            DSText(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))

            content()
                .padding(MCSpacing.lg)
                .background(MCElevation.elevated, in: RoundedRectangle(cornerRadius: MCRadius.md))
        }
    }
}
