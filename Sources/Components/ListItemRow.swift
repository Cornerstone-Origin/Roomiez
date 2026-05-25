import SwiftUI

/// Compact list row matching the grocery-item style. Self-contained
/// white card: leading colour IconBadge · title + subtitle · optional
/// trailing content · chevron.
struct ListItemRow<Trailing: View>: View {
    var icon: String                // SF Symbol name
    var tint: Color
    var title: String
    var subtitle: String? = nil
    var showsChevron: Bool = true
    @ViewBuilder var trailing: () -> Trailing
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                IconBadge(systemName: icon, tint: tint,
                          size: .sm, style: .solid)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.cozyAction)
                        .foregroundStyle(Theme.Palette.text)
                        .lineLimit(1)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.cozyCaption)
                            .foregroundStyle(Theme.Palette.textSoft)
                            .lineLimit(1)
                    }
                }
                Spacer()
                trailing()
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Palette.textSoft)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                // Soft floating shadow on the white surface — replaces
                // the glass-border treatment so the row reads as
                // elevated rather than outlined.
                RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                    .fill(Theme.Palette.surface)
                    .shadow(color: Color.black.opacity(0.08),
                            radius: 8, x: 0, y: 4)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .pressable(scale: 0.98)
    }
}

extension ListItemRow where Trailing == EmptyView {
    init(icon: String,
         tint: Color,
         title: String,
         subtitle: String? = nil,
         showsChevron: Bool = true,
         onTap: @escaping () -> Void = {}) {
        self.icon = icon
        self.tint = tint
        self.title = title
        self.subtitle = subtitle
        self.showsChevron = showsChevron
        self.trailing = { EmptyView() }
        self.onTap = onTap
    }
}

/// Container holding spaced white rows — mirrors the grocery page's
/// `categorySection`. When a `tint` is passed, fills softly with that
/// colour (grocery categories). When `tint` is nil, renders as a clean
/// hairline-bordered group so sections still have a defined edge on
/// the pearl background without piling colours.
struct ListCard<Content: View>: View {
    var tint: Color? = nil
    var radius: CGFloat = Theme.Radius.lg
    @ViewBuilder var content: () -> Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        VStack(spacing: 10) {
            content()
        }
        .padding(14)
        .background(
            shape.fill(
                tint?.opacity(0.18) ?? Theme.Palette.surface.opacity(0.6)
            )
        )
        .overlay(
            shape.stroke(
                tint?.opacity(0.35) ?? Theme.Palette.hairline,
                lineWidth: 1
            )
        )
        .clipShape(shape)
    }
}

/// Kept for backwards compatibility — no longer needed since
/// `ListCard` now spaces its children automatically.
struct RowDivider: View {
    var leadingInset: CGFloat = 58
    var body: some View { EmptyView() }
}
