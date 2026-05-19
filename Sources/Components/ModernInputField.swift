import SwiftUI

/// Clean white input field — soft rounded rectangle with a hairline
/// border, optional leading icon. Replaces the heavier tinted-card text
/// fields on the create-chore / create-grocery sheets.
struct ModernInputField: View {
    var placeholder: String
    @Binding var text: String
    var systemImage: String? = nil
    /// Colour for the leading icon. Defaults to the soft text tone; pass
    /// a brand colour if the icon represents a category being previewed.
    var iconTint: Color? = nil
    var font: Font = .cozyBody
    var keyboard: UIKeyboardType = .default
    var multiline: Bool = false
    var lineLimit: ClosedRange<Int> = 2...5

    var body: some View {
        HStack(alignment: multiline ? .top : .center, spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconTint ?? Theme.Palette.textSoft)
                    .frame(width: 20)
                    .padding(.top, multiline ? 4 : 0)
            }

            Group {
                if multiline {
                    TextField(placeholder, text: $text, axis: .vertical)
                        .lineLimit(lineLimit)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboard)
                }
            }
            .font(font)
            .foregroundStyle(Theme.Palette.text)
            .tint(Theme.Palette.coral)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .fill(Theme.Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .stroke(Theme.Palette.divider, lineWidth: 1)
        )
    }
}
