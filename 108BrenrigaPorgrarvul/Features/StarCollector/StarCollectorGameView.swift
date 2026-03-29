import SwiftUI

struct StarCollectorGameView: View {
    let level: Int
    let difficulty: Difficulty
    var onFinish: (GameSessionResult) -> Void

    @StateObject private var model: StarCollectorViewModel
    @State private var delivered = false

    init(level: Int, difficulty: Difficulty, onFinish: @escaping (GameSessionResult) -> Void) {
        self.level = level
        self.difficulty = difficulty
        self.onFinish = onFinish
        _model = StateObject(wrappedValue: StarCollectorViewModel(level: level, difficulty: difficulty))
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                AppGradients.screenMesh
                Color.appBackground.opacity(0.35)

                lanePaths(size: size)
                    .allowsHitTesting(false)

                ForEach(model.stars) { star in
                    let y = starY(star: star, in: size)
                    let x = CGFloat(star.progress) * size.width
                    Circle()
                        .fill(AppGradients.cta)
                        .frame(width: 16, height: 16)
                        .position(x: x, y: y)
                        .shadow(color: Color.appAccent.opacity(0.5), radius: 6, x: 0, y: 2)
                        .animation(.easeInOut(duration: 0.08), value: star.progress)
                }

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.appAccent.opacity(0.45), Color.appPrimary.opacity(0.32)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4)
                    .position(x: size.width * 0.92, y: size.height / 2)
                    .shadow(color: Color.appPrimary.opacity(0.35), radius: 8, x: 0, y: 0)

                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(AppGradients.cta)
                    .frame(width: 8, height: 28)
                    .position(x: size.width * 0.92, y: size.height * model.alignment)
                    .shadow(color: Color.appPrimary.opacity(0.45), radius: 10, x: 0, y: 2)
                    .animation(.spring(response: 0.4, dampingFraction: 0.62), value: model.alignment)

                VStack {
                    HStack {
                        statChip("Goal", value: "\(model.caught)/\(model.target)")
                        statChip("Time", value: timeString(model.timeLimit - model.elapsed))
                        statChip("Lives", value: "\(model.lives)")
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    Spacer()
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard model.phase == .playing else { return }
                        let y = min(max(value.location.y / size.height, 0.05), 0.95)
                        model.alignment = y
                    }
            )
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Exit") {
                    exitSession()
                }
            }
        }
        .onAppear {
            delivered = false
            model.start()
        }
        .onDisappear {
            model.stop()
        }
        .onChange(of: model.phase) { newPhase in
            if newPhase == .won || newPhase == .lost {
                completeIfNeeded()
            }
        }
    }

    private func exitSession() {
        model.stop()
        let result = GameSessionResult(
            game: .starCollector,
            level: level,
            difficulty: difficulty,
            starsEarned: 0,
            elapsedSeconds: model.elapsed,
            accuracy01: model.accuracy(),
            isWin: false
        )
        onFinish(result)
    }

    private func completeIfNeeded() {
        guard !delivered else { return }
        delivered = true
        let result = GameSessionResult(
            game: .starCollector,
            level: level,
            difficulty: difficulty,
            starsEarned: model.starAward(),
            elapsedSeconds: model.elapsed,
            accuracy01: model.accuracy(),
            isWin: model.phase == .won
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onFinish(result)
        }
    }

    private func statChip(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
            Text(value)
                .font(.footnote.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appFloatingCard(cornerRadius: 12, style: .compact)
    }

    private func timeString(_ remaining: Double) -> String {
        let t = max(0, remaining)
        let sec = Int(ceil(t))
        return "\(sec)s"
    }

    private func starY(star: StarCollectorViewModel.MovingStar, in size: CGSize) -> CGFloat {
        let lanes = CGFloat(max(1, model.laneCount))
        let base = (CGFloat(star.lane) + 0.5) / lanes
        let wave = sin(star.progress * .pi * 2 * 2.5 + CGFloat(star.lane) * 0.7 + star.wavePhase) * 0.11
        let extra = model.difficulty == .hard ? sin(CGFloat(model.elapsed) * 4 + CGFloat(star.lane)) * 0.018 : 0
        let frac = min(0.96, max(0.04, base + wave + extra))
        return frac * size.height
    }

    private func lanePaths(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let lanes = max(1, model.laneCount)
            for lane in 0..<lanes {
                var path = Path()
                let steps = 60
                for step in 0...steps {
                    let p = CGFloat(step) / CGFloat(steps)
                    let x = p * canvasSize.width
                    let lanesF = CGFloat(lanes)
                    let base = (CGFloat(lane) + 0.5) / lanesF
                    let yFrac = min(0.96, max(0.04, base + sin(p * .pi * 2 * 2.5 + CGFloat(lane) * 0.7) * 0.11))
                    let y = yFrac * canvasSize.height
                    if step == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                context.stroke(path, with: .color(Color.appSurface), lineWidth: 3)
            }
        }
        .frame(width: size.width, height: size.height)
    }
}
