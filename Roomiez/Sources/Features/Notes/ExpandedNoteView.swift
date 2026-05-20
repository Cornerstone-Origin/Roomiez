import SwiftUI

/// Full-screen note view that morphs from a sticky-note tile via
/// `matchedGeometryEffect`. Designed to be rendered as an overlay in
/// `NotesHubView`, not as a sheet — sheets are presented in a separate
/// window and can't share a namespace with the underlying grid.
///
/// The visual recipe — what makes this feel like "a note taken off the
/// board and enlarged":
///   1. matchedGeometryEffect morphs size + position from the tile to
///      a near-full-screen rectangle.
///   2. The tile's random rotation (-2.5°…2.5°) animates to 0° during
///      the same spring — the note visibly straightens as it lifts.
///   3. The background gets a black dim + blur applied to the grid below.
///   4. A punchy spring (`.spring(response: 0.55, dampingFraction: 0.78)`)
///      gives a brief pop / overshoot that reads as the lift action.
struct ExpandedNoteView: View {
    let note: Note
    /// Called with the (possibly edited) note when the user closes.
    var onClose: (Note) -> Void
    var onTogglePin: () -> Void
    var onDelete: () -> Void

    @State private var title:    String
    @State private var bodyText: String
    @State private var color:    NoteColor
    @State private var todos:    [NoteTodo]
    @State private var newTodo:  String = ""

    init(note: Note,
         onClose: @escaping (Note) -> Void,
         onTogglePin: @escaping () -> Void,
         onDelete: @escaping () -> Void) {
        self.note         = note
        self.onClose      = onClose
        self.onTogglePin  = onTogglePin
        self.onDelete     = onDelete
        _title    = State(initialValue: note.title)
        _bodyText = State(initialValue: note.body)
        _color    = State(initialValue: note.color)
        _todos    = State(initialValue: note.todos)
    }

    var body: some View {
        ZStack {
            // Note "paper" — fills the whole expanded surface in the
            // chosen note colour. Sits at the bottom of the ZStack so
            // the matched-geometry morph treats this view as one solid
            // rectangle, the same shape the sticky tile is.
            RoundedRectangle(cornerRadius: Theme.Radius.lg,
                             style: .continuous)
                .fill(color.swiftUI.opacity(0.96))

            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        titleField
                        bodyField
                        todoSection
                        colorPicker
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg,
                                    style: .continuous))
        .shadow(color: .black.opacity(0.20), radius: 28, x: 0, y: 12)
    }

    // MARK: - Pieces

    private var topBar: some View {
        HStack(spacing: 14) {
            iconButton("xmark") {
                // Hand the (possibly edited) note back to the parent so
                // it can persist + collapse the overlay in a single
                // animated transaction.
                onClose(currentNoteState())
            }

            Spacer()

            iconButton(note.pinned ? "pin.slash.fill" : "pin.fill",
                       active: note.pinned) {
                onTogglePin()
            }

            iconButton("trash", tint: Theme.Palette.brick) {
                onDelete()
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 20)
        .padding(.bottom, 6)
    }

    private func iconButton(_ symbol: String,
                            active: Bool = false,
                            tint: Color = Theme.Palette.text,
                            action: @escaping () -> Void) -> some View {
        Button {
            Haptics.soft()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(tint.opacity(active ? 1 : 0.75))
                .frame(width: 38, height: 38)
                .background(
                    Circle().fill(.white.opacity(active ? 0.65 : 0.40))
                )
                .overlay(
                    Circle().stroke(.white.opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var titleField: some View {
        TextField("Title", text: $title)
            .font(.cozy(28, weight: .heavy))
            .foregroundStyle(Theme.Palette.text)
            .padding(.top, 4)
    }

    private var bodyField: some View {
        TextField("What's on your mind?", text: $bodyText, axis: .vertical)
            .font(.cozyBody)
            .foregroundStyle(Theme.Palette.text.opacity(0.92))
            .lineLimit(4...)
    }

    private var todoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !todos.isEmpty {
                Text("TODOS")
                    .font(.cozyTag)
                    .foregroundStyle(Theme.Palette.text.opacity(0.55))
            }
            ForEach($todos) { $todo in
                HStack(spacing: 10) {
                    Button {
                        Haptics.soft()
                        todo.done.toggle()
                    } label: {
                        Image(systemName: todo.done
                              ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.Palette.text.opacity(todo.done ? 0.85 : 0.45))
                    }
                    .buttonStyle(.plain)

                    TextField("Todo", text: $todo.text)
                        .strikethrough(todo.done)
                        .foregroundStyle(Theme.Palette.text.opacity(todo.done ? 0.55 : 1))

                    Button(role: .destructive) {
                        if let idx = todos.firstIndex(where: { $0.id == todo.id }) {
                            todos.remove(at: idx)
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(Theme.Palette.text.opacity(0.35))
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.Palette.text.opacity(0.65))
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
        .padding(.top, 12)
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("COLOR")
                .font(.cozyTag)
                .foregroundStyle(Theme.Palette.text.opacity(0.55))
            HStack(spacing: 12) {
                ForEach(NoteColor.allCases, id: \.self) { c in
                    Button {
                        Haptics.soft()
                        withAnimation(.spring(response: 0.35,
                                              dampingFraction: 0.75)) {
                            color = c
                        }
                    } label: {
                        Circle()
                            .fill(c.swiftUI)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle().stroke(
                                    Theme.Palette.text.opacity(color == c ? 0.8 : 0.15),
                                    lineWidth: color == c ? 3 : 1
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Helpers

    /// Snapshot of the note's current edited state for handing back to
    /// the parent on close.
    private func currentNoteState() -> Note {
        var updated = note
        updated.title     = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.body      = bodyText
        updated.color     = color
        updated.todos     = todos
        updated.updatedAt = .now
        return updated
    }
}
