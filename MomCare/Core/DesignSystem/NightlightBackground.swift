import SwiftUI

struct NightlightBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { proxy in
                    MCGradient.canvas(height: proxy.size.height)
                }
                .ignoresSafeArea()
            }
    }
}

extension View {
    func nightlightBackground() -> some View {
        modifier(NightlightBackground())
    }
}
