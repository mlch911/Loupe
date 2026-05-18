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

public struct LoupeRuntimeIdentity: Codable, Equatable {
    public var launchID: String
    public var startedAt: Date
    public var bundleIdentifier: String?
    public var processIdentifier: Int32
    public var simulatorUDID: String?
    public var simulatorName: String?

    public init(
        launchID: String = UUID().uuidString,
        startedAt: Date = Date(),
        bundleIdentifier: String? = nil,
        processIdentifier: Int32,
        simulatorUDID: String? = nil,
        simulatorName: String? = nil
    ) {
        self.launchID = launchID
        self.startedAt = startedAt
        self.bundleIdentifier = bundleIdentifier
        self.processIdentifier = processIdentifier
        self.simulatorUDID = simulatorUDID
        self.simulatorName = simulatorName
    }
}

public struct LoupeRecording: Codable, Equatable {
    public var id: String
    public var startedAt: Date
    public var endedAt: Date?
    public var appIdentity: LoupeRuntimeIdentity?
    public var events: [LoupeRuntimeEvent]

    public init(
        id: String = UUID().uuidString,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        appIdentity: LoupeRuntimeIdentity? = nil,
        events: [LoupeRuntimeEvent] = []
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.appIdentity = appIdentity
        self.events = events
    }
}

public struct LoupeRuntimeState: Codable, Equatable {
    public var identity: LoupeRuntimeIdentity
    public var recording: LoupeRecording?
    public var logs: [LoupeRuntimeLog]

    public init(
        identity: LoupeRuntimeIdentity,
        recording: LoupeRecording? = nil,
        logs: [LoupeRuntimeLog] = []
    ) {
        self.identity = identity
        self.recording = recording
        self.logs = logs
    }
}
