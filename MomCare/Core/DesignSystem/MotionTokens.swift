import Pow
import SwiftUI

// MARK: - Transition Tokens

enum MCTransition {
    static var cardAppear: AnyTransition { .movingParts.pop }
    static var cardDismiss: AnyTransition { .movingParts.vanish }
    static var listInsert: AnyTransition { .movingParts.move(edge: .bottom) }
    static var listRemove: AnyTransition { .movingParts.poof }
    static var sheetPresent: AnyTransition { .movingParts.blur }
    static var heroReveal: AnyTransition { .movingParts.iris() }
    static var sectionExpand: AnyTransition { .movingParts.blinds }
}

// MARK: - Effect View Modifiers

extension View {
    func mcGlow<V: Equatable>(color: Color, trigger: V) -> some View {
        self.changeEffect(.glow(color: color), value: trigger)
    }

    func mcCelebrate<V: Equatable>(trigger: V) -> some View {
        self.changeEffect(
            .spray(origin: UnitPoint(x: 0.5, y: 0.5)) {
                Image(systemName: "sparkle")
                    .foregroundStyle(.white)
            },
            value: trigger
        )
    }

    func mcShine<V: Equatable>(trigger: V) -> some View {
        self.changeEffect(.shine, value: trigger)
    }

    func mcShake<V: Equatable>(trigger: V) -> some View {
        self.changeEffect(.shake, value: trigger)
    }

    func mcRise<V: Equatable>(trigger: V) -> some View {
        self.changeEffect(
            .rise(origin: .center) {
                Image(systemName: "sparkle")
                    .foregroundStyle(.white)
            },
            value: trigger
        )
    }

    func mcJump<V: Equatable>(trigger: V) -> some View {
        self.changeEffect(.jump(height: 50), value: trigger)
    }
}
