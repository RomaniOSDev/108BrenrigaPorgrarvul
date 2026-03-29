import SwiftUI

enum GameType: String, CaseIterable, Identifiable {
    case starCollector
    case colorMatch
    case shapeEscape

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .starCollector: return "Star Collector"
        case .colorMatch: return "Color Match"
        case .shapeEscape: return "Shape Escape"
        }
    }

    var tabSystemImage: String {
        switch self {
        case .starCollector: return "sparkles"
        case .colorMatch: return "circle.hexagongrid"
        case .shapeEscape: return "point.topleft.down.curvedto.point.bottomright.up"
        }
    }
}

enum RootTab: Hashable {
    case home
    case game(GameType)
}

enum Difficulty: String, CaseIterable, Identifiable {
    case easy
    case normal
    case hard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .easy: return "Easy"
        case .normal: return "Normal"
        case .hard: return "Hard"
        }
    }
}

enum PaletteTone: Int, CaseIterable {
    case primary
    case accent
    case surface
    case background
    case textPrimary
    case textSecondary

    var color: Color {
        switch self {
        case .primary: return .appPrimary
        case .accent: return .appAccent
        case .surface: return .appSurface
        case .background: return .appBackground
        case .textPrimary: return .appTextPrimary
        case .textSecondary: return .appTextSecondary
        }
    }

    static func tones(for difficulty: Difficulty) -> [PaletteTone] {
        switch difficulty {
        case .easy: return [.primary, .accent]
        case .normal: return [.primary, .accent, .surface, .textSecondary]
        case .hard: return PaletteTone.allCases.map { $0 }
        }
    }
}

struct GameSessionResult: Hashable, Identifiable {
    let id: UUID
    let game: GameType
    let level: Int
    let difficulty: Difficulty
    let starsEarned: Int
    let elapsedSeconds: Double
    let accuracy01: Double
    let isWin: Bool

    init(
        id: UUID = UUID(),
        game: GameType,
        level: Int,
        difficulty: Difficulty,
        starsEarned: Int,
        elapsedSeconds: Double,
        accuracy01: Double,
        isWin: Bool
    ) {
        self.id = id
        self.game = game
        self.level = level
        self.difficulty = difficulty
        self.starsEarned = starsEarned
        self.elapsedSeconds = elapsedSeconds
        self.accuracy01 = accuracy01
        self.isWin = isWin
    }
}

enum AchievementID: String, CaseIterable, Hashable {
    case firstVictory
    case starCollectorTen
    case triGameExplorer
    case tripleStarStreak
    case marathonPlayer

    var title: String {
        switch self {
        case .firstVictory: return "First Victory"
        case .starCollectorTen: return "Bright Start"
        case .triGameExplorer: return "Triple Play"
        case .tripleStarStreak: return "Sharp Run"
        case .marathonPlayer: return "Dedicated Player"
        }
    }
}
