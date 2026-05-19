import SwiftUI

/// Playful Ghibli-inspired procedural house glyph. One design per
/// level 1…10. Hand-painted feel: warm cream walls on stone bases,
/// shingled roofs in the tier accent, glowing-yellow windows, wispy
/// vertical smoke, and lush garden surroundings. The tier accent still
/// drives the roof colour so the level progression stays readable.
struct HouseTierImage: View {
    /// 1…10. Values outside that range are clamped.
    let level: Int
    /// Edge length of the (square) tile.
    let height: CGFloat

    private var s: CGFloat { height }
    private var tier: LevelService.HouseTier {
        LevelService.HouseTier.tier(for: level)
    }

    // MARK: - Palette (warm, earthy, Ghibli-ish)

    private var roof:        Color { tier.tint }
    private var roofShade:   Color { tier.tint.darker(by: 0.25) }
    private var roofDeep:    Color { tier.tint.darker(by: 0.42) }
    private var wallColor:   Color { Color(hex: "F4E2B6") }
    private var wallShade:   Color { Color(hex: "DCC58C") }
    private var stoneColor:  Color { Color(hex: "B8A481") }
    private var stoneShade:  Color { Color(hex: "877054") }
    private var trim:        Color { Color(hex: "6E4F2C") }
    private var doorColor:   Color { Color(hex: "8C5A33") }
    private var windowGlow:  Color { Color(hex: "FFD86A") }
    private var windowDeep:  Color { Color(hex: "E0A23A") }
    private var windowFrame: Color { Color(hex: "5C4123") }
    private var grass:       Color { Color(hex: "8AB85A") }
    private var grassDark:   Color { Color(hex: "5F8E3D") }
    private var smoke:       Color { Color.white.opacity(0.85) }

    var body: some View {
        let clamped = max(1, min(level, 10))
        ZStack(alignment: .bottom) {
            ground
            houseGroup(for: clamped)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(width: s, height: s)
        .compositingGroup()
        .shadow(color: .black.opacity(0.10),
                radius: s * 0.025, x: 0, y: s * 0.015)
    }

    @ViewBuilder
    private func houseGroup(for lvl: Int) -> some View {
        switch lvl {
        case 1:  tinyCabin
        case 2:  smallHouse
        case 3:  warmCottage
        case 4:  gardenLodge
        case 5:  tallCottage
        case 6:  twoStoryHouse
        case 7:  balconyHouse
        case 8:  grandManor
        case 9:  mythicEstate
        default: castle
        }
    }

    // MARK: - Ground

    private var ground: some View {
        ZStack {
            Ellipse()
                .fill(LinearGradient(
                    colors: [grass, grassDark],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: s * 0.96, height: s * 0.14)
            // Wildflowers + grass tufts
            HStack(spacing: s * 0.06) {
                flowerDot(.init(red: 0.95, green: 0.78, blue: 0.30))
                grassTuft
                flowerDot(.init(red: 0.92, green: 0.45, blue: 0.55))
                grassTuft
                flowerDot(.init(red: 0.97, green: 0.85, blue: 0.40))
                grassTuft
                flowerDot(.init(red: 0.86, green: 0.42, blue: 0.50))
            }
            .offset(y: -s * 0.043)
        }
        .offset(y: -s * 0.005)
    }

    private var grassTuft: some View {
        Path { p in
            p.move(to: CGPoint(x: 0, y: s * 0.025))
            p.addLine(to: CGPoint(x: s * 0.006, y: 0))
            p.addLine(to: CGPoint(x: s * 0.012, y: s * 0.025))
        }
        .stroke(grassDark, lineWidth: s * 0.005)
        .frame(width: s * 0.014, height: s * 0.025)
    }

    private func flowerDot(_ color: Color) -> some View {
        VStack(spacing: -s * 0.002) {
            Circle().fill(color)
                .frame(width: s * 0.016, height: s * 0.016)
                .overlay(Circle().fill(Color.white).frame(width: s * 0.004))
            Rectangle().fill(grassDark)
                .frame(width: s * 0.003, height: s * 0.012)
        }
    }

    // MARK: - Wall + stone base

    private func wall(_ w: CGFloat, _ h: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: s * 0.012, style: .continuous)
            .fill(LinearGradient(
                colors: [wallColor, wallShade],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            .overlay(
                RoundedRectangle(cornerRadius: s * 0.012, style: .continuous)
                    .stroke(wallShade, lineWidth: 0.8)
            )
            .frame(width: s * w, height: s * h)
    }

    /// Rough stone foundation strip — small pebbles in a band beneath
    /// the walls.
    private func stoneBase(_ w: CGFloat, _ h: CGFloat = 0.05) -> some View {
        let baseW = s * w
        let baseH = s * h
        return ZStack {
            // Mortar background
            Rectangle()
                .fill(LinearGradient(
                    colors: [stoneColor, stoneShade],
                    startPoint: .top, endPoint: .bottom
                ))
            // Stones (alternating sizes)
            HStack(spacing: s * 0.004) {
                ForEach(0..<7, id: \.self) { i in
                    Capsule()
                        .fill(stoneColor.opacity(0.95))
                        .overlay(Capsule().stroke(stoneShade.opacity(0.7), lineWidth: 0.5))
                        .frame(height: baseH * (i % 2 == 0 ? 0.85 : 0.70))
                }
            }
            .padding(.horizontal, s * 0.005)
        }
        .frame(width: baseW, height: baseH)
        .clipShape(RoundedRectangle(cornerRadius: s * 0.006, style: .continuous))
    }

    // MARK: - Roof (with shingle tile pattern)

    /// Roof shape filled with the tier accent + horizontal shingle lines
    /// + optional chimney(s) protruding from the slope.
    private func tiledRoof(_ w: CGFloat, _ h: CGFloat,
                           chimneys: Int = 0) -> some View {
        let roofW = s * w
        let roofH = s * h
        return CuteRoof()
            .fill(LinearGradient(
                colors: [roof, roofShade],
                startPoint: .top, endPoint: .bottom
            ))
            .frame(width: roofW, height: roofH)
            .overlay(shingleLines(width: roofW, height: roofH))
            .overlay(CuteRoof().stroke(roofDeep, lineWidth: 0.8))
            .background(alignment: .bottom) {
                if chimneys >= 1 {
                    chimneyStack
                        .offset(x:  roofW * 0.22, y: -roofH * 0.34)
                }
                if chimneys >= 2 {
                    chimneyStack
                        .offset(x: -roofW * 0.22, y: -roofH * 0.34)
                }
            }
    }

    /// Three subtle horizontal shingle bands, masked to the roof shape.
    private func shingleLines(width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: height * 0.18) {
            ForEach(0..<3, id: \.self) { _ in
                Rectangle()
                    .fill(roofDeep.opacity(0.30))
                    .frame(height: max(0.7, height * 0.015))
            }
        }
        .padding(.top, height * 0.30)
        .padding(.horizontal, width * 0.04)
        .mask(CuteRoof().frame(width: width, height: height))
    }

    /// Vertical chimney with wispy smoke trail. Rendered behind the
    /// roof so the lower portion sits inside the slope.
    private var chimneyStack: some View {
        VStack(spacing: -s * 0.004) {
            curlingSmoke
            RoundedRectangle(cornerRadius: s * 0.005, style: .continuous)
                .fill(LinearGradient(
                    colors: [stoneColor, stoneShade],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: s * 0.046, height: s * 0.13)
                .overlay(
                    // Brick band at top
                    Rectangle()
                        .fill(roofDeep.opacity(0.6))
                        .frame(height: s * 0.012)
                        .frame(maxHeight: .infinity, alignment: .top)
                )
        }
    }

    /// Soft vertical column of smoke puffs that drift upward.
    private var curlingSmoke: some View {
        ZStack {
            Circle().fill(smoke.opacity(0.55))
                .frame(width: s * 0.026, height: s * 0.026)
                .offset(x:  s * 0.005, y: s * 0.008)
            Circle().fill(smoke.opacity(0.75))
                .frame(width: s * 0.034, height: s * 0.034)
                .offset(x: -s * 0.004, y: -s * 0.005)
            Circle().fill(smoke.opacity(0.55))
                .frame(width: s * 0.024, height: s * 0.024)
                .offset(x:  s * 0.010, y: -s * 0.020)
            Circle().fill(smoke.opacity(0.35))
                .frame(width: s * 0.020, height: s * 0.020)
                .offset(x: -s * 0.002, y: -s * 0.033)
        }
        .frame(width: s * 0.08, height: s * 0.08)
    }

    // MARK: - Door / window

    private func archedDoor(_ w: CGFloat = 0.10,
                            _ h: CGFloat = 0.18,
                            withHeart: Bool = false) -> some View {
        ZStack {
            ArchedDoorShape()
                .fill(LinearGradient(
                    colors: [doorColor, doorColor.darker(by: 0.22)],
                    startPoint: .top, endPoint: .bottom
                ))
                .overlay(ArchedDoorShape().stroke(trim, lineWidth: 0.8))
            // Vertical plank lines on the door
            HStack(spacing: s * w * 0.30) {
                Rectangle().fill(trim.opacity(0.45))
                    .frame(width: 0.5, height: s * h * 0.55)
                Rectangle().fill(trim.opacity(0.45))
                    .frame(width: 0.5, height: s * h * 0.55)
            }
            .offset(y: s * h * 0.10)
            // Doorknob
            Circle()
                .fill(Theme.Palette.marigold)
                .frame(width: s * 0.012, height: s * 0.012)
                .offset(x: s * w * 0.22, y: s * h * 0.05)
            if withHeart {
                Image(systemName: "heart.fill")
                    .font(.system(size: s * 0.020, weight: .black))
                    .foregroundStyle(Theme.Palette.rose)
                    .offset(y: -s * h * 0.18)
            }
        }
        .frame(width: s * w, height: s * h)
    }

    private func window(_ side: CGFloat = 0.08, lit: Bool = true) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: s * 0.008, style: .continuous)
                .fill(lit
                      ? LinearGradient(colors: [windowGlow, windowDeep],
                                       startPoint: .top, endPoint: .bottom)
                      : LinearGradient(colors: [Color(hex: "BFD8EE"), Color(hex: "8FB7D6")],
                                       startPoint: .top, endPoint: .bottom))
            RoundedRectangle(cornerRadius: s * 0.008, style: .continuous)
                .stroke(windowFrame, lineWidth: 0.8)
            Path { p in
                let edge = s * side
                p.move(to: CGPoint(x: edge / 2, y: 0))
                p.addLine(to: CGPoint(x: edge / 2, y: edge))
                p.move(to: CGPoint(x: 0, y: edge / 2))
                p.addLine(to: CGPoint(x: edge, y: edge / 2))
            }
            .stroke(windowFrame.opacity(0.8), lineWidth: 0.6)
            // Window sill / lintel
            Rectangle().fill(trim.opacity(0.6))
                .frame(width: s * side * 1.15, height: s * 0.006)
                .offset(y: s * side * 0.5 + s * 0.002)
        }
        .frame(width: s * side, height: s * side)
    }

    private func roundWindow(_ side: CGFloat = 0.07) -> some View {
        ZStack {
            Circle().fill(LinearGradient(
                colors: [windowGlow, windowDeep],
                startPoint: .top, endPoint: .bottom
            ))
            Circle().stroke(windowFrame, lineWidth: 0.8)
            Path { p in
                let edge = s * side
                p.move(to: CGPoint(x: edge / 2, y: 0))
                p.addLine(to: CGPoint(x: edge / 2, y: edge))
                p.move(to: CGPoint(x: 0, y: edge / 2))
                p.addLine(to: CGPoint(x: edge, y: edge / 2))
            }
            .stroke(windowFrame.opacity(0.7), lineWidth: 0.6)
        }
        .frame(width: s * side, height: s * side)
    }

    // MARK: - Garden details

    private func bush(_ size: CGFloat = 0.13) -> some View {
        ZStack {
            Circle().fill(grassDark)
                .frame(width: s * size * 0.72, height: s * size * 0.72)
                .offset(x: -s * size * 0.22, y: s * size * 0.10)
            Circle().fill(grass)
                .frame(width: s * size * 0.82, height: s * size * 0.82)
                .offset(y: -s * size * 0.05)
            Circle().fill(grass.darker(by: 0.06))
                .frame(width: s * size * 0.66, height: s * size * 0.66)
                .offset(x: s * size * 0.25)
        }
        .frame(width: s * size, height: s * size)
    }

    /// Window flower box — three small dots above a planter rim.
    private func flowerBox(_ width: CGFloat = 0.10) -> some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: s * 0.005, style: .continuous)
                .fill(LinearGradient(
                    colors: [doorColor.darker(by: 0.08),
                             doorColor.darker(by: 0.28)],
                    startPoint: .top, endPoint: .bottom
                ))
            HStack(spacing: s * 0.008) {
                Circle().fill(Color(hex: "EE6F8A"))
                Circle().fill(Color(hex: "F3C95F"))
                Circle().fill(Color(hex: "DC4D55"))
            }
            .frame(width: s * width * 0.7, height: s * 0.018)
            .offset(y: -s * 0.010)
        }
        .frame(width: s * width, height: s * 0.04)
    }

    /// Tiny sparkle decoration for the legendary tiers.
    private func sparkle(_ side: CGFloat = 0.04,
                         color: Color = Theme.Palette.marigold) -> some View {
        Image(systemName: "sparkle")
            .font(.system(size: s * side, weight: .black))
            .foregroundStyle(color)
    }

    // MARK: - 1 · Tiny Cabin

    private var tinyCabin: some View {
        VStack(spacing: -s * 0.005) {
            tiledRoof(0.52, 0.22)
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    wall(0.42, 0.20)
                    stoneBase(0.42, 0.05)
                }
                archedDoor(0.10, 0.16, withHeart: true)
                    .offset(y: -s * 0.05)
            }
        }
        .padding(.bottom, s * 0.07)
    }

    // MARK: - 2 · Small House

    private var smallHouse: some View {
        VStack(spacing: -s * 0.005) {
            tiledRoof(0.60, 0.22, chimneys: 1)
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    wall(0.50, 0.22)
                    stoneBase(0.50, 0.05)
                }
                HStack(spacing: s * 0.04) {
                    archedDoor(0.10, 0.16, withHeart: true)
                    VStack(spacing: -s * 0.005) {
                        window(0.07).offset(y: -s * 0.04)
                        flowerBox(0.08)
                    }
                    .offset(y: -s * 0.005)
                }
                .offset(y: -s * 0.05)
            }
        }
        .padding(.bottom, s * 0.06)
    }

    // MARK: - 3 · Warm Cottage

    private var warmCottage: some View {
        VStack(spacing: -s * 0.005) {
            tiledRoof(0.68, 0.24, chimneys: 1)
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    wall(0.58, 0.26)
                    stoneBase(0.58, 0.05)
                }
                HStack(spacing: s * 0.03) {
                    VStack(spacing: -s * 0.005) {
                        window(0.075)
                        flowerBox(0.085)
                    }
                    archedDoor(0.10, 0.18)
                    VStack(spacing: -s * 0.005) {
                        window(0.075)
                        flowerBox(0.085)
                    }
                }
                .offset(y: -s * 0.06)
            }
        }
        .padding(.bottom, s * 0.05)
    }

    // MARK: - 4 · Garden Lodge

    private var gardenLodge: some View {
        ZStack(alignment: .bottom) {
            HStack {
                bush(0.14)
                Spacer(minLength: s * 0.46)
                bush(0.16)
            }
            .frame(width: s * 0.88)
            .offset(y: s * 0.02)

            warmCottage.scaleEffect(0.94)
        }
    }

    // MARK: - 5 · Tall Cottage (1.5-story w/ attic dormer)

    private var tallCottage: some View {
        ZStack(alignment: .top) {
            VStack(spacing: -s * 0.005) {
                tiledRoof(0.72, 0.24, chimneys: 1)
                ZStack(alignment: .bottom) {
                    VStack(spacing: 0) {
                        wall(0.60, 0.32)
                        stoneBase(0.60, 0.05)
                    }
                    VStack(spacing: s * 0.025) {
                        HStack(spacing: s * 0.05) {
                            window(0.07)
                            window(0.07)
                        }
                        HStack(spacing: s * 0.03) {
                            window(0.07)
                            archedDoor(0.10, 0.18)
                            window(0.07)
                        }
                    }
                    .offset(y: -s * 0.07)
                }
            }
            // Attic dormer in roof
            ZStack {
                RoundedRectangle(cornerRadius: s * 0.010)
                    .fill(wallColor)
                    .overlay(RoundedRectangle(cornerRadius: s * 0.010)
                        .stroke(wallShade, lineWidth: 0.8))
                roundWindow(0.05)
            }
            .frame(width: s * 0.10, height: s * 0.10)
            .offset(y: s * 0.10)
        }
        .padding(.bottom, s * 0.04)
    }

    // MARK: - 6 · Two-Story House

    private var twoStoryHouse: some View {
        VStack(spacing: -s * 0.005) {
            tiledRoof(0.70, 0.20, chimneys: 1)
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    ZStack(alignment: .bottom) {
                        wall(0.60, 0.22)
                        HStack(spacing: s * 0.07) {
                            window(0.075)
                            window(0.075)
                        }
                        .offset(y: -s * 0.04)
                    }
                    ZStack(alignment: .bottom) {
                        wall(0.60, 0.22)
                        HStack(spacing: s * 0.03) {
                            window(0.075)
                            archedDoor(0.10, 0.18)
                            window(0.075)
                        }
                        .offset(y: -s * 0.05)
                    }
                    stoneBase(0.60, 0.05)
                }
            }
        }
        .padding(.bottom, s * 0.04)
    }

    // MARK: - 7 · Balcony House

    private var balconyHouse: some View {
        VStack(spacing: -s * 0.005) {
            tiledRoof(0.76, 0.20, chimneys: 1)
            VStack(spacing: 0) {
                // Upper level w/ 3 windows
                ZStack(alignment: .bottom) {
                    wall(0.64, 0.22)
                    HStack(spacing: s * 0.05) {
                        window(0.075); window(0.075); window(0.075)
                    }
                    .offset(y: -s * 0.04)
                }
                // Balcony rail
                ZStack {
                    Rectangle()
                        .fill(doorColor.darker(by: 0.15))
                        .frame(width: s * 0.50, height: s * 0.012)
                    HStack(spacing: s * 0.020) {
                        ForEach(0..<7, id: \.self) { _ in
                            Rectangle().fill(doorColor.darker(by: 0.30))
                                .frame(width: s * 0.005, height: s * 0.012)
                        }
                    }
                }
                // Lower level
                ZStack(alignment: .bottom) {
                    wall(0.64, 0.22)
                    HStack(spacing: s * 0.03) {
                        VStack(spacing: -s * 0.005) {
                            window(0.075); flowerBox(0.085)
                        }
                        archedDoor(0.10, 0.18)
                        VStack(spacing: -s * 0.005) {
                            window(0.075); flowerBox(0.085)
                        }
                    }
                    .offset(y: -s * 0.045)
                }
                stoneBase(0.64, 0.05)
            }
        }
        .padding(.bottom, s * 0.04)
    }

    // MARK: - 8 · Grand Manor (3-story)

    private var grandManor: some View {
        VStack(spacing: -s * 0.005) {
            tiledRoof(0.80, 0.18, chimneys: 2)
            VStack(spacing: 0) {
                ZStack {
                    wall(0.68, 0.15)
                    HStack(spacing: s * 0.05) {
                        window(0.065); window(0.065); window(0.065)
                    }
                }
                ZStack {
                    wall(0.68, 0.17)
                    HStack(spacing: s * 0.05) {
                        window(0.07); window(0.07); window(0.07)
                    }
                }
                ZStack(alignment: .bottom) {
                    wall(0.68, 0.19)
                    HStack(spacing: s * 0.03) {
                        VStack(spacing: -s * 0.005) {
                            window(0.07); flowerBox(0.08)
                        }
                        archedDoor(0.11, 0.18)
                        VStack(spacing: -s * 0.005) {
                            window(0.07); flowerBox(0.08)
                        }
                    }
                    .offset(y: -s * 0.04)
                }
                stoneBase(0.68, 0.05)
            }
        }
        .padding(.bottom, s * 0.03)
    }

    // MARK: - 9 · Mythic Estate (triple-peak roof)

    private var mythicEstate: some View {
        ZStack(alignment: .top) {
            VStack(spacing: -s * 0.005) {
                HStack(spacing: -s * 0.01) {
                    tiledRoof(0.30, 0.22)
                    tiledRoof(0.36, 0.30, chimneys: 1).offset(y: -s * 0.04)
                    tiledRoof(0.30, 0.22)
                }
                VStack(spacing: 0) {
                    ZStack {
                        wall(0.80, 0.18)
                        HStack(spacing: s * 0.04) {
                            roundWindow(0.07)
                            window(0.075)
                            roundWindow(0.07)
                            window(0.075)
                        }
                    }
                    ZStack(alignment: .bottom) {
                        wall(0.80, 0.22)
                        HStack(spacing: s * 0.025) {
                            window(0.075)
                            window(0.075)
                            archedDoor(0.11, 0.18)
                            window(0.075)
                            window(0.075)
                        }
                        .offset(y: -s * 0.04)
                    }
                    stoneBase(0.80, 0.05)
                }
            }
            HStack(spacing: s * 0.55) {
                sparkle(0.040, color: Theme.Palette.marigold)
                sparkle(0.040, color: Theme.Palette.coral)
            }
            .offset(y: -s * 0.05)
        }
        .padding(.bottom, s * 0.03)
    }

    // MARK: - 10 · Castle

    private var castle: some View {
        ZStack(alignment: .top) {
            VStack(spacing: -s * 0.005) {
                HStack(alignment: .bottom, spacing: s * 0.012) {
                    spire(0.16, 0.22, fill: roofShade)
                    spire(0.22, 0.32, fill: roof)
                    spire(0.16, 0.22, fill: roofShade)
                }
                VStack(spacing: 0) {
                    ZStack {
                        wall(0.72, 0.18)
                        HStack(spacing: s * 0.04) {
                            roundWindow(0.06); roundWindow(0.06); roundWindow(0.06)
                        }
                    }
                    ZStack {
                        wall(0.72, 0.18)
                        HStack(spacing: s * 0.04) {
                            window(0.075); window(0.075); window(0.075)
                        }
                    }
                    ZStack(alignment: .bottom) {
                        wall(0.72, 0.18)
                        UnevenRoundedRectangle(
                            cornerRadii: .init(topLeading: s * 0.06,
                                               topTrailing: s * 0.06),
                            style: .continuous
                        )
                        .fill(LinearGradient(
                            colors: [doorColor, doorColor.darker(by: 0.22)],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .frame(width: s * 0.12, height: s * 0.16)
                        .offset(y: -s * 0.01)
                    }
                    stoneBase(0.72, 0.06)
                }
            }
            // Flags atop spires
            HStack(spacing: s * 0.13) {
                flag()
                flag().offset(y: -s * 0.05)
                flag()
            }
            .offset(y: -s * 0.02)
            // Sparkles
            HStack(spacing: s * 0.52) {
                sparkle(0.04, color: Theme.Palette.marigold)
                sparkle(0.04, color: Theme.Palette.coral)
            }
            .offset(y: s * 0.06)
        }
        .padding(.bottom, s * 0.02)
    }

    private func spire(_ w: CGFloat, _ h: CGFloat,
                       fill: Color) -> some View {
        Triangle()
            .fill(LinearGradient(
                colors: [fill, fill.darker(by: 0.20)],
                startPoint: .top, endPoint: .bottom
            ))
            .frame(width: s * w, height: s * h)
    }

    private func flag() -> some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(trim)
                .frame(width: s * 0.005, height: s * 0.06)
            Path { p in
                p.move(to: .zero)
                p.addLine(to: CGPoint(x: s * 0.035, y: s * 0.012))
                p.addLine(to: CGPoint(x: 0, y: s * 0.024))
                p.closeSubpath()
            }
            .fill(Theme.Palette.rose)
            .offset(x: s * 0.005, y: s * 0.002)
        }
        .frame(width: s * 0.04, height: s * 0.06)
    }
}

// MARK: - Shapes

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// Pointed roof with a rounded peak + slight eave overhang at the base.
private struct CuteRoof: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let eave = rect.width * 0.045
        let peakRadius = rect.height * 0.16
        let peakX = rect.midX
        let peakY = rect.minY + peakRadius * 0.35
        let leftBase  = CGPoint(x: rect.minX - eave, y: rect.maxY)
        let rightBase = CGPoint(x: rect.maxX + eave, y: rect.maxY)

        p.move(to: leftBase)
        p.addLine(to: CGPoint(x: peakX - peakRadius, y: peakY + peakRadius))
        p.addQuadCurve(
            to: CGPoint(x: peakX + peakRadius, y: peakY + peakRadius),
            control: CGPoint(x: peakX, y: rect.minY)
        )
        p.addLine(to: rightBase)
        p.closeSubpath()
        return p
    }
}

/// Door with a rounded arch top.
private struct ArchedDoorShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let archHeight = rect.width * 0.5
        let archTopY = rect.minY + archHeight
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: archTopY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: archTopY),
            control: CGPoint(x: rect.midX, y: rect.minY)
        )
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

