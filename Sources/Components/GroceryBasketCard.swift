import SwiftUI

/// Wicker-style grocery basket tile. Custom silhouette + woven texture
/// + curved handle so it actually reads as a basket rather than a
/// rounded rectangle. Holds one category's items.
struct GroceryBasketCard: View {
    var category: GroceryCategory
    var items: [GroceryItem]
    var onToggle: (GroceryItem) -> Void
    var onTapItem: (GroceryItem) -> Void
    var onRemove: (GroceryItem) -> Void

    private let maxVisibleItems = 6

    // Palette derived from the category tint, warmed toward wicker.
    private var rim:        Color { category.tint.darker(by: 0.20) }
    private var weaveDark:  Color { category.tint.darker(by: 0.30) }
    private var weaveLight: Color { category.tint.darker(by: 0.05) }
    private var handle:     Color { category.tint.darker(by: 0.35) }

    private var remaining: Int { items.filter { !$0.isChecked }.count }
    private var bought:    Int { items.count - remaining }
    private var progress:  Double {
        items.isEmpty ? 0 : Double(bought) / Double(items.count)
    }

    var body: some View {
        VStack(spacing: -2) {
            handleArc
                .frame(height: 28)
                .zIndex(2)
            basketBody
                .zIndex(1)
        }
    }

    // MARK: - Handle

    /// Curved cane handle arching over the rim.
    private var handleArc: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                // Outer (darker) cane
                Path { p in
                    p.move(to: CGPoint(x: w * 0.22, y: h))
                    p.addQuadCurve(
                        to: CGPoint(x: w * 0.78, y: h),
                        control: CGPoint(x: w * 0.5,  y: -h * 0.30)
                    )
                }
                .stroke(handle,
                        style: StrokeStyle(lineWidth: 7,
                                           lineCap: .round,
                                           lineJoin: .round))
                // Inner highlight
                Path { p in
                    p.move(to: CGPoint(x: w * 0.22, y: h))
                    p.addQuadCurve(
                        to: CGPoint(x: w * 0.78, y: h),
                        control: CGPoint(x: w * 0.5,  y: -h * 0.30)
                    )
                }
                .stroke(weaveLight.opacity(0.55),
                        style: StrokeStyle(lineWidth: 2,
                                           lineCap: .round,
                                           lineJoin: .round))
            }
        }
    }

    // MARK: - Basket body

    private var basketBody: some View {
        ZStack(alignment: .top) {
            // Trapezoid silhouette + rim, clipped to the basket shape.
            BasketBodyShape()
                .fill(category.tint.opacity(0.22))
                .overlay(
                    rimStrip
                        .clipShape(BasketBodyShape())
                )
                .overlay(
                    BasketBodyShape()
                        .stroke(rim.opacity(0.65), lineWidth: 1.5)
                )

            content
                .padding(.top, 22)         // clear the rim strip
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
        }
        .compositingGroup()
        .shadow(color: category.tint.opacity(0.20),
                radius: 6, x: 0, y: 4)
    }

    /// Solid darker band along the very top — the basket's rim/lip.
    private var rimStrip: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [rim, rim.opacity(0.85), category.tint],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 14)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Inner content

    private var content: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            Rectangle()
                .fill(weaveDark.opacity(0.35))
                .frame(height: 1)
            itemsList
            if items.count > maxVisibleItems {
                Text("+\(items.count - maxVisibleItems) more")
                    .font(.cozyTag)
                    .foregroundStyle(Theme.Palette.text.opacity(0.6))
            }
            Spacer(minLength: 0)
            progressBar
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: category.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(category.tint)
                .frame(width: 36, height: 36)
                .background(
                    Circle().fill(Theme.Palette.surface)
                )
                .overlay(
                    Circle().stroke(rim.opacity(0.55), lineWidth: 1)
                )
            VStack(alignment: .leading, spacing: 1) {
                Text(category.title)
                    .font(.cozyHeadline)
                    .foregroundStyle(Theme.Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("\(remaining) left")
                    .font(.cozyTag)
                    .foregroundStyle(Theme.Palette.text.opacity(0.6))
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var itemsList: some View {
        if items.isEmpty {
            Text("Basket's empty.")
                .font(.cozyCaption)
                .foregroundStyle(Theme.Palette.text.opacity(0.55))
        } else {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(items.prefix(maxVisibleItems)) { item in
                    itemRow(item)
                }
            }
        }
    }

    private func itemRow(_ item: GroceryItem) -> some View {
        HStack(spacing: 8) {
            Button {
                Haptics.soft()
                withAnimation(Theme.Motion.snappy) { onToggle(item) }
            } label: {
                Image(systemName: item.isChecked
                      ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(item.isChecked
                                     ? rim
                                     : Theme.Palette.text.opacity(0.35))
            }
            .buttonStyle(.plain)

            Text(item.title)
                .font(.cozyCaption)
                .strikethrough(item.isChecked)
                .foregroundStyle(Theme.Palette.text
                                 .opacity(item.isChecked ? 0.45 : 1))
                .lineLimit(1)

            Spacer(minLength: 0)

            if let qty = item.quantity, !qty.isEmpty {
                Text(qty)
                    .font(.cozyTag)
                    .foregroundStyle(Theme.Palette.text.opacity(0.55))
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

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(weaveDark.opacity(0.20))
                Capsule()
                    .fill(rim)
                    .frame(width: max(6, proxy.size.width * progress))
            }
        }
        .frame(height: 5)
    }
}

// MARK: - Basket silhouette

/// Trapezoid-ish basket body: top is square-cornered (the rim sits on
/// it), the bottom is slightly narrower with rounded corners.
private struct BasketBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let inset = rect.width * 0.06                 // bottom 12% narrower
        let topCorner: CGFloat = 10
        let bottomCorner: CGFloat = 18

        // Top edge with light rounding
        p.move(to: CGPoint(x: topCorner, y: 0))
        p.addLine(to: CGPoint(x: rect.maxX - topCorner, y: 0))
        p.addArc(
            center: CGPoint(x: rect.maxX - topCorner, y: topCorner),
            radius: topCorner,
            startAngle: .degrees(-90), endAngle: .degrees(0),
            clockwise: false
        )

        // Right side — angles inward toward the base
        p.addLine(to: CGPoint(x: rect.maxX - inset,
                              y: rect.maxY - bottomCorner))
        // Bottom-right corner
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX - inset - bottomCorner * 0.4,
                        y: rect.maxY),
            control: CGPoint(x: rect.maxX - inset, y: rect.maxY)
        )

        // Bottom edge
        p.addLine(to: CGPoint(x: rect.minX + inset + bottomCorner * 0.4,
                              y: rect.maxY))

        // Bottom-left corner
        p.addQuadCurve(
            to: CGPoint(x: rect.minX + inset,
                        y: rect.maxY - bottomCorner),
            control: CGPoint(x: rect.minX + inset, y: rect.maxY)
        )

        // Left side — angles inward
        p.addLine(to: CGPoint(x: rect.minX, y: topCorner))

        // Top-left corner
        p.addArc(
            center: CGPoint(x: topCorner, y: topCorner),
            radius: topCorner,
            startAngle: .degrees(180), endAngle: .degrees(270),
            clockwise: false
        )
        p.closeSubpath()
        return p
    }
}
