import SwiftUI

extension Font {
    /// Rounded SF — gives the app its friendly, planner-app feel.
    static func cozy(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static let cozyDisplay   = Font.cozy(34, weight: .bold)
    static let cozyTitle     = Font.cozy(26, weight: .bold)
    static let cozyHeadline  = Font.cozy(20, weight: .semibold)
    static let cozyBody      = Font.cozy(16, weight: .medium)
    static let cozyCaption   = Font.cozy(13, weight: .medium)
    static let cozyTag       = Font.cozy(11, weight: .bold)
}
