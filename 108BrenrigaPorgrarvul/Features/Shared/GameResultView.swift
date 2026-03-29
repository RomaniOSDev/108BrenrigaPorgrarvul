import SwiftUI

struct GameResultView: View {
    let result: GameSessionResult
    let newAchievements: [AchievementID]
    var onNextLevel: () -> Void
    var onRetry: () -> Void
    var onLevels: () -> Void

    @State private var starBurst = false
    @State private var bannerOffset: CGFloat = -200

    private var canGoNext: Bool {
        result.isWin && result.level < GameConstants.levelsPerGame
    }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 22) {
                    Text(result.isWin ? "Complete" : "Try Again")
                        .font(.title.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                        .shadow(color: Color.appPrimary.opacity(0.22), radius: 12, x: 0, y: 4)

                    HStack(spacing: 14) {
                        ForEach(0..<3, id: \.self) { i in
                            let on = i < result.starsEarned
                            Image(systemName: on ? "star.fill" : "star")
                                .font(.system(size: 36))
                                .foregroundStyle(on ? Color.appAccent : Color.appTextSecondary)
                                .shadow(color: on ? Color.appPrimary.opacity(0.55) : .clear, radius: on ? 10 : 0)
                                .scaleEffect(starBurst ? (on ? 1.12 : 1.0) : 0.55)
                                .animation(
                                    .spring(response: 0.45, dampingFraction: 0.55)
                                        .delay(Double(i) * 0.15),
                                    value: starBurst
                                )
                        }
                    }
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 10) {
                        statRow("Time", value: formatTime(result.elapsedSeconds))
                        statRow("Accuracy", value: "\(Int((result.accuracy01 * 100).rounded()))%")
                        statRow("Outcome", value: result.isWin ? "Success" : "Incomplete")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .appFloatingCard(cornerRadius: 16, style: .raised)

                    VStack(spacing: 12) {
                        if canGoNext {
                            resultButton(title: "Next Level", role: .primary, action: onNextLevel)
                        }
                        resultButton(title: "Retry", role: .secondary, action: onRetry)
                        resultButton(title: "Level Selection", role: .ghost, action: onLevels)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 28)
                .padding(.top, newAchievements.isEmpty ? 0 : 56)
            }

            if !newAchievements.isEmpty {
                VStack(spacing: 6) {
                    ForEach(newAchievements, id: \.self) { a in
                        Text("New achievement: \(a.title)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.appBackground)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(AppGradients.cta)
                            )
                            .shadow(color: Color.appPrimary.opacity(0.4), radius: 14, x: 0, y: 6)
                    }
                }
                .padding(.horizontal, 16)
                .offset(y: bannerOffset)
                .animation(.spring(response: 0.55, dampingFraction: 0.72), value: bannerOffset)
            }
        }
        .appScreenBackground()
        .onAppear {
            DispatchQueue.main.async {
                starBurst = true
            }
            if !newAchievements.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    bannerOffset = 0
                }
            }
        }
    }

    private func statRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.appTextSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(Color.appTextPrimary)
                .font(.body.weight(.semibold))
        }
    }

    private func formatTime(_ s: Double) -> String {
        let t = max(0, s)
        let m = Int(t) / 60
        let sec = Int(t) % 60
        return String(format: "%d:%02d", m, sec)
    }

    private enum Role {
        case primary
        case secondary
        case ghost
    }

    private func resultButton(title: String, role: Role, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(foreground(for: role))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .modifier(ResultButtonBackground(role: role))
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
    }

    private func foreground(for role: Role) -> Color {
        switch role {
        case .primary: return Color.appBackground
        case .secondary: return Color.appTextPrimary
        case .ghost: return Color.appPrimary
        }
    }
}

extension GameResultView {
    private struct ResultButtonBackground: ViewModifier {
        let role: GameResultView.Role

        func body(content: Content) -> some View {
            switch role {
            case .primary:
                content
                    .appPrimaryButtonChrome(cornerRadius: 14)
            case .secondary:
                content
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppGradients.panel)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.appPrimary.opacity(0.28), lineWidth: 1)
                    }
                    .shadow(color: Color.appPrimary.opacity(0.1), radius: 12, x: 0, y: 6)
            case .ghost:
                content
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.appSurface.opacity(0.15))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(AppGradients.panelRim, lineWidth: 1.25)
                    }
            }
        }
    }
}
