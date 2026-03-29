import SwiftUI

struct ShapeEscapeGameView: View {
    let level: Int
    let difficulty: Difficulty
    var onFinish: (GameSessionResult) -> Void

    @StateObject private var model: ShapeEscapeViewModel
    @State private var delivered = false
    @State private var dragStart: CGPoint?

    init(level: Int, difficulty: Difficulty, onFinish: @escaping (GameSessionResult) -> Void) {
        self.level = level
        self.difficulty = difficulty
        self.onFinish = onFinish
        _model = StateObject(wrappedValue: ShapeEscapeViewModel(level: level, difficulty: difficulty))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    statLabel("Moves", value: "\(model.moves)")
                    statLabel("Elapsed", value: String(format: "%.1fs", model.elapsed))
                    if let limit = model.timeLimit {
                        statLabel("Limit", value: String(format: "%.0fs", limit))
                    }
                }
                .padding(.horizontal, 12)

                GeometryReader { geo in
                    let inset = geo.size.width - 24
                    let cell = inset / CGFloat(max(model.maze.cols, model.maze.rows))
                    mazeCanvas(cellSize: cell)
                        .frame(width: cell * CGFloat(model.maze.cols), height: cell * CGFloat(model.maze.rows))
                        .frame(maxWidth: .infinity)
                        .highPriorityGesture(navGesture())
                }
                .frame(minHeight: 360)
                .padding(.horizontal, 12)
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

    private func mazeCanvas(cellSize: CGFloat) -> some View {
        Canvas { context, size in
            let rows = model.maze.rows
            let cols = model.maze.cols
            let cell = min(size.width / CGFloat(cols), size.height / CGFloat(rows))

            for r in 0...rows {
                var hPath = Path()
                let y = CGFloat(r) * cell
                hPath.move(to: CGPoint(x: 0, y: y))
                hPath.addLine(to: CGPoint(x: CGFloat(cols) * cell, y: y))
                context.stroke(hPath, with: .color(Color.appSurface.opacity(0.35)), lineWidth: 2)
            }
            for c in 0...cols {
                var vPath = Path()
                let x = CGFloat(c) * cell
                vPath.move(to: CGPoint(x: x, y: 0))
                vPath.addLine(to: CGPoint(x: x, y: CGFloat(rows) * cell))
                context.stroke(vPath, with: .color(Color.appSurface.opacity(0.35)), lineWidth: 2)
            }

            for r in 0..<rows {
                for c in 0..<cols {
                    let origin = CGPoint(x: CGFloat(c) * cell, y: CGFloat(r) * cell)
                    if c < model.maze.eastOpen[r].count, !model.maze.eastOpen[r][c] {
                        var wall = Path()
                        let x = origin.x + cell
                        wall.move(to: CGPoint(x: x, y: origin.y))
                        wall.addLine(to: CGPoint(x: x, y: origin.y + cell))
                        context.stroke(wall, with: .color(Color.appTextSecondary), lineWidth: 4)
                    }
                    if r < model.maze.southOpen.count, !model.maze.southOpen[r][c] {
                        var wall = Path()
                        let y = origin.y + cell
                        wall.move(to: CGPoint(x: origin.x, y: y))
                        wall.addLine(to: CGPoint(x: origin.x + cell, y: y))
                        context.stroke(wall, with: .color(Color.appTextSecondary), lineWidth: 4)
                    }

                    if model.hazardBlocks(row: r, col: c) {
                        let pulse = 0.35 + 0.25 * sin(Double(model.gatePulse) * 6 + Double(r + c))
                        let rect = CGRect(x: origin.x + 4, y: origin.y + 4, width: cell - 8, height: cell - 8)
                        context.fill(Path(ellipseIn: rect), with: .color(Color.appAccent.opacity(pulse)))
                    }
                }
            }

            let goal = CGPoint(x: CGFloat(cols - 1) * cell + cell / 2, y: CGFloat(rows - 1) * cell + cell / 2)
            var exitRing = Path()
            exitRing.addEllipse(in: CGRect(x: goal.x - 14, y: goal.y - 14, width: 28, height: 28))
            context.stroke(exitRing, with: .color(Color.appPrimary.opacity(0.95)), lineWidth: 4)

            let p = model.player
            let center = CGPoint(x: CGFloat(p.1) * cell + cell / 2, y: CGFloat(p.0) * cell + cell / 2)
            var glow = Path()
            glow.addEllipse(in: CGRect(x: center.x - 16, y: center.y - 16, width: 32, height: 32))
            context.fill(glow, with: .color(Color.appAccent.opacity(0.35)))
            var shape = Path()
            shape.addEllipse(in: CGRect(x: center.x - 12, y: center.y - 12, width: 24, height: 24))
            context.fill(shape, with: .color(Color.appPrimary))
        }
    }

    private func navGesture() -> some Gesture {
        DragGesture(minimumDistance: 18)
            .onChanged { value in
                if dragStart == nil {
                    dragStart = value.startLocation
                }
            }
            .onEnded { value in
                let start = dragStart ?? value.startLocation
                dragStart = nil
                let dx = value.location.x - start.x
                let dy = value.location.y - start.y
                if abs(dx) > abs(dy) {
                    if dx > 12 {
                        model.attemptMove(delta: (0, 1))
                    } else if dx < -12 {
                        model.attemptMove(delta: (0, -1))
                    }
                } else {
                    if dy > 12 {
                        model.attemptMove(delta: (1, 0))
                    } else if dy < -12 {
                        model.attemptMove(delta: (-1, 0))
                    }
                }
            }
    }

    private func exitSession() {
        model.stop()
        let result = GameSessionResult(
            game: .shapeEscape,
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
            game: .shapeEscape,
            level: level,
            difficulty: difficulty,
            starsEarned: model.starAward(),
            elapsedSeconds: model.elapsed,
            accuracy01: model.accuracy(),
            isWin: model.phase == .won
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            onFinish(result)
        }
    }
}
