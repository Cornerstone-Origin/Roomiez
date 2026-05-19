import SwiftUI
import Combine

@MainActor
final class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var error: String?

    private let appState: AppState
    init(appState: AppState) { self.appState = appState }

    func load() async {
        do {
            notes = try await appState.noteRepo.loadNotes(
                householdId: appState.household.id
            )
        } catch { self.error = error.localizedDescription }
    }

    func add(_ note: Note) async {
        await save(note)
        await appState.logEvent(
            kind: .noteAdded, subject: note.title,
            icon: "note.text", xp: LevelService.Reward.noteCreated
        )
    }

    func update(_ note: Note) async { await save(note) }

    func togglePin(_ note: Note) async {
        var copy = note
        copy.pinned.toggle()
        copy.updatedAt = .now
        await save(copy)
    }

    func toggleTodo(in note: Note, todo: NoteTodo) async {
        var copy = note
        if let idx = copy.todos.firstIndex(where: { $0.id == todo.id }) {
            copy.todos[idx].done.toggle()
            copy.updatedAt = .now
            await save(copy)
        }
    }

    func reorder(from source: IndexSet, to dest: Int) async {
        notes.move(fromOffsets: source, toOffset: dest)
        for index in notes.indices {
            var note = notes[index]
            note.orderIndex = index
            await save(note)
        }
    }

    func remove(_ note: Note) async {
        do {
            try await appState.noteRepo.delete(note)
            notes.removeAll { $0.id == note.id }
        } catch { self.error = error.localizedDescription }
    }

    private func save(_ note: Note) async {
        do {
            let saved = try await appState.noteRepo.upsert(note)
            if let idx = notes.firstIndex(where: { $0.id == saved.id }) {
                notes[idx] = saved
            } else {
                notes.append(saved)
            }
        } catch { self.error = error.localizedDescription }
    }
}
