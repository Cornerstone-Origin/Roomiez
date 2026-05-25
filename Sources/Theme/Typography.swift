import SwiftUI

extension Font {
    /// Rounded SF — the app's friendly planner-app feel. Always
    /// prefer one of the named tokens below; reach for `cozy(_:weight:)`
    /// only for one-off design moments that don't fit the scale.
    static func cozy(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    // MARK: - Display

    /// 34/bold — primary page titles ("Chore Board", "Your household").
    static let cozyDisplay      = Font.cozy(34, weight: .bold)
    /// 22/bold — secondary screen titles (sheet headers).
    static let cozyTitle        = Font.cozy(22, weight: .bold)
    /// 20/semibold — card titles, hero text.
    static let cozyHeadline     = Font.cozy(20, weight: .semibold)

    // MARK: - Body

    /// 16/medium — primary body text (input fields, notes).
    static let cozyBody         = Font.cozy(16, weight: .medium)

    // MARK: - Action / chip

    /// 15/semibold — primary inline action text ("Add", "Save").
    static let cozyAction       = Font.cozy(15, weight: .semibold)
    /// 15/bold — bolder action emphasis (toolbar confirmations).
    static let cozyActionStrong = Font.cozy(15, weight: .bold)
    /// 14/semibold — secondary action / chip text.
    static let cozyChip         = Font.cozy(14, weight: .semibold)
    /// 14/bold — bolder chip / button text.
    static let cozyChipStrong   = Font.cozy(14, weight: .bold)

    // MARK: - Captions

    /// 13/medium — subtitles, friendly small text.
    static let cozyCaption      = Font.cozy(13, weight: .medium)
    /// 13/semibold — emphasised captions, labels above fields.
    static let cozyCaptionEmph  = Font.cozy(13, weight: .semibold)
    /// 13/bold — bolder caption emphasis.
    static let cozyCaptionStrong = Font.cozy(13, weight: .bold)

    // MARK: - Small / pill labels

    /// 12/bold — badges, count chips, status pills.
    static let cozyBadge        = Font.cozy(12, weight: .bold)
    /// 12/semibold — secondary small labels.
    static let cozyBadgeSoft    = Font.cozy(12, weight: .semibold)
    /// 11/bold — all-caps tags ("LATE", "PRODUCE"). Pair with
    /// `.cozyAllCaps()` for letter-spacing.
    static let cozyTag          = Font.cozy(11, weight: .bold)
}

extension Text {
    /// Standard treatment for all-caps tag / label text — uppercased
    /// plus a touch of positive letter-spacing so the letters breathe.
    /// Use with `.cozyTag` or `.cozyCaption`/`.cozyCaptionEmph`.
    func cozyAllCaps(tracking: CGFloat = 1.6) -> some View {
        self.tracking(tracking)
            .textCase(.uppercase)
    }
}
