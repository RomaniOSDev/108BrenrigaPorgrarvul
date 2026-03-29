import Combine
import SwiftUI

@MainActor
final class ShapeEscapeViewModel: ObservableObject {
    enum PlayPhase {
        case ready
        case playing
        case won
        case lost
    }

    @Published var phase: PlayPhase = .ready
    @Published var player: (Int, Int) = (0, 0)
    @Published var maze: MazeLayout
    @Published var elapsed: Double = 0
    @Published var gatePulse: CGFloat = 0
    @Published private(set) var moves: Int = 0

    let level: Int
    let difficulty: Difficulty
    let hazardKeys: Set<String>
    let timeLimit: Double?

    private var ticker: AnyCancellable?
    private var hazardClock: CGFloat = 0
    private var optimalSteps: Int = 0

    init(level: Int, difficulty: Difficulty) {
        self.level = level
        self.difficulty = difficulty

        let size = ShapeEscapeViewModel.mazeSize(level: level)
        self.maze = MazeLayout.generate(rows: size, cols: size)

        let cellTotal = size * size
        let diffIdx: Int = switch difficulty {
        case .easy: 0
        case .normal: 1
        case .hard: 2
        }
        let sampleCount = min(max(2, size + diffIdx), cellTotal - 2)
        var keys = Set<String>()
        while keys.count < sampleCount {
            let r = Int.random(in: 0..<size)
            let c = Int.random(in: 0..<size)
            if (r == 0 && c == 0) || (r == size - 1 && c == size - 1) {
                continue
            }
            keys.insert("\(r),\(c)")
        }
        if difficulty == .easy {
            keys = []
        }
        hazardKeys = keys

        switch difficulty {
        case .easy:
            timeLimit = nil
        case .normal:
            timeLimit = max(55, 85 - Double(level))
        case .hard:
            timeLimit = max(40, 70 - Double(level))
        }

        optimalSteps = max(1, size * 2 - 2)
    }

    static func mazeSize(level: Int) -> Int {
        min(9, max(4, 4 + level / 4))
    }

    func start() {
        stop()
        phase = .playing
        player = (0, 0)
        elapsed = 0
        hazardClock = 0
        moves = 0
        gatePulse = 0
        ticker = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick(dt: 1.0 / 60.0)
            }
    }

    func stop() {
        ticker?.cancel()
        ticker = nil
    }

    private func tick(dt: Double) {
        guard phase == .playing else { return }
        elapsed += dt
        hazardClock += CGFloat(dt)
        gatePulse += CGFloat(dt)

        if let limit = timeLimit, elapsed >= limit {
            phase = .lost
            stop()
        }
    }

    func hazardBlocks(row: Int, col: Int) -> Bool {
        guard difficulty != .easy else { return false }
        let key = "\(row),\(col)"
        guard hazardKeys.contains(key) else { return false }
        let period: CGFloat = difficulty == .hard ? 0.95 : 1.35
        let phase = Int(floor(Double(hazardClock / period))) % 2
        return phase == 0
    }

    func attemptMove(delta: (Int, Int)) {
        guard phase == .playing else { return }
        let next = (player.0 + delta.0, player.1 + delta.1)
        guard maze.canMove(from: player, delta: delta) else { return }
        if hazardBlocks(row: next.0, col: next.1) {
            return
        }
        player = next
        moves += 1
        withAnimation(.easeIn(duration: 0.5)) {
            gatePulse += 0.01
        }
        if player.0 == maze.rows - 1, player.1 == maze.cols - 1 {
            phase = .won
            stop()
        }
    }

    func accuracy() -> Double {
        let ratio = Double(moves) / Double(max(1, optimalSteps))
        return min(1, max(0, 2 - ratio))
    }

    func starAward() -> Int {
        guard phase == .won else { return 0 }
        switch difficulty {
        case .easy:
            if moves <= optimalSteps + 1 { return 3 }
            if moves <= optimalSteps + 4 { return 2 }
            return 1
        case .normal:
            let timeScore = timeLimit.map { elapsed < $0 * 0.55 } ?? true
            if timeScore && moves <= optimalSteps + 2 { return 3 }
            if moves <= optimalSteps + 5 { return 2 }
            return 1
        case .hard:
            let timeScore = timeLimit.map { elapsed < $0 * 0.5 } ?? true
            if timeScore && moves <= optimalSteps + 3 { return 3 }
            if moves <= optimalSteps + 7 { return 2 }
            return 1
        }
    }
}
