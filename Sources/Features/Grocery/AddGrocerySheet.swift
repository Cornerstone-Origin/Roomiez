import SwiftUI

struct AddGrocerySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    @State private var title: String
    @State private var brand: String
    @State private var quantity: String
    @State private var category: GroceryCategory

    private let initial: GroceryItem?
    private let onSave: (GroceryItem) -> Void

    init(initial: GroceryItem?, onSave: @escaping (GroceryItem) -> Void) {
        self.initial = initial
        self.onSave = onSave
        _title    = State(initialValue: initial?.title ?? "")
        _brand    = State(initialValue: initial?.brand ?? "")
        _quantity = State(initialValue: initial?.quantity ?? "")
        _category = State(initialValue: initial?.category ?? .produce)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Palette.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        titleCard
                        SettingsRow(title: "Category") {
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(),
                                                                   spacing: 8), count: 3),
                                spacing: 8
                            ) {
                                ForEach(GroceryCategory.allCases) { cat in
                                    Button {
                                        Haptics.soft(); category = cat
                                    } label: {
                                        VStack(spacing: 6) {
                                            Image(systemName: cat.icon)
                                                .font(.system(size: 18,
                                                              weight: .semibold))
                                            Text(cat.title).font(.cozyTag)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: Theme.Radius.sm,
                                                             style: .continuous)
                                                .fill(
                                                    category == cat
                                                    ? cat.tint
                                                    : cat.tint.opacity(0.10)
                                                )
                                        )
                                        .foregroundStyle(
                                            category == cat ? .white : cat.tint
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.lg)
                }
            }
            .navigationTitle(initial == nil ? "New item" : "Edit item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(initial == nil ? "Add" : "Save", action: save)
                        .font(.cozy(15, weight: .bold))
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var titleCard: some View {
        VStack(spacing: 10) {
            ModernInputField(
                placeholder: "Item",
                text: $title,
                systemImage: category.icon,
                iconTint: category.tint,
                font: .cozy(20, weight: .semibold)
            )
            ModernInputField(
                placeholder: "Brand (optional)",
                text: $brand,
                systemImage: "tag"
            )
            ModernInputField(
                placeholder: "Quantity (optional)",
                text: $quantity,
                systemImage: "number"
            )
        }
        .animation(Theme.Motion.spring, value: category)
    }

    private func save() {
        let item = GroceryItem(
            id: initial?.id ?? UUID(),
            householdId: appState.household.id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            brand: brand.isEmpty ? nil : brand,
            quantity: quantity.isEmpty ? nil : quantity,
            category: category,
            isChecked: initial?.isChecked ?? false,
            addedById: appState.currentUser.id,
            photoURL: initial?.photoURL,
            addedAt: initial?.addedAt ?? .now
        )
        onSave(item)
        dismiss()
    }
}
