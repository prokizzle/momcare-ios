import SwiftUI

struct BabyAvatarView: View {
    let baby: Baby
    var size: CGFloat = 40

    var body: some View {
        Group {
            if let photoData = baby.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
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
    }
}

#Preview("With initial") {
    BabyAvatarView(baby: Baby.fixture(name: "Emma"), size: 60)
}

#Preview("Large") {
    BabyAvatarView(baby: Baby.fixture(name: "Noah"), size: 120)
}
