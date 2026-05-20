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

        // Brand colours. `coral` (Tomato) is the PRIMARY brand colour —
        // hero gradients, XP bar, primary CTAs, the centre house hub.
        // `azure` (Blue Bell) is the SECONDARY — rotation chip, recurrence,
        // info banners, secondary buttons. The other five are RETUNED into
        // the orange/blue family so the whole app reads as the new brand
        // while still keeping enough hue variety for chore icons,
        // difficulty chips, status chips, and house tiers to read
        // distinctly from each other.
        static let coral       = Color(hex: "FF6A3D")   // Tomato — primary
        static let azure       = Color(hex: "2D9CDB")   // Blue Bell — secondary
        // Warm family — pull toward Tomato's hue so they read as variants
        // of the primary instead of a separate Flat-UI rainbow.
        static let marigold    = Color(hex: "F5A623")   // Warm amber (was sunflower)
        static let rose        = Color(hex: "E55542")   // Warm coral-red (was grapefruit)
        // Cool family — pull toward Blue Bell so the secondary feels
        // anchored instead of competing with a separate aqua/teal.
        static let periwinkle  = Color(hex: "6BC0E8")   // Soft sky tint of azure
        static let mint        = Color(hex: "3FB8A8")   // Blue-leaning teal (was pure mint)
        static let grass       = Color(hex: "7FBF8B")   // Sage green (was bright grass)

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

        /// XP / level bar — Tomato → amber → Blue Bell. Anchored in the
        /// two brand colours so XP progress visibly reads "Roomiez" no
        /// matter where it appears.
        static let xpBar = LinearGradient(
            colors: [Palette.coral, Palette.marigold, Palette.azure],
            startPoint: .leading, endPoint: .trailing
        )

        /// Harmony meter — warm sunrise sweep, now anchored on the new
        /// primary so the bar reads as full-brand instead of a separate
        /// red-orange-yellow rainbow.
        static let harmony = LinearGradient(
            colors: [Palette.rose, Palette.coral, Palette.marigold],
            startPoint: .leading, endPoint: .trailing
        )

        /// Auth hero block & marketing surfaces. Literally the swatch the
        /// brand is built on: Blue Bell → Tomato.
        static let logo = LinearGradient(
            colors: [Palette.azure, Palette.coral],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )

        /// The app's primary accent gradient — used on the home hub, the
        /// floating add button, the calendar selection pill, and the
        /// Single | Group mode toggle. Pulled more saturated than the
        /// previous pastel so the new brand actually lands at a glance,
        /// while still sitting comfortably on the pearl background.
        static let accent = LinearGradient(
            colors: [
                Color(hex: "FF8A63"),   // softer Tomato (still in primary family)
                Color(hex: "5BB6E3")    // softer Blue Bell (still in secondary family)
            ],
            startPoint: .topLeading,
            endPoint:   .bottomTrailing
        )

        /// Pearl background — now a true sunrise: a kiss of Tomato in the
        /// top-left, a kiss of Blue Bell in the bottom-right, nearly-white
        /// in between. The brand identity shows up on every page without
        /// the surface ever feeling crowded.
        static let pearl = LinearGradient(
            stops: [
                .init(color: Color(hex: "FFE9DE"), location: 0.0),   // pale Tomato wash
                .init(color: Color(hex: "FFF6F0"), location: 0.35),  // warm near-white
                .init(color: Color(hex: "F0F7FC"), location: 0.70),  // cool near-white
                .init(color: Color(hex: "DEEEF8"), location: 1.0)    // pale Blue Bell wash
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
