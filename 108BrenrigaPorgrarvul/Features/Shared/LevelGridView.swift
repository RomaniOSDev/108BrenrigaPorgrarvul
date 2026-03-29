import SwiftUI

struct LevelGridView: View {
    let game: GameType
    let difficulty: Difficulty
    var onSelect: (Int) -> Void

    @EnvironmentObject private var store: GameProgressStore

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Levels")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
                .padding(.horizontal, 16)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(1...GameConstants.levelsPerGame, id: \.self) { level in
                    levelCell(level)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func levelCell(_ level: Int) -> some View {
        let unlocked = store.isLevelUnlocked(game: game, level: level)
        let stars = store.bestStars(game: game, level: level)

        Button {
            if unlocked {
                onSelect(level)
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    if unlocked {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppGradients.panel)
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(AppGradients.panelRim, lineWidth: 1)
                            }
                            .shadow(color: Color.appPrimary.opacity(0.14), radius: 12, x: 0, y: 6)
                            .shadow(color: Color.appBackground.opacity(0.5), radius: 1, x: 0, y: 2)
                    } else {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.appSurface.opacity(0.4))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Color.appTextSecondary.opacity(0.2), lineWidth: 1)
                            }
                    }

                    if unlocked {
                        Text("\(level)")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.appTextPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .shadow(color: Color.appPrimary.opacity(0.2), radius: 6, x: 0, y: 2)
                    } else {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(Color.appTextSecondary)
                            .font(.title3)
                    }
                }
                .frame(minHeight: 72)

                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < stars ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundStyle(i < stars ? Color.appAccent : Color.appTextSecondary)
                            .shadow(color: i < stars ? Color.appAccent.opacity(0.35) : .clear, radius: 4, x: 0, y: 1)
                    }
                }
                .accessibilityHidden(true)
            }
            .padding(10)
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
        .accessibilityLabel("Level \(level)")
    }
}
