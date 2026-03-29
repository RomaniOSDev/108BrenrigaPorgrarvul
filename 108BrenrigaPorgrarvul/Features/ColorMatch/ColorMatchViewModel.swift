import Combine
import SwiftUI

@MainActor
final class ColorMatchViewModel: ObservableObject {
    enum PlayPhase {
        case ready
        case playing
        case won
        case lost
    }

    struct CellTile: Identifiable {
        let id: UUID
        var rotation: Int
        let base: [Int]
    }

    @Published var phase: PlayPhase = .ready
    @Published var grid: [[CellTile]] = []
    @Published var timeRemaining: Double = 0

    let level: Int
    let difficulty: Difficulty
    let rows: Int
    let cols: Int
    let palette: [PaletteTone]

    private var timer: AnyCancellable?
    let initialTime: Double

    init(level: Int, difficulty: Difficulty) {
        self.level = level
        self.difficulty = difficulty
        let (r, c) = ColorMatchViewModel.gridSize(level: level, difficulty: difficulty)
        rows = r
        cols = c
        palette = PaletteTone.tones(for: difficulty)
        let baseTime = 28 + Double(r * c) * 2.6 - Double(level) * 0.6
        initialTime = max(14, baseTime)
        timeRemaining = initialTime
        rebuildGrid()
    }

    static func gridSize(level: Int, difficulty: Difficulty) -> (Int, Int) {
        switch difficulty {
        case .easy:
            return level <= 4 ? (2, 2) : (2, 3)
        case .normal:
            return level <= 6 ? (3, 3) : (3, 4)
        case .hard:
            return level <= 8 ? (4, 4) : (4, 5)
        }
    }

    func start() {
        stop()
        phase = .playing
        timeRemaining = initialTime
        rebuildGrid()
        timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick(dt: 1.0 / 30.0)
            }
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    private func tick(dt: Double) {
        guard phase == .playing else { return }
        timeRemaining -= dt
        if timeRemaining <= 0 {
            timeRemaining = 0
            phase = isSolved() ? .won : .lost
            stop()
        }
    }

    private func buildSolvedGrid() {
        let k = max(1, palette.count)
        var built: [[CellTile]] = []
        built.reserveCapacity(rows)
        for r in 0..<rows {
            var rowTiles: [CellTile] = []
            var incomingWest = Int.random(in: 0..<k)
            for c in 0..<cols {
                let north: Int
                if r == 0 {
                    north = Int.random(in: 0..<k)
                } else {
                    north = built[r - 1][c].base[2]
                }
                let south = Int.random(in: 0..<k)
                let east = Int.random(in: 0..<k)
                let base = [north, east, south, incomingWest]
                let tile = CellTile(id: UUID(), rotation: 0, base: base)
                rowTiles.append(tile)
                incomingWest = east
            }
            built.append(rowTiles)
        }
        grid = built
    }

    private func rebuildGrid() {
        guard rows > 0, cols > 0 else {
            grid = []
            return
        }
        buildSolvedGrid()
        shuffleRotations()
    }

    private func shuffleRotations() {
        let moves = 18 + level * 2
        for _ in 0..<moves {
            let r = Int.random(in: 0..<rows)
            let c = Int.random(in: 0..<cols)
            grid[r][c].rotation = (grid[r][c].rotation + 1) % 4
        }
        // Scramble must not start already solved (many non‑zero rotations still match with 2 colors).
        var guardN = 0
        while edgesAllMatch() && guardN < 200 {
            let r = Int.random(in: 0..<rows)
            let c = Int.random(in: 0..<cols)
            grid[r][c].rotation = (grid[r][c].rotation + 1) % 4
            guardN += 1
        }
    }

    func colorsNESW(_ tile: CellTile) -> [Int] {
        var arr = tile.base
        var r = tile.rotation % 4
        while r > 0 {
            arr = [arr[3], arr[0], arr[1], arr[2]]
            r -= 1
        }
        return arr
    }

    func rotate(row: Int, col: Int) {
        guard phase == .playing else { return }
        guard row >= 0, row < rows, col >= 0, col < cols else { return }
        var next = grid
        next[row][col].rotation = (next[row][col].rotation + 1) % 4
        grid = next
        if isSolved() {
            phase = .won
            stop()
        }
    }

    /// Win when every shared edge matches (same palette index). Requiring all `rotation == 0` was wrong:
    /// with few colors, many valid solutions exist where pieces are rotated but edges still align.
    func isSolved() -> Bool {
        edgesAllMatch()
    }

    private func edgesAllMatch() -> Bool {
        for r in 0..<rows {
            for c in 0..<cols {
                let v = colorsNESW(grid[r][c])
                if c + 1 < cols {
                    let right = colorsNESW(grid[r][c + 1])
                    if v[1] != right[3] { return false }
                }
                if r + 1 < rows {
                    let down = colorsNESW(grid[r + 1][c])
                    if v[2] != down[0] { return false }
                }
            }
        }
        return true
    }

    func starAward() -> Int {
        guard phase == .won else { return 0 }
        let ratio = timeRemaining / max(1, initialTime)
        if ratio > 0.55 { return 3 }
        if ratio > 0.28 { return 2 }
        return 1
    }

    func accuracy() -> Double {
        var correct = 0
        var total = 0
        for r in 0..<rows {
            for c in 0..<cols {
                let v = colorsNESW(grid[r][c])
                if c + 1 < cols {
                    total += 1
                    let right = colorsNESW(grid[r][c + 1])
                    if v[1] == right[3] {
                        correct += 1
                    }
                }
                if r + 1 < rows {
                    total += 1
                    let down = colorsNESW(grid[r + 1][c])
                    if v[2] == down[0] {
                        correct += 1
                    }
                }
            }
        }
        return total == 0 ? 1 : Double(correct) / Double(total)
    }
}
