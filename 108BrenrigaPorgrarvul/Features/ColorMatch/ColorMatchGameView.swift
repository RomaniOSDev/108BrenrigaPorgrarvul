import SwiftUI

struct ColorMatchGameView: View {
    let level: Int
    let difficulty: Difficulty
    var onFinish: (GameSessionResult) -> Void

    @StateObject private var model: ColorMatchViewModel
    @State private var delivered = false

    init(level: Int, difficulty: Difficulty, onFinish: @escaping (GameSessionResult) -> Void) {
        self.level = level
        self.difficulty = difficulty
        self.onFinish = onFinish
        _model = StateObject(wrappedValue: ColorMatchViewModel(level: level, difficulty: difficulty))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    statLabel("Time left", value: String(format: "%.1fs", model.timeRemaining))
                    statLabel("Tiles", value: "\(model.rows)×\(model.cols)")
                }
                .padding(.horizontal, 12)

                VStack(spacing: 10) {
                    ForEach(0..<model.rows, id: \.self) { r in
                        HStack(spacing: 10) {
                            ForEach(0..<model.cols, id: \.self) { c in
                                tileView(row: r, col: c)
                            }
                        }
                    }
                }
                .padding(12)
            }
            .padding(.vertical, 12)
        }
        .appScreenBackground()
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

    @ViewBuilder
    private func tileView(row: Int, col: Int) -> some View {
        if model.grid.indices.contains(row), model.grid[row].indices.contains(col) {
            let tile = model.grid[row][col]
            TileShape(base: tile.base, palette: model.palette)
            .frame(width: tileSize(), height: tileSize())
            .rotationEffect(.degrees(Double(tile.rotation) * 90))
            .animation(.easeInOut(duration: 0.3), value: tile.rotation)
            .gesture(
                RotationGesture()
                    .onEnded { angle in
                        if abs(angle.degrees) > 25 {
                            model.rotate(row: row, col: col)
                        }
                    }
            )
            .simultaneousGesture(
                TapGesture().onEnded {
                    model.rotate(row: row, col: col)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(AppGradients.panelRim, lineWidth: 1.5)
            )
            .shadow(color: Color.appPrimary.opacity(0.14), radius: 10, x: 0, y: 5)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            Color.clear
                .frame(width: tileSize(), height: tileSize())
        }
    }

    private func tileSize() -> CGFloat {
        let base = UIScreen.main.bounds.width - 48
        let per = max(60, (base - CGFloat(model.cols - 1) * 10) / CGFloat(max(1, model.cols)))
        return min(92, per)
    }

    private func statLabel(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appFloatingCard(cornerRadius: 12, style: .compact)
    }

    private func exitSession() {
        model.stop()
        let elapsed = max(0, model.initialTime - model.timeRemaining)
        let result = GameSessionResult(
            game: .colorMatch,
            level: level,
            difficulty: difficulty,
            starsEarned: 0,
            elapsedSeconds: elapsed,
            accuracy01: model.accuracy(),
            isWin: false
        )
        onFinish(result)
    }

    private func completeIfNeeded() {
        guard !delivered else { return }
        delivered = true
        let elapsed = max(0, model.initialTime - model.timeRemaining)
        let result = GameSessionResult(
            game: .colorMatch,
            level: level,
            difficulty: difficulty,
            starsEarned: model.starAward(),
            elapsedSeconds: elapsed,
            accuracy01: model.accuracy(),
            isWin: model.phase == .won
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            onFinish(result)
        }
    }
}

private struct TileShape: View {
    let base: [Int]
    let palette: [PaletteTone]

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let r = min(size.width, size.height) / 2
            let colors = base
            let wedges: [(Int, CGFloat, CGFloat)] = [
                (0, -CGFloat.pi / 2, 0),
                (1, 0, CGFloat.pi / 2),
                (2, CGFloat.pi / 2, CGFloat.pi),
                (3, CGFloat.pi, CGFloat.pi * 1.5)
            ]
            for (idx, start, end) in wedges {
                var wedge = Path()
                wedge.move(to: center)
                wedge.addArc(center: center, radius: r, startAngle: Angle(radians: Double(start)), endAngle: Angle(radians: Double(end)), clockwise: false)
                wedge.closeSubpath()
                let tone = palette[colors[idx] % max(1, palette.count)]
                context.fill(wedge, with: .color(tone.color))
            }
            var rim = Path()
            rim.addEllipse(in: CGRect(x: center.x - r * 0.22, y: center.y - r * 0.22, width: r * 0.44, height: r * 0.44))
            context.fill(rim, with: .color(Color.appBackground.opacity(0.92)))
        }
    }
}
