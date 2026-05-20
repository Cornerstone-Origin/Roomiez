import SwiftUI

struct GroceryItemRow: View {
    var item: GroceryItem
    var addedBy: RoomieUser?
    var onToggle: () -> Void
    var onTap: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Checkbox
            Button {
                Haptics.soft()
                withAnimation(Theme.Motion.bouncy) { onToggle() }
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(item.isChecked
                                      ? Theme.Palette.teal
                                      : Theme.Palette.text.opacity(0.18),
                                      lineWidth: 2)
                        .background(
                            Circle().fill(item.isChecked
                                          ? Theme.Palette.teal
                                          : Color.clear)
                        )
                        .frame(width: 26, height: 26)

                    if item.isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            // Item
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.title)
                        .font(.cozyBody)
                        .strikethrough(item.isChecked)
                        .foregroundStyle(Theme.Palette.text
                                         .opacity(item.isChecked ? 0.45 : 1))
                    if let qty = item.quantity, !qty.isEmpty {
                        Text("· \(qty)")
                            .font(.cozyCaption)
                            .foregroundStyle(Theme.Palette.textSoft)
                    }
                }
                if let brand = item.brand, !brand.isEmpty {
                    Text(brand)
                        .font(.cozyTag)
                        .foregroundStyle(Theme.Palette.textSoft)
                }
            }

            Spacer()

            if let addedBy {
                AvatarView(user: addedBy, size: 22, showsRing: false)
                    .opacity(0.85)
            }
        }
        .padding(.vertical, 10).padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .fill(Theme.Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .stroke(Theme.Palette.divider, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}
