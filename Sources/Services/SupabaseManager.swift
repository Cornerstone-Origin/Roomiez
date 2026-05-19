import Foundation
import Combine
import os
import Supabase

/// Central Supabase client. Reads URL + anon key from `SupabaseConfig.plist`
/// (gitignored) or from `Info.plist` keys `SUPABASE_URL` / `SUPABASE_ANON_KEY`.
///
/// If credentials are missing, `isConfigured == false` and the rest of the app
/// runs against in-memory seed data via the repository protocols.
@MainActor
final class SupabaseManager: ObservableObject {

    static let shared = SupabaseManager()

    let client: SupabaseClient?
    let isConfigured: Bool

    private init() {
        if let (url, key) = SupabaseManager.loadCredentials() {
            self.client = SupabaseClient(supabaseURL: url, supabaseKey: key)
            self.isConfigured = true
            Log.supabase.info("Supabase configured for \(url.absoluteString, privacy: .public)")
        } else {
            self.client = nil
            self.isConfigured = false
            Log.supabase.notice("Supabase NOT configured — running on seed data.")
        }
    }

    private static func loadCredentials() -> (URL, String)? {
        // 1. Prefer a dedicated plist so we don't leak keys via Info.plist.
        if let path = Bundle.main.path(forResource: "SupabaseConfig", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
           let urlString = dict["SUPABASE_URL"] as? String,
           let key       = dict["SUPABASE_ANON_KEY"] as? String,
           let url       = URL(string: urlString),
           !key.isEmpty, !urlString.contains("YOUR_") {
            return (url, key)
        }

        // 2. Fallback to Info.plist (handy for xcconfig-driven envs).
        if let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
           let key       = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
           let url       = URL(string: urlString),
           !key.isEmpty, !urlString.contains("YOUR_") {
            return (url, key)
        }

        return nil
    }
}
