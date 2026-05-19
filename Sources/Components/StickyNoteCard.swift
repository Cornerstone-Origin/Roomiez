import SwiftUI

/// Sticky-note style card with a slight tilt and dog-ear corner.
struct StickyNoteCard: View {
    var note: Note
    var assignee: RoomieUser?
    var onTap: () -> Void
    var onToggle: (NoteTodo) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.cozyHeadline)
                    .foregroundStyle(Theme.Palette.text)
                    .lineLimit(2)
                Spacer(minLength: 4)
                if note.pinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.Palette.text.opacity(0.55))
                }
            }

            if !note.body.isEmpty {
                Text(note.body)
                    .font(.cozyBody)
                    .foregroundStyle(Theme.Palette.text.opacity(0.85))
                    .lineLimit(4)
            }

            if !note.todos.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(note.todos.prefix(3)) { todo in
                        Button {
                            Haptics.soft()
                            onToggle(todo)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: todo.done
                                      ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(todo.done
                                                     ? Theme.Palette.text
                                                     : Theme.Palette.text.opacity(0.55))
                                Text(todo.text)
                                    .font(.cozyCaption)
                                    .strikethrough(todo.done)
                                    .foregroundStyle(Theme.Palette.text.opacity(todo.done ? 0.5 : 0.9))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    if note.todos.count > 3 {
                        Text("+\(note.todos.count - 3) more")
                            .font(.cozyTag)
                            .foregroundStyle(Theme.Palette.text.opacity(0.55))
                    }
                }
            }

            HStack {
                if let assignee {
                    AvatarView(user: assignee, size: 22)
                }
                Spacer()
                Text(note.updatedAt.relative())
                    .font(.cozyTag)
                    .foregroundStyle(Theme.Palette.text.opacity(0.5))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .fill(note.color.swiftUI.opacity(0.92))

                // Dog-ear corner
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 24))
                    p.addLine(to: CGPoint(x: 24, y: 0))
                    p.addLine(to: CGPoint(x: 0, y: 0))
                    p.closeSubpath()
                }
                .fill(.white.opacity(0.55))
                .frame(width: 24, height: 24)
                .rotationEffect(.degrees(180))
                .offset(x: -110, y: -70)
                .blendMode(.softLight)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .rotationEffect(.degrees(note.rotation))
        .cozyShadow(intensity: 0.85)
        .onTapGesture { Haptics.tap(); onTap() }
        .pressable(scale: 0.98)
    }
}
