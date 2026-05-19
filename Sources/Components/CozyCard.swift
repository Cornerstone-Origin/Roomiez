import SwiftUI

/// Flat tinted card — same look as a grocery category section.
/// Soft tint fill, hairline tint stroke, no shadow, no glass.
struct CozyCard<Content: View>: View {
    var tint: Color? = nil
    var padding: CGFloat = Theme.Spacing.lg
    var radius: CGFloat = Theme.Radius.lg
    @ViewBuilder var content: () -> Content

    var body: some View {
        let resolvedTint = tint ?? Theme.Palette.periwinkle
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        ZStack {
            shape.fill(resolvedTint.opacity(0.18))
            content().padding(padding)
        }
        .overlay(shape.stroke(resolvedTint.opacity(0.35), lineWidth: 1))
        .clipShape(shape)
    }
}
