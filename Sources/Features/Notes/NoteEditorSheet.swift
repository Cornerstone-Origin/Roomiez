import SwiftUI

struct NoteEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    @State private var title: String
    @State private var bodyText: String
    @State private var color: NoteColor
    @State private var pinned: Bool
    @State private var todos: [NoteTodo]
    @State private var newTodo: String = ""

    private let initial: Note?
    private let onSave: (Note) -> Void

    init(initial: Note?, onSave: @escaping (Note) -> Void) {
        self.initial = initial
        self.onSave = onSave
        _title    = State(initialValue: initial?.title ?? "")
        _bodyText = State(initialValue: initial?.body ?? "")
        _color    = State(initialValue: initial?.color ?? .coral)
        _pinned   = State(initialValue: initial?.pinned ?? false)
        _todos    = State(initialValue: initial?.todos ?? [])
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Palette.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        notePreview
                        SettingsRow(title: "Color") { colorPicker }
                        SettingsRow(title: "Todos") { todoEditor }
                        Toggle("Pin to top", isOn: $pinned)
                            .padding(.horizontal, 16)
                            .tint(Theme.Palette.coral)
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.lg)
                }
            }
            .navigationTitle(initial == nil ? "New note" : "Edit note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .font(.cozyActionStrong)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty &&
                                  bodyText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    // MARK: - Note preview / editor

    private var notePreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Title", text: $title)
                .font(.cozyTitle)
            TextField("What's on your mind?", text: $bodyText, axis: .vertical)
                .font(.cozyBody)
                .lineLimit(3...10)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(color.swiftUI.opacity(0.92))
        )
        .cozyShadow()
    }

    private var colorPicker: some View {
        HStack(spacing: 10) {
            ForEach(NoteColor.allCases, id: \.self) { c in
                Button {
                    Haptics.soft(); color = c
                } label: {
                    Circle()
                        .fill(c.swiftUI)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle().stroke(
                                Theme.Palette.text.opacity(color == c ? 0.6 : 0.1),
                                lineWidth: color == c ? 3 : 1
                            )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var todoEditor: some View {
        VStack(spacing: 10) {
            ForEach($todos) { $todo in
                HStack {
                    Button {
                        Haptics.soft()
                        todo.done.toggle()
                    } label: {
                        Image(systemName: todo.done ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(todo.done
                                             ? Theme.Palette.teal
                                             : Theme.Palette.text.opacity(0.4))
                    }
                    .buttonStyle(.plain)

                    TextField("Todo", text: $todo.text)
                        .strikethrough(todo.done)
                        .foregroundStyle(Theme.Palette.text.opacity(todo.done ? 0.5 : 1))

                    Button(role: .destructive) {
                        if let idx = todos.firstIndex(where: { $0.id == todo.id }) {
                            todos.remove(at: idx)
                        }
                    } label: {
                        Image(systemName: "minus.circle")
                            .foregroundStyle(Theme.Palette.coral.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Theme.Palette.teal)
                TextField("Add a todo", text: $newTodo)
                    .submitLabel(.done)
                    .onSubmit {
                        let trimmed = newTodo.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        todos.append(.init(id: UUID(), text: trimmed, done: false))
                        newTodo = ""
                    }
            }
        }
    }

    private func save() {
        let now = Date.now
        let note = Note(
            id: initial?.id ?? UUID(),
            householdId: appState.household.id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            body: bodyText,
            color: color,
            todos: todos,
            rotation: initial?.rotation ?? Double.random(in: -2.5...2.5),
            orderIndex: initial?.orderIndex ?? Int(now.timeIntervalSince1970),
            authorId: appState.currentUser.id,
            pinned: pinned,
            createdAt: initial?.createdAt ?? now,
            updatedAt: now
        )
        onSave(note)
        dismiss()
    }
}
