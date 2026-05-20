import SwiftUI

extension View {
    /// Cards/buttons get a tactile press scale via this helper.
    func pressable(scale: CGFloat = 0.97) -> some View {
        modifier(PressableModifier(scale: scale))
    }

    /// Standard horizontal page padding.
    func screenPadding() -> some View {
        padding(.horizontal, Theme.Spacing.md)
    }

    /// Hide the keyboard from anywhere.
    func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }

    /// Soft fade + scale as the view enters/exits the scroll viewport.
    /// Subtle "lift" that makes scrolling feel alive without becoming
    /// gimmicky.
    func scrollLift(threshold: CGFloat = 0.15) -> some View {
        scrollTransition(.animated.threshold(.visible(threshold))) { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0.45)
                .scaleEffect(phase.isIdentity ? 1 : 0.93)
                .blur(radius: phase.isIdentity ? 0 : 1.5)
        }
    }

    /// Stretchy parallax — pulling down scales the view from its top
    /// anchor. Used on the hero card.
    func stretchyTop() -> some View {
        visualEffect { content, proxy in
            let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
            let pull = max(0, minY)
            return content
                .scaleEffect(1 + pull / 700, anchor: .top)
        }
    }

    /// Applies the iOS 26 Liquid Glass material tinted with the given
    /// colour, clipped to a continuous rounded rect. Falls back to a
    /// stacked `ultraThinMaterial` + soft tint overlay on older OSes so
    /// the deployment target can stay at iOS 17.
    @ViewBuilder
    func liquidGlassTile(tint: Color, radius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        if #available(iOS 26.0, *) {
            self.glassEffect(
                .regular.tint(tint.opacity(0.32)),
                in: shape
            )
        } else {
            self
                .background(shape.fill(.ultraThinMaterial))
                .overlay(shape.fill(tint.opacity(0.18)))
                .overlay(
                    shape.strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.55),
                                tint.opacity(0.35)
                            ],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                )
                .clipShape(shape)
        }
    }
}

private struct PressableModifier: ViewModifier {
    let scale: CGFloat
    @State private var pressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(pressed ? scale : 1)
            .animation(Theme.Motion.snappy, value: pressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pressed = true }
                    .onEnded   { _ in pressed = false }
            )
    }
}

extension Binding {
    /// Lets us write `$state.optional(default: …)` for non-optional bindings.
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: {
                wrappedValue = $0
                handler($0)
            }
        )
    }
}
