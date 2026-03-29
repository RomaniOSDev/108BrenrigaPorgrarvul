import Foundation

struct MazeLayout: Hashable {
    let rows: Int
    let cols: Int
    var eastOpen: [[Bool]]
    var southOpen: [[Bool]]

    func canMove(from rc: (Int, Int), delta: (Int, Int)) -> Bool {
        let (r, c) = rc
        let (dr, dc) = delta
        if dr == 0, dc == 1 {
            guard c + 1 < cols, c < eastOpen[r].count else { return false }
            return eastOpen[r][c]
        }
        if dr == 0, dc == -1 {
            guard c > 0, c - 1 < eastOpen[r].count else { return false }
            return eastOpen[r][c - 1]
        }
        if dr == 1, dc == 0 {
            guard r + 1 < rows, r < southOpen.count else { return false }
            return southOpen[r][c]
        }
        if dr == -1, dc == 0 {
            guard r > 0, r - 1 < southOpen.count else { return false }
            return southOpen[r - 1][c]
        }
        return false
    }

    static func generate(rows: Int, cols: Int) -> MazeLayout {
        let safeRows = max(2, rows)
        let safeCols = max(2, cols)
        let eastCols = max(0, safeCols - 1)
        let southRows = max(0, safeRows - 1)

        var eastOpen = Array(repeating: Array(repeating: false, count: eastCols), count: safeRows)
        var southOpen = Array(repeating: Array(repeating: false, count: safeCols), count: southRows)

        var visited = Array(repeating: Array(repeating: false, count: safeCols), count: safeRows)

        func carve(_ r: Int, _ c: Int) {
            visited[r][c] = true
            var options: [(Int, Int)] = []
            if c + 1 < safeCols { options.append((r, c + 1)) }
            if c > 0 { options.append((r, c - 1)) }
            if r + 1 < safeRows { options.append((r + 1, c)) }
            if r > 0 { options.append((r - 1, c)) }

            for (nr, nc) in options.shuffled() {
                if visited[nr][nc] {
                    continue
                }
                if nr == r, nc == c + 1 {
                    eastOpen[r][c] = true
                } else if nr == r, nc == c - 1 {
                    eastOpen[r][c - 1] = true
                } else if nr == r + 1, nc == c {
                    southOpen[r][c] = true
                } else if nr == r - 1, nc == c {
                    southOpen[r - 1][c] = true
                }
                carve(nr, nc)
            }
        }

        carve(0, 0)
        return MazeLayout(rows: safeRows, cols: safeCols, eastOpen: eastOpen, southOpen: southOpen)
    }
}
