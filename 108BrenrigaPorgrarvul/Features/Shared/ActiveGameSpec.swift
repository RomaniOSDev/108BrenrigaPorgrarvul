import Foundation

struct ActiveGameSpec: Identifiable, Hashable {
    let id: String
    let game: GameType
    let level: Int
    let difficulty: Difficulty

    init(game: GameType, level: Int, difficulty: Difficulty) {
        self.game = game
        self.level = level
        self.difficulty = difficulty
        self.id = "\(game.rawValue)|\(level)|\(difficulty.rawValue)"
    }
}
