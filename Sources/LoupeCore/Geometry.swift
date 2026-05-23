import Foundation

public struct LoupePoint: Codable, Equatable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sanitizeGeometryDouble(x), forKey: .x)
        try container.encode(sanitizeGeometryDouble(y), forKey: .y)
    }
}

public struct LoupeSize: Codable, Equatable {
    public var width: Double
    public var height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sanitizeGeometryDouble(width), forKey: .width)
        try container.encode(sanitizeGeometryDouble(height), forKey: .height)
    }
}

public struct LoupeRect: Codable, Equatable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var maxX: Double { x + width }
    public var maxY: Double { y + height }
    public var isEmpty: Bool { width <= 0 || height <= 0 }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sanitizeGeometryDouble(x), forKey: .x)
        try container.encode(sanitizeGeometryDouble(y), forKey: .y)
        try container.encode(sanitizeGeometryDouble(width), forKey: .width)
        try container.encode(sanitizeGeometryDouble(height), forKey: .height)
    }

    public func intersects(_ other: LoupeRect) -> Bool {
        guard !isEmpty, !other.isEmpty else { return false }
        return x < other.maxX && maxX > other.x && y < other.maxY && maxY > other.y
    }

    public func contains(_ other: LoupeRect, tolerance: Double = 0) -> Bool {
        guard !isEmpty, !other.isEmpty else { return false }
        return other.x >= x - tolerance
            && other.y >= y - tolerance
            && other.maxX <= maxX + tolerance
            && other.maxY <= maxY + tolerance
    }

    public func intersectionArea(with other: LoupeRect) -> Double {
        guard intersects(other) else { return 0 }
        let width = min(maxX, other.maxX) - max(x, other.x)
        let height = min(maxY, other.maxY) - max(y, other.y)
        return max(0, width) * max(0, height)
    }
}

public struct LoupeInsets: Codable, Equatable {
    public var top: Double
    public var left: Double
    public var bottom: Double
    public var right: Double

    public init(top: Double, left: Double, bottom: Double, right: Double) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sanitizeGeometryDouble(top), forKey: .top)
        try container.encode(sanitizeGeometryDouble(left), forKey: .left)
        try container.encode(sanitizeGeometryDouble(bottom), forKey: .bottom)
        try container.encode(sanitizeGeometryDouble(right), forKey: .right)
    }
}

public struct LoupeColor: Codable, Equatable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

private func sanitizeGeometryDouble(_ value: Double) -> Double {
    guard value.isFinite, abs(value) <= 1_000_000 else {
        return 0
    }
    return (value * 100).rounded() / 100
}
