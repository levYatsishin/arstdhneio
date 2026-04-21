import Foundation

public struct GridPoint: Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public struct GridRect: Equatable, Sendable {
    public var origin: GridPoint
    public var size: GridPoint

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.origin = GridPoint(x: x, y: y)
        self.size = GridPoint(x: width, y: height)
    }

    public static var defaultScreen: GridRect {
        GridRect(x: 0, y: 0, width: 1920, height: 1080)
    }

    public var minX: Double { origin.x }
    public var minY: Double { origin.y }
    public var width: Double { size.x }
    public var height: Double { size.y }
    public var midX: Double { origin.x + size.x / 2 }
    public var midY: Double { origin.y + size.y / 2 }
    public var center: GridPoint { GridPoint(x: midX, y: midY) }

    public func subdividing(rows: Int, columns: Int, row: Int, column: Int) -> GridRect? {
        guard rows > 0, columns > 0, row >= 0, column >= 0, row < rows, column < columns else {
            return nil
        }

        let tileWidth = width / Double(columns)
        let tileHeight = height / Double(rows)
        let x = minX + Double(column) * tileWidth
        let y = minY + Double(row) * tileHeight

        return GridRect(x: x, y: y, width: tileWidth, height: tileHeight)
    }
}

public struct GridCoordinate: Hashable, Equatable {
    public let row: Int
    public let column: Int
}

public enum GridLayoutPreset: String, CaseIterable, Sendable {
    case qwerty
    case colemak
    case colemak5

    public var rowStrings: [String] {
        switch self {
        case .qwerty:
            return [
                "1234567890",
                "qwertyuiop",
                "asdfghjkl;",
                "zxcvbnm,./"
            ]
        case .colemak:
            return [
                "1234567890",
                "qwfpgjluy;",
                "arstdhneio",
                "zxcvbkm,./"
            ]
        case .colemak5:
            return [
                "neiuy",
                "qwfpg",
                "arstd",
                "zxcvb"
            ]
        }
    }
}

public struct GridLayout {
    public let rows: Int
    public let columns: Int
    public let keymap: [Character: GridCoordinate]
    private let coordinateToKey: [GridCoordinate: Character]

    public init(rows: Int = 4, columns: Int = 10, keymap: [Character: GridCoordinate] = GridLayout.defaultKeymap) {
        self.rows = rows
        self.columns = columns
        self.keymap = keymap
        self.coordinateToKey = GridLayout.inverseKeymap(keymap)
    }

    public init?(rowStrings: [String]) {
        guard let columns = GridLayout.validate(rowStrings: rowStrings) else { return nil }
        self.init(rows: rowStrings.count, columns: columns, keymap: GridLayout.keymap(from: rowStrings))
    }

    public init(preset: GridLayoutPreset) {
        self.init(rowStrings: preset.rowStrings)!
    }

    public func coordinate(for key: Character) -> GridCoordinate? {
        keymap[Character(key.lowercased())]
    }

    public func rect(for key: Character, in rect: GridRect) -> GridRect? {
        guard let coordinate = coordinate(for: key) else { return nil }
        return rect.subdividing(rows: rows, columns: columns, row: coordinate.row, column: coordinate.column)
    }

    public func label(forRow row: Int, column: Int) -> Character? {
        guard row >= 0, column >= 0, row < rows, column < columns else { return nil }
        return coordinateToKey[GridCoordinate(row: row, column: column)]
    }

    public static var defaultKeymap: [Character: GridCoordinate] {
        keymap(from: GridLayoutPreset.qwerty.rowStrings)
    }

    private static func validate(rowStrings: [String]) -> Int? {
        guard let firstRow = rowStrings.first else { return nil }
        let columns = firstRow.count
        guard columns > 0 else { return nil }
        guard rowStrings.allSatisfy({ $0.count == columns }) else { return nil }

        let normalized = rowStrings.flatMap { $0.lowercased() }
        guard Set(normalized).count == normalized.count else { return nil }
        return columns
    }

    private static func keymap(from rowStrings: [String]) -> [Character: GridCoordinate] {
        var mapping: [Character: GridCoordinate] = [:]
        for (rowIndex, rowString) in rowStrings.enumerated() {
            for (columnIndex, char) in rowString.lowercased().enumerated() {
                mapping[char] = GridCoordinate(row: rowIndex, column: columnIndex)
            }
        }
        return mapping
    }

    private static func inverseKeymap(_ keymap: [Character: GridCoordinate]) -> [GridCoordinate: Character] {
        var mapping: [GridCoordinate: Character] = [:]
        for (key, coordinate) in keymap {
            if mapping[coordinate] == nil {
                mapping[coordinate] = key
            }
        }
        return mapping
    }
}
