import SwiftUI

struct NotesHubView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var vm: NotesViewModel
    @State private var showingEditor = false
    /// The note currently lifted off the board into full-screen view.
    /// Replaces the previous `.sheet(item:)` editing flow so we can
    /// share a namespace with the grid card for the morph animation.
    @State private var expanded: Note? = nil
    @Namespace private var noteSpace

    /// Punchy spring with a touch of overshoot — gives the matched-
    /// geometry morph a brief "pop" that reads as the note lifting off
    /// the board before settling into the full-screen size.
    private let liftSpring = Animation.spring(response: 0.55,
                                              dampingFraction: 0.78)

    init(appState: AppState) {
        _vm = StateObject(wrappedValue: NotesViewModel(appState: appState))
    }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            PearlBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    header

                    if vm.notes.isEmpty {
                        EmptyStateView(
                            systemImage: "note.text",
                            tint: Theme.Palette.brick,
                            title: "Put a note on the fridge",
                            subtitle: "Stick a reminder, a wifi password, a movie pick — anything you'd want the whole house to see.",
                            actionTitle: "Add note"
                        ) { showingEditor = true }
                        .padding(.top, 40)
                    } else {
                        if let pinned = pinnedNotes, !pinned.isEmpty {
                            SectionHeader(title: "Pinned",
                                          systemImage: "pin.fill",
                                          tint: Theme.Palette.brick)
                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(pinned) { note in tile(for: note) }
                            }
                        }

                        SectionHeader(title: "All notes",
                                      systemImage: "note.text",
                                      tint: Theme.Palette.indigo)
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(unpinnedNotes) { note in tile(for: note) }
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, FloatingButtonClearance.bottom + 60)
            }
            .refreshable { await vm.load() }
            // Grid dims + blurs while a note is expanded — sells the
            // "lifted off the board" feel by pushing the board back.
            .blur(radius: expanded != nil ? 8 : 0)
            .scaleEffect(expanded != nil ? 0.94 : 1)
            .opacity(expanded != nil ? 0.55 : 1)
            .animation(liftSpring, value: expanded?.id)

            FloatingAddButton { showingEditor = true }
                .padding(.trailing, 20).padding(.bottom, FloatingButtonClearance.bottom)
                .opacity(expanded != nil ? 0 : 1)
                .animation(liftSpring, value: expanded?.id)

            // Expanded-note overlay — appears in the same view hierarchy
            // as the grid so `matchedGeometryEffect` can morph between
            // the tile and the full-screen surface.
            if let note = expanded {
                // Tap-anywhere-to-close scrim behind the expanded note.
                Color.black.opacity(0.32)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { closeExpanded(note) }

                ExpandedNoteView(
                    note: note,
                    onClose:       { updated in closeExpanded(updated) },
                    onTogglePin:   { Task { await vm.togglePin(note) } },
                    onDelete:      {
                        Task { await vm.remove(note) }
                        closeExpanded(note)
                    }
                )
                // Expanded view becomes the geometric anchor (isSource:
                // true, the default) while the source tile becomes non-
                // source via the `isSource: !isLifted` on the tile.
                .matchedGeometryEffect(id: note.id, in: noteSpace)
                .padding(.horizontal, 16)
                .padding(.vertical, 60)
                .transition(.identity)   // matched geometry handles the morph
                .zIndex(2)
            }
        }
        .task { await vm.load() }
        .sheet(isPresented: $showingEditor) {
            NoteEditorSheet(initial: nil) { note in
                Task { await vm.add(note) }
            }
            .presentationDetents([.large])
            .presentationCornerRadius(28)
        }
    }

    /// Persist any edits, then collapse the expansion in one animated
    /// transaction so the matched-geometry morph runs in reverse.
    private func closeExpanded(_ updated: Note) {
        // Save only if something actually changed.
        if updated != expanded {
            Task { await vm.update(updated) }
        }
        withAnimation(liftSpring) {
            expanded = nil
        }
    }

    private var pinnedNotes: [Note]? {
        vm.notes.filter(\.pinned).sorted { $0.orderIndex < $1.orderIndex }
    }
    private var unpinnedNotes: [Note] {
        vm.notes.filter { !$0.pinned }.sorted { $0.orderIndex < $1.orderIndex }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notes Hub").font(.cozyDisplay)
                .foregroundStyle(Theme.Palette.text)
            Text("Pin, jot, and check things off — the digital fridge door.")
                .font(.cozyCaption)
                .foregroundStyle(Theme.Palette.textSoft)
        }
    }

    private func tile(for note: Note) -> some View {
        let isLifted = expanded?.id == note.id
        return StickyNoteCard(
            note: note,
            assignee: appState.member(id: note.authorId),
            onTap: { liftOff(note) },
            onToggle: { todo in Task { await vm.toggleTodo(in: note, todo: todo) } }
        )
        .matchedGeometryEffect(id: note.id, in: noteSpace,
                                isSource: !isLifted)
        // Hide the source tile while it's lifted — the expanded
        // overlay takes over its visual identity via the namespace.
        .opacity(isLifted ? 0 : 1)
        .contextMenu {
            Button {
                Task { await vm.togglePin(note) }
            } label: {
                Label(note.pinned ? "Unpin" : "Pin to top",
                      systemImage: note.pinned ? "pin.slash" : "pin")
            }
            Button(role: .destructive) {
                Task { await vm.remove(note) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .transition(.scale.combined(with: .opacity))
    }

    /// Lifts a note off the board with a punchy spring. The
    /// matched-geometry morph + the grid dim/blur run in the same
    /// animation transaction so they feel coordinated.
    private func liftOff(_ note: Note) {
        Haptics.tap()
        withAnimation(liftSpring) {
            expanded = note
        }
    }
}
