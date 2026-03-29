import Combine
import SwiftUI

@MainActor
final class StarCollectorViewModel: ObservableObject {
    enum PlayPhase {
        case ready
        case playing
        case won
        case lost
    }

    struct MovingStar: Identifiable {
        let id: UUID
        var progress: CGFloat
        let lane: Int
        var speedMultiplier: CGFloat
        var crossedThisLap: Bool
        /// Random wave offset so Y at the gate changes each lap — avoids parking in one spot.
        var wavePhase: CGFloat
    }

    @Published var phase: PlayPhase = .ready
    @Published var alignment: CGFloat = 0.5
    @Published var elapsed: Double = 0
    @Published var caught: Int = 0
    @Published var lives: Int = 3
    @Published var stars: [MovingStar] = []

    let level: Int
    let difficulty: Difficulty

    let target: Int
    let timeLimit: Double
    private let baseSpeed: CGFloat

    private var tickSubscription: AnyCancellable?
    private var misses: Int = 0
    private var attempts: Int = 0

    init(level: Int, difficulty: Difficulty) {
        self.level = level
        self.difficulty = difficulty

        let difficultyBonus = switch difficulty {
        case .easy: 0
        case .normal: 6
        case .hard: 12
        }
        let base = 14 + min(level, 10) * 4 + difficultyBonus
        self.target = min(80, max(20, base))

        let easeTime: Double = switch difficulty {
        case .easy: 72
        case .normal: 58
        case .hard: 46
        }
        self.timeLimit = max(28, easeTime - Double(level) * 1.1)

        self.baseSpeed = switch difficulty {
        case .easy: 0.12
        case .normal: 0.16
        case .hard: 0.20
        }
    }

    var laneCount: Int {
        min(5, 1 + level / 3)
    }

    var starCount: Int {
        let base = min(5, 1 + level / 4)
        switch difficulty {
        case .easy: return max(1, base)
        case .normal: return max(2, base)
        case .hard: return max(3, base + 1)
        }
    }

    func start() {
        stop()
        phase = .playing
        elapsed = 0
        caught = 0
        lives = 3
        alignment = 0.35
        misses = 0
        attempts = 0
        respawnStars()

        tickSubscription = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.advance(dt: 1.0 / 60.0)
            }
    }

    func stop() {
        tickSubscription?.cancel()
        tickSubscription = nil
    }

    private func newWavePhase() -> CGFloat {
        CGFloat.random(in: 0..<(2 * .pi))
    }

    private func respawnStars() {
        let lanes = laneCount
        let count = starCount
        let span: CGFloat = 0.58
        stars = (0..<count).map { i in
            let t = count > 1 ? CGFloat(i) / CGFloat(count - 1) : 0.35
            let progress = min(span - 0.04, max(0.05, t * span))
            return MovingStar(
                id: UUID(),
                progress: progress,
                lane: i % max(1, lanes),
                speedMultiplier: difficulty == .hard ? CGFloat(Double.random(in: 0.88...1.12)) : 1.0,
                crossedThisLap: false,
                wavePhase: newWavePhase()
            )
        }
    }

    private func hitWindow() -> CGFloat {
        switch difficulty {
        case .easy: return 0.095
        case .normal: return 0.075
        case .hard: return 0.058
        }
    }

    private func starY(progress p: CGFloat, lane: Int, wavePhase: CGFloat) -> CGFloat {
        let lanes = CGFloat(max(1, laneCount))
        let base = (CGFloat(lane) + 0.5) / lanes
        let wave = sin(p * .pi * 2 * 2.5 + CGFloat(lane) * 0.7 + wavePhase) * 0.11
        let hardJitter = difficulty == .hard ? sin(CGFloat(elapsed) * 4 + CGFloat(lane)) * 0.018 : 0
        return min(0.96, max(0.04, base + wave + hardJitter))
    }

    private func advance(dt: Double) {
        guard phase == .playing else { return }
        elapsed += dt

        if elapsed >= timeLimit {
            phase = caught >= target ? .won : .lost
            stop()
            return
        }

        let speedMultiplier: CGFloat = 2.8
        let delta = CGFloat(dt) * baseSpeed * speedMultiplier
        let gate: CGFloat = 0.92
        let window = hitWindow()

        for idx in stars.indices {
            var s = stars[idx]
            let previous = s.progress
            var next = s.progress + delta * s.speedMultiplier
            if difficulty == .hard {
                next += sin(CGFloat(elapsed * 6) + CGFloat(idx)) * CGFloat(dt) * 0.04
            }

            var crossed = s.crossedThisLap

            if previous < gate && next >= gate && !crossed {
                crossed = true
                attempts += 1
                let sy = starY(progress: gate, lane: s.lane, wavePhase: s.wavePhase)
                if abs(alignment - sy) < window {
                    caught += 1
                } else {
                    lives -= 1
                    misses += 1
                }
            }

            if next >= 1 {
                next = next.truncatingRemainder(dividingBy: 1)
                crossed = false
                s.wavePhase = newWavePhase()
            }

            s.progress = max(0, next)
            s.crossedThisLap = crossed
            stars[idx] = s
        }

        if caught >= target {
            phase = .won
            stop()
        } else if lives <= 0 {
            phase = .lost
            stop()
        }
    }

    func accuracy() -> Double {
        let total = max(1, attempts)
        return min(1, Double(max(0, attempts - misses)) / Double(total))
    }

    func starAward() -> Int {
        guard phase == .won else { return 0 }
        let ratio = elapsed / max(1, timeLimit)
        if ratio < 0.52 { return 3 }
        if ratio < 0.78 { return 2 }
        return 1
    }
}
