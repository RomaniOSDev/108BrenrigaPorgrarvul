import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: RootTab
    @EnvironmentObject private var store: GameProgressStore
    @State private var showSettings = false
    @State private var heroPulse = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroHeader
                    statsRow
                    sectionTitle("Challenges")
                    ForEach(GameType.allCases) { game in
                        gameCard(game)
                    }
                    achievementsStrip
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .appScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Home")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                        .shadow(color: Color.appPrimary.opacity(0.25), radius: 8, x: 0, y: 2)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(AppGradients.panel)
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Circle()
                                        .strokeBorder(AppGradients.panelRim, lineWidth: 1)
                                }
                                .shadow(color: Color.appPrimary.opacity(0.2), radius: 10, x: 0, y: 4)
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.appPrimary, Color.appAccent],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                        .environmentObject(store)
                }
            }
        }
        .tint(Color.appPrimary)
        .onAppear {
            syncHeroPulseAnimation()
        }
        .onChange(of: selectedTab) { _ in
            syncHeroPulseAnimation()
        }
    }

    private func syncHeroPulseAnimation() {
        if selectedTab == .home {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                heroPulse = true
            }
        } else {
            heroPulse = false
        }
    }

    private var heroHeader: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppGradients.hero)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(AppGradients.panelRim, lineWidth: 1)
                }
                .overlay(alignment: .top) {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(AppGradients.glossTop)
                        .frame(height: 72)
                        .allowsHitTesting(false)
                }

            Group {
                if selectedTab == .home {
                    HomeHeroBackdrop(pulse: heroPulse)
                } else {
                    Color.clear
                }
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 10) {
                Text(greetingLine)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.appTextSecondary)
                Text("Three quick challenges.")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Swipe, rotate, and trace paths — collect stars and unlock every stage.")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
        }
        .shadow(color: Color.appPrimary.opacity(0.18), radius: 22, x: 0, y: 12)
        .shadow(color: Color.appBackground.opacity(0.6), radius: 2, x: 0, y: 2)
        .padding(.top, 8)
    }

    private var greetingLine: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Welcome back"
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statTile(
                icon: "star.fill",
                value: "\(store.totalStarsCollected)",
                label: "Stars",
                accent: Color.appAccent
            )
            statTile(
                icon: "flag.checkered",
                value: "\(store.victoriesCount)",
                label: "Cleared",
                accent: Color.appPrimary
            )
            statTile(
                icon: "clock.fill",
                value: shortPlayTime,
                label: "Play time",
                accent: Color.appTextSecondary
            )
        }
    }

    private var shortPlayTime: String {
        let s = max(0, store.totalPlaySeconds)
        let m = Int(s) / 60
        if m >= 60 {
            let h = m / 60
            let mm = m % 60
            return "\(h)h \(mm)m"
        }
        return "\(m)m"
    }

    private func statTile(icon: String, value: String, label: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(accent)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .appFloatingCard(cornerRadius: 16, style: .compact)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.appTextSecondary)
            .textCase(.uppercase)
            .tracking(0.6)
    }

    private func gameCard(_ game: GameType) -> some View {
        let stars = store.totalStars(for: game)
        let furthest = store.furthestVictoryLevel(for: game)
        let subtitle: String = {
            if furthest == 0 {
                return "Tap to begin · \(GameConstants.levelsPerGame) stages"
            }
            return "Best: level \(furthest) · \(stars) stars earned"
        }()

        return Button {
            selectedTab = .game(game)
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppGradients.panel)
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(AppGradients.panelRim.opacity(0.55), lineWidth: 0.75)
                        }
                    Image(systemName: game.tabSystemImage)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.appPrimary, Color.appAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.appPrimary.opacity(0.35), radius: 6, x: 0, y: 2)
                }
                .frame(width: 58, height: 58)
                .shadow(color: Color.appBackground.opacity(0.45), radius: 2, x: 0, y: 1)

                VStack(alignment: .leading, spacing: 6) {
                    Text(game.displayTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                        .multilineTextAlignment(.leading)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
                    .shadow(color: Color.appAccent.opacity(0.35), radius: 4, x: 0, y: 1)
            }
            .padding(16)
            .appFloatingCard(cornerRadius: 18, style: .raised)
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
    }

    private var achievementsStrip: some View {
        let earned = store.currentAchievements().count
        let total = AchievementID.allCases.count

        return Button {
            showSettings = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppGradients.cta.opacity(0.2))
                        .frame(width: 48, height: 48)
                        .overlay {
                            Circle()
                                .strokeBorder(Color.appAccent.opacity(0.45), lineWidth: 1)
                        }
                        .shadow(color: Color.appPrimary.opacity(0.25), radius: 8, x: 0, y: 4)
                    Image(systemName: "seal.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.appAccent)
                        .shadow(color: Color.appAccent.opacity(0.4), radius: 6, x: 0, y: 2)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Achievements & stats")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                    Text("\(earned) of \(total) unlocked · open for details")
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(16)
            .appFloatingCard(cornerRadius: 18, style: .raised)
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .accessibilityHint("Opens settings and statistics")
    }
}

private struct HomeHeroBackdrop: View {
    var pulse: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let warm = Color.appPrimary.opacity(pulse ? 0.35 : 0.22)
                let cool = Color.appAccent.opacity(pulse ? 0.22 : 0.35)

                for i in 0..<4 {
                    let a = t * (0.35 + Double(i) * 0.09) + Double(i)
                    let cx = size.width * (0.22 + CGFloat(i) * 0.18)
                    let cy = size.height * (0.5 + 0.12 * sin(a))
                    let rx = 28 + CGFloat(i) * 8
                    var ellipse = Path()
                    ellipse.addEllipse(in: CGRect(x: cx - rx, y: cy - 16, width: rx * 2, height: 32))
                    ctx.fill(ellipse, with: .color(i % 2 == 0 ? warm : cool))
                }

                var arc = Path()
                arc.addArc(
                    center: CGPoint(x: size.width * 0.85, y: size.height * 0.35),
                    radius: min(size.width, size.height) * 0.45,
                    startAngle: .degrees(-28),
                    endAngle: .degrees(38),
                    clockwise: false
                )
                ctx.stroke(arc, with: .color(Color.appAccent.opacity(0.45)), lineWidth: 3)
            }
        }
    }
}
