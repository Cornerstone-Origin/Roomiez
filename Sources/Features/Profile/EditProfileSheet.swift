import SwiftUI

/// Edit-profile form for the current user. Fields:
/// • Display name · short bio
/// • Profile picture — pick from the bundled `avatarPack` (24 tiles)
///   plus a "Monogram" fallback that uses the user's initials.
/// • Accent colour (curated palette swatches)
/// • Displayed title — picked from unlocked trophies (or "Default")
struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String
    @State private var bio: String
    @State private var accentHex: String
    @State private var customTitle: String?

    private let initial: RoomieUser
    private let unlockedTrophies: [Achievement]
    private let onSave: (RoomieUser) -> Void

    private let accentChoices: [String] = [
        "FC6E51", "48CFAD", "FFCE54", "4FC1E9",
        "ED5565", "5D9CEC", "A0D468"
    ]

    init(user: RoomieUser,
         unlockedTrophies: [Achievement],
         onSave: @escaping (RoomieUser) -> Void) {
        self.initial = user
        self.unlockedTrophies = unlockedTrophies
        self.onSave = onSave
        _displayName = State(initialValue: user.displayName)
        _bio         = State(initialValue: user.bio ?? "")
        _accentHex   = State(initialValue: user.accentHex)
        _customTitle = State(initialValue: user.customTitle)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PearlBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        avatarPreview
                        nameSection
                        bioSection
                        accentSection
                        titleSection
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.md)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .font(.cozyActionStrong)
                        .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    // MARK: - Live preview

    private var avatarPreview: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(Color(hex: accentHex))
                    .frame(width: 96, height: 96)
                Text(initialsFromName)
                    .font(.cozyDisplay)
                    .foregroundStyle(.white)
            }
            Text(displayName.isEmpty ? "Your name" : displayName)
                .font(.cozyTitle)
                .foregroundStyle(Theme.Palette.text)
            Text(previewTitle)
                .font(.cozyCaption)
                .padding(.horizontal, 12).padding(.vertical, 4)
                .overlay(Capsule().stroke(Theme.Palette.divider, lineWidth: 1))
                .foregroundStyle(Theme.Palette.text)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Other fields

    private var nameSection: some View {
        SettingsRow(title: "Display name") {
            ModernInputField(
                placeholder: "Your name",
                text: $displayName,
                systemImage: "person.fill",
                iconTint: Color(hex: accentHex)
            )
        }
    }

    private var bioSection: some View {
        SettingsRow(title: "Bio") {
            ModernInputField(
                placeholder: "Say something about yourself",
                text: $bio,
                systemImage: "quote.opening",
                iconTint: Color(hex: accentHex),
                multiline: true,
                lineLimit: 2...4
            )
        }
    }

    private var accentSection: some View {
        SettingsRow(title: "Accent colour") {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 10),
                    count: 7
                ),
                spacing: 10
            ) {
                ForEach(accentChoices, id: \.self) { hex in
                    accentSwatch(hex: hex)
                }
            }
        }
    }

    private func accentSwatch(hex: String) -> some View {
        let isSelected = hex == accentHex
        return Button {
            Haptics.soft()
            accentHex = hex
        } label: {
            ZStack {
                Circle().fill(Color(hex: hex))
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(height: 36)
            .overlay(
                Circle().stroke(
                    isSelected ? Theme.Palette.text : Theme.Palette.divider,
                    lineWidth: isSelected ? 2 : 1
                )
            )
        }
        .buttonStyle(.plain)
    }

    /// Title chosen from unlocked trophies — no free text.
    private var titleSection: some View {
        SettingsRow(title: "Displayed title") {
            VStack(spacing: 8) {
                titleRow(
                    icon: "rosette",
                    tint: Theme.Palette.text,
                    title: "Default",
                    subtitle: initial.levelTitle,
                    isSelected: customTitle == nil
                ) {
                    customTitle = nil
                }

                if unlockedTrophies.isEmpty {
                    Text("Unlock trophies in the Trophy room to earn titles you can wear here.")
                        .font(.cozyTag)
                        .foregroundStyle(Theme.Palette.textSoft)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                } else {
                    ForEach(unlockedTrophies) { trophy in
                        titleRow(
                            icon: trophy.icon,
                            tint: trophy.tint,
                            title: trophy.title,
                            subtitle: trophy.blurb,
                            isSelected: customTitle == trophy.title
                        ) {
                            customTitle = trophy.title
                        }
                    }
                }
            }
        }
    }

    private func titleRow(icon: String,
                          tint: Color,
                          title: String,
                          subtitle: String,
                          isSelected: Bool,
                          onTap: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            onTap()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 38, height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.sm,
                                         style: .continuous)
                            .fill(tint.opacity(0.12))
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.cozyAction)
                        .foregroundStyle(Theme.Palette.text)
                    Text(subtitle)
                        .font(.cozyTag)
                        .foregroundStyle(Theme.Palette.textSoft)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isSelected ? tint : Theme.Palette.textSoft.opacity(0.6))
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                    .fill(Theme.Palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                    .stroke(
                        isSelected ? tint.opacity(0.55) : Theme.Palette.divider,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Computed

    /// Monogram derived from the (edited) display name. Used when the
    /// user picks the "Monogram" option in the avatar picker.
    private var initialsFromName: String {
        let parts = displayName.split(separator: " ").prefix(2)
        let auto = parts.compactMap { $0.first.map(String.init) }
                        .joined()
                        .uppercased()
        return auto.isEmpty ? "?" : auto
    }

    private var previewTitle: String {
        customTitle ?? initial.levelTitle
    }

    // MARK: - Save

    private func save() {
        var updated = initial
        updated.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.accentHex   = accentHex
        let trimmedBio      = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.bio         = trimmedBio.isEmpty ? nil : trimmedBio
        updated.customTitle = customTitle
        onSave(updated)
        dismiss()
    }
}
