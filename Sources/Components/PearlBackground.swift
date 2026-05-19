import SwiftUI

/// Full-screen pearl background — soft diagonal pearl gradient only.
/// Quiet, luminous, no decorative colour orbs so foreground content
/// owns all the colour.
struct PearlBackground: View {
    var body: some View {
        Theme.Gradients.pearl
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}

/// Spacing constant for floating action buttons so they clear the
/// `CozyTabBar` and its elevated centre house hub (which extends 14pt
/// above the pill).
enum FloatingButtonClearance {
    static let bottom: CGFloat = 90
}
