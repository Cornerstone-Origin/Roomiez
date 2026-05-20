import Foundation
import os
import Supabase

/// Subscribes to Supabase Realtime so chores / grocery / notes update live
/// across roommates' phones. Falls back to a no-op when Supabase isn't
/// configured.
@MainActor
final class RealtimeService {

    private let manager: SupabaseManager
    private var channels: [RealtimeChannelV2] = []
    private var listeners: [Task<Void, Never>] = []

    init(manager: SupabaseManager = .shared) { self.manager = manager }

    /// Start subscriptions for a household. `onChange` fires every time a
    /// row in any of the household-scoped tables changes.
    func start(for householdId: UUID,
               onChange: @escaping @Sendable () -> Void) async {
        guard let client = manager.client else { return }
        await stop()

        let tables = ["chores", "grocery_items", "notes",
                      "activity_events", "achievements", "households",
                      "chore_groups", "chore_group_members"]

        for table in tables {
            let channel = client.channel("public:\(table):\(householdId.uuidString)")
            let stream  = channel.postgresChange(
                AnyAction.self,
                schema: "public", table: table
            )
            channels.append(channel)

            let task = Task { @MainActor in
                for await _ in stream {
                    onChange()
                }
            }
            listeners.append(task)

            await channel.subscribe()
        }
        Log.realtime.info("Realtime: \(self.channels.count) channels active")
    }

    func stop() async {
        for task in listeners { task.cancel() }
        listeners.removeAll()
        for ch in channels { await ch.unsubscribe() }
        channels.removeAll()
    }
}
