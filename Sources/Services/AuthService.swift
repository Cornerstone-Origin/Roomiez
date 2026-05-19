import Foundation
import Combine
import Supabase

/// Thin wrapper over Supabase Auth with a local-only fallback so the app
/// works offline / before credentials are wired up.
@MainActor
final class AuthService: ObservableObject {

    enum SessionState: Equatable {
        case loading
        case signedOut
        case signedIn(RoomieUser)
    }

    @Published private(set) var state: SessionState = .loading
    private let supabase = SupabaseManager.shared

    init() { Task { await bootstrap() } }

    // MARK: - Bootstrap

    func bootstrap() async {
        guard let client = supabase.client else {
            // No Supabase yet — auto sign-in with the seed "you" so the UI
            // is interactive.
            state = .signedIn(PreviewData.currentUser)
            return
        }
        do {
            let session = try await client.auth.session
            state = .signedIn(try await hydrate(userId: session.user.id))
        } catch {
            state = .signedOut
        }
    }

    // MARK: - Email / password

    func signUp(email: String, password: String, displayName: String) async throws {
        guard let client = supabase.client else {
            state = .signedIn(PreviewData.currentUser); return
        }
        let response = try await client.auth.signUp(email: email, password: password)
        let user = try await hydrate(userId: response.user.id, fallbackName: displayName)
        state = .signedIn(user)
    }

    func signIn(email: String, password: String) async throws {
        guard let client = supabase.client else {
            state = .signedIn(PreviewData.currentUser); return
        }
        let session = try await client.auth.signIn(email: email, password: password)
        state = .signedIn(try await hydrate(userId: session.user.id))
    }

    func signOut() async {
        if let client = supabase.client {
            try? await client.auth.signOut()
        }
        state = .signedOut
    }

    // MARK: - Hydration

    private func hydrate(userId: UUID, fallbackName: String = "Roomie") async throws -> RoomieUser {
        guard let client = supabase.client else { return PreviewData.currentUser }
        do {
            let profile: RoomieUser = try await client.from("users")
                .select().eq("id", value: userId).single().execute().value
            return profile
        } catch {
            // First sign-in — create a profile row.
            let accents = ["FC6E51", "48CFAD", "FFCE54", "4FC1E9", "ED5565"]
            let initials = fallbackName.split(separator: " ")
                .prefix(2)
                .compactMap { $0.first.map(String.init) }
                .joined()
                .uppercased()
            let stub = RoomieUser(
                id: userId, displayName: fallbackName,
                avatarInitials: initials.isEmpty ? "R" : initials,
                accentHex: accents.randomElement() ?? "FC6E51",
                householdId: nil, personalXP: 0,
                weeklyStreak: 0, joinedAt: .now
            )
            try await client.from("users").insert(stub).execute()
            return stub
        }
    }
}
