import SwiftUI

struct GameHubView: View {
    let game: GameType
    @State private var difficulty: Difficulty = .easy
    @State private var activeSpec: ActiveGameSpec?
    @State private var resultPack: ResultPack?

    @EnvironmentObject private var store: GameProgressStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    GameDifficultyPicker(selection: $difficulty)
                    LevelGridView(game: game, difficulty: difficulty) { level in
                        activeSpec = ActiveGameSpec(game: game, level: level, difficulty: difficulty)
                    }
                }
                .padding(.vertical, 12)
            }
            .appScreenBackground()
            .navigationTitle(game.displayTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
        .fullScreenCover(item: $activeSpec) { spec in
            NavigationStack {
                gameSession(for: spec)
            }
        }
        .fullScreenCover(item: $resultPack) { pack in
            GameResultView(
                result: pack.result,
                newAchievements: pack.newAchievements,
                onNextLevel: {
                    let next = pack.result.level + 1
                    let g = pack.result.game
                    let d = pack.result.difficulty
                    resultPack = nil
                    if store.isLevelUnlocked(game: g, level: next) {
                        activeSpec = ActiveGameSpec(game: g, level: next, difficulty: d)
                    }
                },
                onRetry: {
                    let r = pack.result
                    resultPack = nil
                    activeSpec = ActiveGameSpec(game: r.game, level: r.level, difficulty: r.difficulty)
                },
                onLevels: {
                    resultPack = nil
                    activeSpec = nil
                }
            )
        }
    }

    @ViewBuilder
    private func gameSession(for spec: ActiveGameSpec) -> some View {
        switch spec.game {
        case .starCollector:
            StarCollectorGameView(level: spec.level, difficulty: spec.difficulty) { outcome in
                finish(outcome: outcome)
            }
        case .colorMatch:
            ColorMatchGameView(level: spec.level, difficulty: spec.difficulty) { outcome in
                finish(outcome: outcome)
            }
        case .shapeEscape:
            ShapeEscapeGameView(level: spec.level, difficulty: spec.difficulty) { outcome in
                finish(outcome: outcome)
            }
        }
    }

    private func finish(outcome: GameSessionResult) {
        let snapshot = store.currentAchievements()
        store.recordCompletion(
            game: outcome.game,
            level: outcome.level,
            starsEarned: outcome.starsEarned,
            elapsedSeconds: outcome.elapsedSeconds,
            isWin: outcome.isWin
        )
        let fresh = store.newAchievements(since: snapshot)
        activeSpec = nil
        resultPack = ResultPack(result: outcome, newAchievements: fresh)
    }
}

struct ResultPack: Identifiable {
    let id: UUID
    let result: GameSessionResult
    let newAchievements: [AchievementID]

    init(result: GameSessionResult, newAchievements: [AchievementID]) {
        self.id = result.id
        self.result = result
        self.newAchievements = newAchievements
    }
}
