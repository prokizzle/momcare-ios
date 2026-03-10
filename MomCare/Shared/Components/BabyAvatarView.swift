import SwiftUI

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
                    .font(.system(size: size * 0.45, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(MCColor.accent.gradient)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(MCColor.accent.opacity(0.3), lineWidth: 1))
        .task(id: baby.photoData) {
            cachedImage = baby.photoData.flatMap { UIImage(data: $0) }
        }
    }
}

#Preview("With initial") {
    BabyAvatarView(baby: Baby.fixture(name: "Emma"), size: 60)
}

#Preview("Large") {
    BabyAvatarView(baby: Baby.fixture(name: "Noah"), size: 120)
}
