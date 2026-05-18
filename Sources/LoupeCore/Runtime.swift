import Foundation

public enum LoupeRuntimeEventKind: String, Codable, Equatable {
    case touch
    case wait
    case log
}

public enum LoupeTouchPhase: String, Codable, Equatable {
    case began
    case moved
    case ended
    case cancelled
}

public struct LoupeRuntimeEvent: Codable, Equatable {
    public var id: String
    public var kind: LoupeRuntimeEventKind
    public var timestamp: Date
    public var phase: LoupeTouchPhase?
    public var points: [LoupePoint]
    public var message: String?

    public init(
        id: String = UUID().uuidString,
        kind: LoupeRuntimeEventKind,
        timestamp: Date = Date(),
        phase: LoupeTouchPhase? = nil,
        points: [LoupePoint] = [],
        message: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.timestamp = timestamp
        self.phase = phase
        self.points = points
        self.message = message
    }
}

public struct LoupeRuntimeLog: Codable, Equatable {
    public var id: String
    public var timestamp: Date
    public var level: String
    public var message: String
    public var metadata: [String: LoupeMetadataValue]

    public init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        level: String,
        message: String,
        metadata: [String: LoupeMetadataValue] = [:]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.message = message
        self.metadata = metadata
    }
}

public struct LoupeRecording: Codable, Equatable {
    public var id: String
    public var startedAt: Date
    public var endedAt: Date?
    public var events: [LoupeRuntimeEvent]

    public init(
        id: String = UUID().uuidString,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        events: [LoupeRuntimeEvent] = []
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.events = events
    }
}

public struct LoupeRuntimeState: Codable, Equatable {
    public var recording: LoupeRecording?
    public var logs: [LoupeRuntimeLog]

    public init(recording: LoupeRecording? = nil, logs: [LoupeRuntimeLog] = []) {
        self.recording = recording
        self.logs = logs
    }
}
