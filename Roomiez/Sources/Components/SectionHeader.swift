import SwiftUI

struct SectionHeader: View {
    var title: String
    /// SF Symbol name; nil hides the leading icon.
    var systemImage: String? = nil
    var tint: Color = Theme.Palette.indigo
    var trailingTitle: String? = nil
    var trailingAction: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 22, height: 22)
                    .background(
                        Circle().fill(tint.opacity(0.14))
                    )
            }
            Text(title)
                .font(.cozyHeadline)
                .foregroundStyle(Theme.Palette.text)
            Spacer()
            if let trailingTitle, let trailingAction {
                Button(action: trailingAction) {
                    HStack(spacing: 4) {
                        Text(trailingTitle).font(.cozyCaption)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Theme.Palette.textSoft)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
    }
}

struct EmptyStateView: View {
    /// SF Symbol shown in the centered medallion.
    var systemImage: String
    var tint: Color = Theme.Palette.indigo
    var title: String
    var subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: systemImage)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(tint)
            }
            Text(title)
                .font(.cozyHeadline)
                .foregroundStyle(Theme.Palette.text)
            Text(subtitle)
                .font(.cozyBody)
                .foregroundStyle(Theme.Palette.textSoft)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, style: .soft,
                              tint: tint,
                              fullWidth: false, action: action)
                    .padding(.top, 4)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
    }
}

struct CozyDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.Palette.divider)
            .frame(height: 1)
    }
}
