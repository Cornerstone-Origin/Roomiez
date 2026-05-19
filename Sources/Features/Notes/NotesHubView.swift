import SwiftUI

struct NotesHubView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var vm: NotesViewModel
    @State private var showingEditor = false
    @State private var editing: Note? = nil

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

            FloatingAddButton { showingEditor = true }
                .padding(.trailing, 20).padding(.bottom, FloatingButtonClearance.bottom)
        }
        .task { await vm.load() }
        .sheet(isPresented: $showingEditor) {
            NoteEditorSheet(initial: nil) { note in
                Task { await vm.add(note) }
            }
            .presentationDetents([.large])
            .presentationCornerRadius(28)
        }
        .sheet(item: $editing) { note in
            NoteEditorSheet(initial: note) { updated in
                Task { await vm.update(updated) }
            }
            .presentationDetents([.large])
            .presentationCornerRadius(28)
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
        StickyNoteCard(
            note: note,
            assignee: appState.member(id: note.authorId),
            onTap: { editing = note },
            onToggle: { todo in Task { await vm.toggleTodo(in: note, todo: todo) } }
        )
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
}
