import SwiftUI

struct NightlightBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                MCGradient.canvas()
                    .ignoresSafeArea()
            }
    }
}

extension View {
    func nightlightBackground() -> some View {
        modifier(NightlightBackground())
    }
}
