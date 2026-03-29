import Combine
import Foundation
import SwiftUI

extension Notification.Name {
    static let gameProgressDidReset = Notification.Name("gameProgressDidReset")
}

enum GameConstants {
    static let levelsPerGame = 12
}

@MainActor
final class GameProgressStore: ObservableObject {
    private let defaults = UserDefaults.standard

    private enum Key {
        static let onboarding = "progress.hasSeenOnboarding"
        static let playTime = "progress.totalPlaySeconds"
        static let activities = "progress.totalActivities"
        static let playedGames = "progress.playedGames"
        static let streakThreeStars = "progress.streakThreeStars"

        static func stars(_ game: GameType, level: Int) -> String {
            "progress.stars.\(game.rawValue).\(level)"
        }
    }

    @Published private(set) var hasSeenOnboarding: Bool

    init() {
        hasSeenOnboarding = defaults.bool(forKey: Key.onboarding)
    }

    func completeOnboarding() {
        defaults.set(true, forKey: Key.onboarding)
        hasSeenOnboarding = true
        objectWillChange.send()
    }

    func bestStars(game: GameType, level: Int) -> Int {
        guard level >= 1, level <= GameConstants.levelsPerGame else { return 0 }
        return min(3, max(0, defaults.integer(forKey: Key.stars(game, level: level))))
    }

    func isLevelUnlocked(game: GameType, level: Int) -> Bool {
        guard level >= 1, level <= GameConstants.levelsPerGame else { return false }
        if level == 1 { return true }
        return bestStars(game: game, level: level - 1) >= 1
    }

    var totalPlaySeconds: Double {
        defaults.double(forKey: Key.playTime)
    }

    var totalActivitiesPlayed: Int {
        defaults.integer(forKey: Key.activities)
    }

    var victoriesCount: Int {
        var n = 0
        for g in GameType.allCases {
            for lv in 1...GameConstants.levelsPerGame {
                if bestStars(game: g, level: lv) >= 1 {
                    n += 1
                }
            }
        }
        return n
    }

    var totalStarsCollected: Int {
        var t = 0
        for g in GameType.allCases {
            for lv in 1...GameConstants.levelsPerGame {
                t += bestStars(game: g, level: lv)
            }
        }
        return t
    }

    private var playedGameRawValues: Set<String> {
        Set(defaults.stringArray(forKey: Key.playedGames) ?? [])
    }

    func hasPlayed(game: GameType) -> Bool {
        playedGameRawValues.contains(game.rawValue)
    }

    func currentAchievements() -> Set<AchievementID> {
        var s = Set<AchievementID>()
        if victoriesCount >= 1 {
            s.insert(.firstVictory)
        }
        if totalStarsCollected >= 10 {
            s.insert(.starCollectorTen)
        }
        if GameType.allCases.allSatisfy({ hasPlayed(game: $0) }) {
            s.insert(.triGameExplorer)
        }
        if defaults.integer(forKey: Key.streakThreeStars) >= 3 {
            s.insert(.tripleStarStreak)
        }
        if totalActivitiesPlayed >= 30 {
            s.insert(.marathonPlayer)
        }
        return s
    }

    func newAchievements(since previousSnapshot: Set<AchievementID>) -> [AchievementID] {
        let now = currentAchievements()
        return Array(now.subtracting(previousSnapshot)).sorted { $0.rawValue < $1.rawValue }
    }

    func totalStars(for game: GameType) -> Int {
        (1...GameConstants.levelsPerGame).reduce(0) { $0 + bestStars(game: game, level: $1) }
    }

    func furthestVictoryLevel(for game: GameType) -> Int {
        var highest = 0
        for lv in 1...GameConstants.levelsPerGame where bestStars(game: game, level: lv) >= 1 {
            highest = lv
        }
        return highest
    }

    func recordCompletion(
        game: GameType,
        level: Int,
        starsEarned: Int,
        elapsedSeconds: Double,
        isWin: Bool
    ) {
        let clampedTime = max(0, elapsedSeconds)
        let prevTime = defaults.double(forKey: Key.playTime)
        defaults.set(prevTime + clampedTime, forKey: Key.playTime)

        let prevAct = defaults.integer(forKey: Key.activities)
        defaults.set(prevAct + 1, forKey: Key.activities)

        var played = playedGameRawValues
        played.insert(game.rawValue)
        defaults.set(Array(played), forKey: Key.playedGames)

        if isWin {
            let prevBest = bestStars(game: game, level: level)
            let next = min(3, max(prevBest, starsEarned))
            defaults.set(next, forKey: Key.stars(game, level: level))

            if starsEarned >= 3 {
                let st = defaults.integer(forKey: Key.streakThreeStars) + 1
                defaults.set(st, forKey: Key.streakThreeStars)
            } else {
                defaults.set(0, forKey: Key.streakThreeStars)
            }
        } else {
            defaults.set(0, forKey: Key.streakThreeStars)
        }

        objectWillChange.send()
    }

    func resetAllProgress() {
        for g in GameType.allCases {
            for lv in 1...GameConstants.levelsPerGame {
                defaults.removeObject(forKey: Key.stars(g, level: lv))
            }
        }
        defaults.removeObject(forKey: Key.playTime)
        defaults.removeObject(forKey: Key.activities)
        defaults.removeObject(forKey: Key.playedGames)
        defaults.removeObject(forKey: Key.streakThreeStars)
        objectWillChange.send()
        NotificationCenter.default.post(name: .gameProgressDidReset, object: nil)
    }
}
