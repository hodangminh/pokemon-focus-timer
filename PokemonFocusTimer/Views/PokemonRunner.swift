import SwiftUI

private enum PokemonKind: CaseIterable {
    case pikachu, eevee, leafeon, glaceon, sylveon

    var assetName: String {
        switch self {
        case .pikachu:  return "pikachu"
        case .eevee:    return "eevee"
        case .leafeon:  return "leafeon"
        case .glaceon:  return "glaceon"
        case .sylveon:  return "sylveon"
        }
    }

    /// Base speed multiplier — each critter feels a bit different.
    var speedFactor: CGFloat {
        switch self {
        case .pikachu:  return 1.35   // fast/zippy
        case .eevee:    return 1.10
        case .leafeon:  return 1.00
        case .glaceon:  return 0.90
        case .sylveon:  return 1.05
        }
    }

    /// Hop cadence in seconds per hop.
    var hopPeriod: Double {
        switch self {
        case .pikachu:  return 0.28
        case .eevee:    return 0.34
        case .leafeon:  return 0.36
        case .glaceon:  return 0.40
        case .sylveon:  return 0.34
        }
    }
}

private final class Critter: Identifiable {
    let id = UUID()
    let kind: PokemonKind
    var x: CGFloat
    var vx: CGFloat = 0
    var facingRight: Bool = true
    var wanderTarget: CGFloat
    var lastUpdate: TimeInterval
    var hopPhaseOffset: Double

    init(kind: PokemonKind, x: CGFloat, wanderTarget: CGFloat, now: TimeInterval, hopPhaseOffset: Double) {
        self.kind = kind
        self.x = x
        self.wanderTarget = wanderTarget
        self.lastUpdate = now
        self.hopPhaseOffset = hopPhaseOffset
    }
}

struct PokemonRunner: View {
    var height: CGFloat = 76
    var cursorX: CGFloat? = nil

    @State private var critters: [Critter] = []
    @State private var lastWander: TimeInterval = 0

    private let baseMaxSpeed: CGFloat = 95     // pts / second
    private let dashBoost: CGFloat = 1.6        // multiplier when chasing cursor
    private let acceleration: CGFloat = 340     // pts / second^2
    private let spriteSize: CGFloat = 58
    private let footprint: CGFloat = 48         // horizontal separation

    private let kinds: [PokemonKind] = [.pikachu, .leafeon, .sylveon]

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { context in
                let now = context.date.timeIntervalSinceReferenceDate
                let width = geo.size.width

                ZStack(alignment: .bottomLeading) {
                    Color.clear
                    ForEach(critters) { c in
                        let hop = hopMetrics(for: c, at: now)
                        CritterView(
                            kind: c.kind,
                            facingRight: c.facingRight,
                            hopLift: hop.lift,
                            squash: hop.squash,
                            spriteSize: spriteSize
                        )
                        .position(x: c.x, y: height - spriteSize / 2 - 2 - hop.lift)
                    }
                }
                .frame(width: width, height: height)
                .onAppear {
                    if critters.isEmpty {
                        seed(width: width, now: context.date.timeIntervalSinceReferenceDate)
                    }
                }
                .onChange(of: context.date) { newDate in
                    step(now: newDate.timeIntervalSinceReferenceDate, width: width)
                }
            }
        }
        .frame(height: height)
        .allowsHitTesting(false)
    }

    private func seed(width: CGFloat, now: TimeInterval) {
        critters = kinds.enumerated().map { (i, kind) in
            let slot = CGFloat(i + 1) / CGFloat(kinds.count + 1)
            return Critter(
                kind: kind,
                x: width * slot,
                wanderTarget: width * CGFloat.random(in: 0.15...0.85),
                now: now,
                hopPhaseOffset: Double(i) * 0.11
            )
        }
        lastWander = now
    }

    private func hopMetrics(for c: Critter, at now: TimeInterval) -> (lift: CGFloat, squash: CGFloat) {
        let moving = abs(c.vx) > 3
        guard moving else {
            // Idle bob
            let s = sin(now * 2 + c.hopPhaseOffset * 6)
            return (lift: CGFloat(s) * 0.8, squash: 1.0)
        }
        let period = c.kind.hopPeriod
        let phase = (now + c.hopPhaseOffset).truncatingRemainder(dividingBy: period) / period
        // Parabolic hop: peak at phase 0.5.
        let arch = 1.0 - pow(2.0 * phase - 1.0, 2.0)
        let maxLift: CGFloat = 6.5
        let lift = CGFloat(arch) * maxLift
        // Squash on landing (bottom of arc), stretch mid-air.
        let ground = 1.0 - arch // 1 on ground, 0 at peak
        let squash = 1.0 + CGFloat(arch) * 0.05 - CGFloat(ground) * 0.10
        return (lift: lift, squash: squash)
    }

    private func step(now: TimeInterval, width: CGFloat) {
        guard width > 0, !critters.isEmpty else { return }

        if now - lastWander > 3.0 {
            lastWander = now
            for c in critters {
                c.wanderTarget = CGFloat.random(in: (footprint / 2)...(width - footprint / 2))
            }
        }

        let chasing = cursorX != nil

        for c in critters {
            let dt = max(0.001, min(0.05, now - c.lastUpdate))
            c.lastUpdate = now

            let target: CGFloat = cursorX ?? c.wanderTarget
            let dx = target - c.x
            let speedCap = baseMaxSpeed * c.kind.speedFactor * (chasing ? dashBoost : 1.0)
            let desired: CGFloat
            if abs(dx) < 2 {
                desired = 0
            } else {
                desired = (dx > 0 ? 1 : -1) * speedCap
            }
            let dv = desired - c.vx
            let maxDv = acceleration * CGFloat(dt)
            c.vx += max(-maxDv, min(maxDv, dv))
            c.x += c.vx * CGFloat(dt)

            if c.vx > 1 { c.facingRight = true }
            else if c.vx < -1 { c.facingRight = false }
        }

        // Separation: keep at least `footprint` between centers.
        let minX = footprint / 2
        let maxX = width - footprint / 2
        let sorted = critters.sorted { $0.x < $1.x }
        for i in 1..<sorted.count {
            let prev = sorted[i - 1]
            let curr = sorted[i]
            let gap = curr.x - prev.x
            if gap < footprint {
                let push = (footprint - gap) / 2
                prev.x -= push
                curr.x += push
                if prev.vx > 0 { prev.vx = 0 }
                if curr.vx < 0 { curr.vx = 0 }
            }
        }
        for c in critters {
            if c.x < minX { c.x = minX; if c.vx < 0 { c.vx = 0 } }
            if c.x > maxX { c.x = maxX; if c.vx > 0 { c.vx = 0 } }
        }
    }
}

private struct CritterView: View {
    let kind: PokemonKind
    let facingRight: Bool
    let hopLift: CGFloat
    let squash: CGFloat
    let spriteSize: CGFloat

    var body: some View {
        ZStack {
            // Shadow — shrinks as the critter rises.
            let shadowScale = max(0.35, 1.0 - hopLift / 12.0)
            Ellipse()
                .fill(Color.black.opacity(0.28 * Double(shadowScale)))
                .frame(width: spriteSize * 0.55 * shadowScale, height: 4 * shadowScale)
                .offset(y: spriteSize / 2 + hopLift - 1)

            Image(kind.assetName)
                .interpolation(.none)               // preserve pixel-art crispness
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: spriteSize, height: spriteSize)
                .scaleEffect(x: facingRight ? -1 : 1, y: 1)
                .scaleEffect(x: 1.0, y: squash, anchor: .bottom)
        }
        .frame(width: spriteSize, height: spriteSize)
    }
}

struct RollingPokeball: View {
    var size: CGFloat = 22
    var speed: CGFloat = 130   // pts / second

    @State private var x: CGFloat = 0
    @State private var dir: CGFloat = 1
    @State private var lastTick: TimeInterval = 0

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { context in
                let width = geo.size.width
                let now = context.date.timeIntervalSinceReferenceDate
                let rotation = rotationFor(x: x, dir: dir)
                ZStack {
                    Color.clear
                    PokeballView(size: size, rotation: rotation)
                        .position(x: max(size / 2, min(width - size / 2, x)), y: size / 2 + 2)
                }
                .frame(width: width, height: size + 6)
                .onAppear {
                    if lastTick == 0 {
                        x = size / 2
                        lastTick = now
                    }
                }
                .onChange(of: context.date) { newDate in
                    let t = newDate.timeIntervalSinceReferenceDate
                    let dt = max(0.001, min(0.05, t - lastTick))
                    lastTick = t
                    x += speed * dir * CGFloat(dt)
                    let minX = size / 2
                    let maxX = width - size / 2
                    if x >= maxX { x = maxX; dir = -1 }
                    if x <= minX { x = minX; dir = 1 }
                }
            }
        }
        .frame(height: size + 6)
        .allowsHitTesting(false)
    }

    private func rotationFor(x: CGFloat, dir: CGFloat) -> Double {
        let circumference = Double.pi * Double(size)
        return Double(x) / circumference * 360.0 * Double(dir)
    }
}

private struct PokeballView: View {
    let size: CGFloat
    let rotation: Double

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(0.28))
                .frame(width: size * 0.7, height: 3)
                .offset(y: size / 2 + 1)

            ZStack {
                Circle()
                    .fill(Color.white)
                Circle()
                    .trim(from: 0.0, to: 0.5)
                    .fill(Color(red: 0.90, green: 0.15, blue: 0.15))
                    .rotationEffect(.degrees(180))
                Rectangle()
                    .fill(Color.black)
                    .frame(height: max(1.5, size * 0.10))
                Circle()
                    .stroke(Color.black, lineWidth: max(1.0, size * 0.06))
                Circle()
                    .fill(Color.black)
                    .frame(width: size * 0.30, height: size * 0.30)
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.18, height: size * 0.18)
                Circle()
                    .stroke(Color.black, lineWidth: max(1.0, size * 0.05))
                    .frame(width: size * 0.18, height: size * 0.18)
            }
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
        }
        .frame(width: size, height: size)
    }
}
