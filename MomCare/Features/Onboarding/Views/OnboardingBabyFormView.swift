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

    var body: some View {
        ScrollView {
            VStack(spacing: MCSpacing.xl) {
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
        .onChange(of: selectedPhoto) { _, newItem in
            Task { @MainActor in
                viewModel.babyPhotoData = try? await newItem?.loadTransferable(type: Data.self)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: MCSpacing.lg) {
            Image(systemName: "figure.and.child.holdinghands")
                .font(.system(size: 56))
                .foregroundStyle(MCColor.accent)

            Text("Add your baby")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("Tell us about your little one")
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
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
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
        VStack(spacing: MCSpacing.lg) {
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
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.top, MCSpacing.lg)
        } label: {
            Text("Additional Details")
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
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Submit

    private var submitButton: some View {
        Button {
            MCHaptic.tap()
            Task {
                await viewModel.submitBaby()
                if viewModel.babyError == nil {
                    showSuccess = true
                    MCHaptic.success()
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
                    in: RoundedRectangle(cornerRadius: 16)
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
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))

            content()
                .padding(MCSpacing.lg)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
