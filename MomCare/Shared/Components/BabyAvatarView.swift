import SwiftUI

@MainActor
struct BabyAvatarView: View {
    let baby: Baby
    var size: CGFloat = 40

    @State private var cachedImage: UIImage?

    var body: some View {
        Group {
            if let cachedImage {
                Image(uiImage: cachedImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(baby.name.prefix(1).uppercased())
                    .font(.system(size: size * 0.45, weight: .semibold, design: .rounded).relativeTo(.body))
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(MCColor.accent.gradient)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(MCColor.accent.opacity(0.3), lineWidth: 1))
        .task(id: baby.photoData) {
            guard let data = baby.photoData else { cachedImage = nil; return }
            cachedImage = await Task.detached(priority: .userInitiated) {
                UIImage(data: data)
            }.value
        }
    }
}

#Preview("With initial") {
    BabyAvatarView(baby: Baby.fixture(name: "Emma"), size: 60)
}

#Preview("Large") {
    BabyAvatarView(baby: Baby.fixture(name: "Noah"), size: 120)
}
