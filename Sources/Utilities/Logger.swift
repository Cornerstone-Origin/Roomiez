import os
import OSLog

/// Wrapper around `OSLog`'s `Logger`. Loggers are `Sendable`, so the static
/// constants are safe to read from any isolation domain.
enum Log {
    static let app      = Logger(subsystem: "com.roomiez.app", category: "app")
    static let net      = Logger(subsystem: "com.roomiez.app", category: "network")
    static let supabase = Logger(subsystem: "com.roomiez.app", category: "supabase")
    static let realtime = Logger(subsystem: "com.roomiez.app", category: "realtime")
}
