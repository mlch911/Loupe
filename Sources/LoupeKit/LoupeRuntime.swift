import Foundation
import LoupeCore

#if canImport(UIKit)
import UIKit

@MainActor
public final class LoupeRuntime {
    public static let shared = LoupeRuntime()

    public let identity: LoupeRuntimeIdentity
    private var logs: [LoupeRuntimeLog] = []
    private var metadataByTestID: [String: [String: LoupeMetadataValue]] = [:]
    private var didInstallBridge = false

    private init() {
        let environment = ProcessInfo.processInfo.environment
        identity = LoupeRuntimeIdentity(
            bundleIdentifier: Bundle.main.bundleIdentifier,
            processIdentifier: ProcessInfo.processInfo.processIdentifier,
            simulatorUDID: environment["SIMULATOR_UDID"],
            simulatorName: environment["SIMULATOR_DEVICE_NAME"]
        )
    }

    public func activateBridge() {
        installBridgeIfNeeded()
    }

    public func runtimeState() -> LoupeRuntimeState {
        LoupeRuntimeState(identity: identity, logs: logs)
    }

    public func runtimeLogs() -> [LoupeRuntimeLog] {
        logs
    }

    func metadata(forTestID testID: String?) -> [String: LoupeMetadataValue] {
        guard let testID = nonEmpty(testID) else {
            return [:]
        }
        return metadataByTestID[testID] ?? [:]
    }

    public func log(
        level: String = "info",
        _ message: String,
        metadata: [String: LoupeMetadataValue] = [:]
    ) {
        logs.append(
            LoupeRuntimeLog(
                level: level,
                message: message,
                metadata: metadata
            )
        )

        if logs.count > 500 {
            logs.removeFirst(logs.count - 500)
        }
    }

    private func installBridgeIfNeeded() {
        guard !didInstallBridge else {
            return
        }

        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(receiveLogNotification(_:)),
            name: .loupeLog,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(receiveViewMetadataNotification(_:)),
            name: .loupeViewMetadata,
            object: nil
        )
        didInstallBridge = true
    }

    @objc private nonisolated func receiveLogNotification(_ notification: Notification) {
        guard let payload = LoupeLogNotificationPayload(notification: notification) else {
            return
        }

        if Thread.isMainThread {
            MainActor.assumeIsolated {
                self.receiveLogPayload(payload)
            }
        } else {
            DispatchQueue.main.async { [weak self, payload] in
                MainActor.assumeIsolated {
                    self?.receiveLogPayload(payload)
                }
            }
        }
    }

    @MainActor
    private func receiveLogPayload(_ payload: LoupeLogNotificationPayload) {
        log(
            level: payload.level,
            payload.message,
            metadata: payload.metadata
        )
    }

    @objc private nonisolated func receiveViewMetadataNotification(_ notification: Notification) {
        guard let payload = LoupeViewMetadataNotificationPayload(notification: notification) else {
            return
        }

        if Thread.isMainThread {
            MainActor.assumeIsolated {
                self.receiveViewMetadataPayload(payload)
            }
        } else {
            DispatchQueue.main.async { [weak self, payload] in
                MainActor.assumeIsolated {
                    self?.receiveViewMetadataPayload(payload)
                }
            }
        }
    }

    @MainActor
    private func receiveViewMetadataPayload(_ payload: LoupeViewMetadataNotificationPayload) {
        if let view = payload.view {
            view.loupeMetadata.merge(payload.metadata) { _, new in new }
        }

        if let testID = payload.testID {
            var existing = metadataByTestID[testID] ?? [:]
            existing.merge(payload.metadata) { _, new in new }
            metadataByTestID[testID] = existing
        }
    }

}

public enum Loupe {
    @MainActor
    public static func log(
        _ message: String,
        level: String = "info",
        metadata: [String: LoupeMetadataValue] = [:]
    ) {
        LoupeRuntime.shared.log(level: level, message, metadata: metadata)
    }
}

private func nonEmpty(_ value: String?) -> String? {
    guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
        return nil
    }
    return trimmed
}

private func metadataPayload(from userInfo: [AnyHashable: Any]) -> [String: LoupeMetadataValue] {
    if let metadata = userInfo["metadata"] as? [String: Any] {
        return metadata.compactMapValues(loupeMetadataValue)
    }

    var payload: [String: LoupeMetadataValue] = [:]
    let reservedKeys: Set<String> = ["level", "message", "metadata", "view", "testID", "id"]
    for (rawKey, rawValue) in userInfo {
        guard let key = rawKey as? String, !reservedKeys.contains(key), let value = loupeMetadataValue(from: rawValue) else {
            continue
        }
        payload[key] = value
    }
    return payload
}

private func loupeMetadataValue(from value: Any) -> LoupeMetadataValue? {
    switch value {
    case let value as String:
        return .string(value)
    case let value as Bool:
        return .bool(value)
    case let value as Int:
        return .int(value)
    case let value as Double:
        return .double(value)
    case let value as Float:
        return .double(Double(value))
    case let value as NSNumber:
        if CFGetTypeID(value) == CFBooleanGetTypeID() {
            return .bool(value.boolValue)
        }
        let doubleValue = value.doubleValue
        if doubleValue.rounded() == doubleValue {
            return .int(value.intValue)
        }
        return .double(doubleValue)
    default:
        return nil
    }
}

private struct LoupeLogNotificationPayload: Sendable {
    var level: String
    var message: String
    var metadata: [String: LoupeMetadataValue]

    init?(notification: Notification) {
        let userInfo = notification.userInfo ?? [:]
        guard let message = nonEmpty(userInfo["message"] as? String) else {
            return nil
        }

        self.level = nonEmpty(userInfo["level"] as? String) ?? "info"
        self.message = message
        self.metadata = metadataPayload(from: userInfo)
    }
}

private struct LoupeViewMetadataNotificationPayload: @unchecked Sendable {
    var view: UIView?
    var testID: String?
    var metadata: [String: LoupeMetadataValue]

    init?(notification: Notification) {
        let userInfo = notification.userInfo ?? [:]
        let metadata = metadataPayload(from: userInfo)
        guard !metadata.isEmpty else {
            return nil
        }

        self.view = (notification.object as? UIView) ?? (userInfo["view"] as? UIView)
        self.testID = nonEmpty(userInfo["testID"] as? String ?? userInfo["id"] as? String)
        self.metadata = metadata
    }
}

public extension Notification.Name {
    static let loupeLog = Notification.Name("dev.loupe.log")
    static let loupeViewMetadata = Notification.Name("dev.loupe.viewMetadata")
}

#endif
