import os
import OSLog

/// Wrapper around `OSLog`'s `Logger`. Loggers are `Sendable`, so the static
/// constants are safe to read from any isolation domain.
enum Log {
    nonisolated(unsafe) static let app      = Logger(subsystem: "com.roomiez.app", category: "app")
    nonisolated(unsafe) static let net      = Logger(subsystem: "com.roomiez.app", category: "network")
    nonisolated(unsafe) static let supabase = Logger(subsystem: "com.roomiez.app", category: "supabase")
    nonisolated(unsafe) static let realtime = Logger(subsystem: "com.roomiez.app", category: "realtime")
}
