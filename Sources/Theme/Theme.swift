import SwiftUI

/// Roomiez palette + spacing tokens.
///
/// Direction: pure white surfaces, cool charcoal text, saturated modern
/// brand accents used sparingly. Premium-feeling because the space is
/// mostly white and colour is reserved for emphasis (icons, badges, bars).
///
/// Reskin the whole app by editing this file.
enum Theme {

    // MARK: - Palette

    enum Palette {
        // Neutrals — pure white surfaces, slight cool grey for subtle layers.
        static let background  = Color(hex: "FFFFFF")
        static let surface     = Color(hex: "FFFFFF")
        static let subtle      = Color(hex: "F5F5F8")   // grouped row bg
        static let ink         = Color(hex: "0B0B12")   // near-black, cool
        static let text        = ink
        static let textSoft    = Color(hex: "0B0B12").opacity(0.56)
        static let textMuted   = Color(hex: "0B0B12").opacity(0.36)
        static let divider     = Color(hex: "0B0B12").opacity(0.14)
        static let hairline    = Color(hex: "0B0B12").opacity(0.18)

        // Brand colours — Flat UI Colors palette. Bright, harmonious,
        // designed for flat design — no longer chunky-button.
        static let coral       = Color(hex: "FC6E51")   // Bittersweet (orange-red)
        static let mint        = Color(hex: "48CFAD")   // Mint teal
        static let marigold    = Color(hex: "FFCE54")   // Sunflower yellow
        static let periwinkle  = Color(hex: "4FC1E9")   // Aqua light blue
        static let rose        = Color(hex: "ED5565")   // Grapefruit red
        static let azure       = Color(hex: "5D9CEC")   // Blue Jeans
        static let grass       = Color(hex: "A0D468")   // Grass green

        // Premium chore-page palette — bright orange + sky blue.
        // Used by the chore-board accents (calendar selection, status
        // segment, filter button, FAB) and the active bottom-nav tab.
        static let orange      = Color(hex: "FF7A00")   // primary
        static let orangeMid   = Color(hex: "FF8F1F")
        static let orangeSoft  = Color(hex: "FFB15E")
        static let skyBlue     = Color(hex: "1DA1FF")   // secondary
        static let skyBlueMid  = Color(hex: "5BC2FF")
        static let skyBlueSoft = Color(hex: "B8E7FF")

        // Companions.
        static let sand        = Color(hex: "FFCE54")   // alias to sunflower
        static let sky         = Color(hex: "4FC1E9")   // alias to aqua

        // Legacy aliases — keep older call sites compiling.
        static let brick       = coral
        static let forest      = mint
        static let ochre       = marigold
        static let indigo      = periwinkle
        static let teal        = mint
        static let amber       = marigold
        static let peach       = sand
        static let slate       = sky

        /// Used to randomly tint avatars / decorative cards.
        static let pastels: [Color] = [coral, mint, marigold, periwinkle, azure, rose]
    }

    // MARK: - Gradients

    enum Gradients {
        /// Screen background — pure white with a barely-there cool fade.
        /// Premium "endless white" feel without going clinical.
        static let warmSky = LinearGradient(
            colors: [Color(hex: "FFFFFF"), Color(hex: "F7F7FA")],
            startPoint: .top, endPoint: .bottom
        )

        /// Same idea, slightly cooler — used by secondary screens.
        static let tealCloud = LinearGradient(
            colors: [Color(hex: "FFFFFF"), Color(hex: "F5F7FA")],
            startPoint: .top, endPoint: .bottom
        )

        /// XP / level bar — bold tri-stop sweep.
        static let xpBar = LinearGradient(
            colors: [Palette.coral, Palette.marigold, Palette.mint],
            startPoint: .leading, endPoint: .trailing
        )

        /// Harmony meter — warm sunrise sweep (red → orange → yellow).
        static let harmony = LinearGradient(
            colors: [Palette.rose, Palette.coral, Palette.marigold],
            startPoint: .leading, endPoint: .trailing
        )

        /// Auth hero block & marketing surfaces.
        static let logo = LinearGradient(
            colors: [Palette.azure, Palette.coral],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )

        /// Frosted-glass rim — white reflection at the top fading to a
        /// soft dark shadow at the bottom. Stroked at 1–1.5pt on white
        /// surfaces to give them a chrome-bezel feel.
        static let glassBorder = LinearGradient(
            stops: [
                .init(color: Color.white.opacity(0.95), location: 0.0),
                .init(color: Color.black.opacity(0.20), location: 0.55),
                .init(color: Color.black.opacity(0.55), location: 1.0)
            ],
            startPoint: .top, endPoint: .bottom
        )

        /// Premium chore-page sweep — bright orange → sky blue.
        /// Drives the calendar selected day, the active status segment,
        /// the filter button, the floating add button, and the active
        /// bottom-nav tab indicator.
        static let orangeSky = LinearGradient(
            colors: [Palette.orange, Palette.skyBlue],
            startPoint: .topLeading,
            endPoint:   .bottomTrailing
        )

        /// Soft pastel peach → sky sweep — the app's primary accent for
        /// the home hub, floating add button, calendar selection, etc.
        /// Hand-picked light hues so it sits well on the pearl surface.
        static let accent = LinearGradient(
            colors: [
                Color(hex: "FFC8B0"),   // soft peach
                Color(hex: "C4DAF2")    // soft sky
            ],
            startPoint: .topLeading,
            endPoint:   .bottomTrailing
        )

        /// Iridescent pearl background — soft diagonal sweep through warm
        /// peach → cool white → pale aqua → honey. Used on the dashboard
        /// so cards float on a luminous surface rather than flat white.
        static let pearl = LinearGradient(
            stops: [
                .init(color: Color(hex: "FFF1DD"), location: 0.0),   // warm peach
                .init(color: Color(hex: "F8F5FF"), location: 0.38),  // cool white
                .init(color: Color(hex: "E8F4FF"), location: 0.72),  // pale aqua
                .init(color: Color(hex: "FFF6E2"), location: 1.0)    // honey
            ],
            startPoint: .topLeading,
            endPoint:   .bottomTrailing
        )
    }

    // MARK: - Radii / spacing

    enum Radius {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 14
        static let md: CGFloat = 20
        static let lg: CGFloat = 28
        static let xl: CGFloat = 36
    }

    enum Spacing {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    // MARK: - Animation

    enum Motion {
        static let spring  = Animation.spring(response: 0.45, dampingFraction: 0.72)
        static let bouncy  = Animation.spring(response: 0.38, dampingFraction: 0.6)
        static let snappy  = Animation.spring(response: 0.28, dampingFraction: 0.85)
        static let gentle  = Animation.easeInOut(duration: 0.35)
    }
}
