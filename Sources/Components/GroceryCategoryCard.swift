import SwiftUI

/// Grocery category tile rendered as a glass card — same recipe as
/// `ChoreCard` (white surface + glass-border stroke + flat-icon
/// header) so the Grocery grid feels visually consistent with the
/// Chores tab. Holds one category's items.
struct GroceryCategoryCard: View {
    var category: GroceryCategory
    var items: [GroceryItem]
    var onToggle: (GroceryItem) -> Void
    var onTapItem: (GroceryItem) -> Void
    var onRemove: (GroceryItem) -> Void

    private let maxVisibleItems = 6

    private var remaining: Int { items.filter { !$0.isChecked }.count }
    private var bought:    Int { items.count - remaining }
    private var progress:  Double {
        items.isEmpty ? 0 : Double(bought) / Double(items.count)
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.md,
                                     style: .continuous)
        return ZStack {
            shape.fill(Theme.Palette.surface)
            VStack(alignment: .leading, spacing: 10) {
                header
                Rectangle()
                    .fill(category.tint.opacity(0.20))
                    .frame(height: 1)
                itemsList
                if items.count > maxVisibleItems {
                    Text("+\(items.count - maxVisibleItems) more")
                        .font(.cozyTag)
                        .foregroundStyle(Theme.Palette.textSoft)
                }
                // Only show the progress bar once at least one item
                // has been bought — otherwise it reads as a smudge.
                if bought > 0 {
                    progressBar
                        .padding(.top, 2)
                }
            }
            .padding(14)
        }
        .overlay(shape.stroke(Theme.Gradients.glassBorder, lineWidth: 1.2))
        .clipShape(shape)
    }

    // MARK: - Header

    /// Flat icon recipe — 38pt rounded square with `tint.opacity(0.12)`
    /// fill and the tint glyph, matching the chore card / today
    /// section / recent updates pattern across the app.
    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: category.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(category.tint)
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm,
                                     style: .continuous)
                        .fill(category.tint.opacity(0.12))
                )
            VStack(alignment: .leading, spacing: 1) {
                Text(category.title)
                    .font(.cozyHeadline)
                    .foregroundStyle(Theme.Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("\(remaining) left")
                    .font(.cozyTag)
                    .foregroundStyle(Theme.Palette.textSoft)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Item list

    @ViewBuilder
    private var itemsList: some View {
        if items.isEmpty {
            Text("Nothing here yet.")
                .font(.cozyCaption)
                .foregroundStyle(Theme.Palette.textSoft)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(items.prefix(maxVisibleItems)) { item in
                    itemRow(item)
                }
            }
        }
    }

    private func itemRow(_ item: GroceryItem) -> some View {
        // Surface a "NEW" pill on items that were added in the last
        // 24 hours and are still unchecked — gives roommates a
        // visual cue for what's been put on the list since they
        // last looked.
        let isNew = !item.isChecked
            && item.addedAt.timeIntervalSinceNow > -Self.newWindowSeconds
        return HStack(spacing: 8) {
            Button {
                Haptics.soft()
                withAnimation(Theme.Motion.snappy) { onToggle(item) }
            } label: {
                Image(systemName: item.isChecked
                      ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(item.isChecked
                                     ? category.tint
                                     : Theme.Palette.textMuted)
            }
            .buttonStyle(.plain)

            // Title + a small coral "newly added" sparkle glyph. The
            // glyph is an SF Symbol, so it aligns to the title's
            // text baseline naturally and can't be cut off by the
            // surrounding columns.
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if isNew {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.Palette.coral)
                        .accessibilityLabel("Newly added")
                }
                Text(item.title)
                    .font(.cozyCaption)
                    .strikethrough(item.isChecked)
                    .foregroundStyle(item.isChecked
                                     ? Theme.Palette.textMuted
                                     : Theme.Palette.text)
                    // Wrap long preset titles (e.g. "Frozen dumplings")
                    // instead of hard-truncating mid-word with an ellipsis.
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            if let qty = item.quantity, !qty.isEmpty {
                Text(qty)
                    .font(.cozyTag)
                    .foregroundStyle(Theme.Palette.textSoft)
                    .lineLimit(1)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTapItem(item) }
        .contextMenu {
            Button(role: .destructive) { onRemove(item) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Newly-added marker

    /// How recent an item has to be (in seconds) to count as "newly
    /// added" and earn the inline sparkle glyph. 24h covers a
    /// roommate checking the list once a day; bump this up if the
    /// household moves slower.
    private static let newWindowSeconds: TimeInterval = 24 * 60 * 60

    // MARK: - Progress bar

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                // More visible empty track so the bar reads as a
                // bar even when progress is low.
                Capsule()
                    .fill(category.tint.opacity(0.28))
                Capsule()
                    .fill(category.tint)
                    .frame(width: max(8, proxy.size.width * progress))
            }
        }
        .frame(height: 6)
    }
}
