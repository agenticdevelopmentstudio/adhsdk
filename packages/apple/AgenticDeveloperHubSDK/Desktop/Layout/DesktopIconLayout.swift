import CoreGraphics
import Foundation

public enum DesktopIconArrangement: String, Codable, Sendable, CaseIterable {
    case largeIcons, smallIcons, list
}

/// Pure icon placement math. Coordinates are top-left origin.
public struct DesktopIconLayout: Sendable {
    public struct Metrics: Sendable {
        public var iconSize: CGFloat
        public var cellSize: CGSize
        public var padding: CGFloat

        public init(iconSize: CGFloat, cellSize: CGSize, padding: CGFloat) {
            self.iconSize = iconSize
            self.cellSize = cellSize
            self.padding = padding
        }

        public static let large = Metrics(iconSize: 64, cellSize: CGSize(width: 96, height: 96), padding: 8)
        public static let small = Metrics(iconSize: 32, cellSize: CGSize(width: 80, height: 64), padding: 8)
    }

    public let metrics: Metrics
    public let containerSize: CGSize

    public init(metrics: Metrics, containerSize: CGSize) {
        self.metrics = metrics
        self.containerSize = containerSize
    }

    private var rowsPerColumn: Int {
        max(1, Int(((containerSize.height - metrics.padding) / metrics.cellSize.height).rounded(.down)))
    }

    private func origin(column: Int, row: Int) -> CGPoint {
        CGPoint(
            x: metrics.padding + CGFloat(column) * metrics.cellSize.width,
            y: metrics.padding + CGFloat(row) * metrics.cellSize.height
        )
    }

    private func cellIndex(containing origin: CGPoint) -> (column: Int, row: Int) {
        (
            Int(((origin.x - metrics.padding) / metrics.cellSize.width).rounded(.down)),
            Int(((origin.y - metrics.padding) / metrics.cellSize.height).rounded(.down))
        )
    }

    /// Grid from the top-left, filling down then across, in the given order.
    public func arrangedOrigins(for ids: [String]) -> [String: CGPoint] {
        let rows = rowsPerColumn
        var result: [String: CGPoint] = [:]
        for (index, id) in ids.enumerated() {
            result[id] = origin(column: index / rows, row: index % rows)
        }
        return result
    }

    /// Saved origins (clamped) where present, next free grid cell otherwise.
    /// Saved origins for ids not in `ids` are ignored.
    public func freeOrigins(for ids: [String], saved: [String: CGPoint]) -> [String: CGPoint] {
        var result: [String: CGPoint] = [:]
        var taken = Set<GridCell>()
        for id in ids {
            guard let savedOrigin = saved[id] else { continue }
            let clamped = clamp(savedOrigin)
            result[id] = clamped
            let cell = cellIndex(containing: clamped)
            taken.insert(GridCell(column: cell.column, row: cell.row))
        }
        let rows = rowsPerColumn
        var next = 0
        for id in ids where result[id] == nil {
            var cell = GridCell(column: next / rows, row: next % rows)
            while taken.contains(cell) {
                next += 1
                cell = GridCell(column: next / rows, row: next % rows)
            }
            next += 1
            taken.insert(cell)
            result[id] = origin(column: cell.column, row: cell.row)
        }
        return result
    }

    /// Keeps the whole cell inside the container.
    public func clamp(_ origin: CGPoint) -> CGPoint {
        let maxX = max(0, containerSize.width - metrics.cellSize.width)
        let maxY = max(0, containerSize.height - metrics.cellSize.height)
        return CGPoint(x: min(max(origin.x, 0), maxX), y: min(max(origin.y, 0), maxY))
    }

    private struct GridCell: Hashable {
        let column: Int
        let row: Int
    }
}
