import SwiftUI

/// Bottom navigation bar with an elevated centre "house" hub button.
/// Layout: Chores · Grocery · [HOUSE] · Notes · You
struct CozyTabBar: View {
    @Binding var selected: AppTab
    @Namespace private var indicator

    var body: some View {
        HStack(spacing: 0) {
            sideTab(.chores)
            sideTab(.grocery)
            Color.clear.frame(width: 66, height: 1)   // reserve for hub
            sideTab(.notes)
            sideTab(.profile)
        }
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(.white.opacity(0.55), lineWidth: 1)
        )
        .floatingShadow()
        .overlay(alignment: .top) {
            houseButton.offset(y: -14)
        }
    }

    // MARK: - Centre house button

    private var houseButton: some View {
        let isActive = selected == .dashboard
        return Button {
            Haptics.medium()
            withAnimation(Theme.Motion.spring) { selected = .dashboard }
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle().fill(
                            LinearGradient(
                                colors: [
                                    Theme.Palette.coral.opacity(0.62),
                                    Theme.Palette.azure.opacity(0.62)
                                ],
                                startPoint: .topLeading,
                                endPoint:   .bottomTrailing
                            )
                        )
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(
                                .white.opacity(isActive ? 0.85 : 0.55),
                                lineWidth: 1
                            )
                    )
                    .frame(width: 54, height: 54)
                    .shadow(color: Color.black.opacity(0.08),
                            radius: 5, x: 0, y: 3)

                Image(systemName: "house.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .pressable(scale: 0.92)
        .scaleEffect(isActive ? 1.03 : 1)
        .animation(Theme.Motion.spring, value: isActive)
    }

    // MARK: - Side tab buttons

    private func sideTab(_ tab: AppTab) -> some View {
        Button {
            Haptics.selection()
            withAnimation(Theme.Motion.spring) { selected = tab }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if selected == tab {
                        Circle()
                            .fill(tab.tint.opacity(0.85))
                            .frame(width: 34, height: 34)
                            .matchedGeometryEffect(id: "bg", in: indicator)
                    }
                    Image(systemName: tab.icon)
                        .font(.system(size: 16,
                                      weight: selected == tab ? .bold : .medium))
                        .foregroundStyle(
                            selected == tab
                                ? Theme.Palette.text
                                : Theme.Palette.text.opacity(0.55)
                        )
                }
                .frame(height: 34)
                Text(tab.title)
                    .font(.cozy(10, weight: .semibold))
                    .foregroundStyle(
                        selected == tab
                            ? Theme.Palette.text
                            : Theme.Palette.textSoft
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}
