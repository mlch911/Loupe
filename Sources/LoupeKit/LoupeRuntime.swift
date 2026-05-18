import Foundation
import LoupeCore

#if canImport(UIKit)
import ObjectiveC
import UIKit

@MainActor
public final class LoupeRuntime {
    public static let shared = LoupeRuntime()

    public let identity: LoupeRuntimeIdentity
    private var recording: LoupeRecording?
    private var completedRecording: LoupeRecording?
    private var logs: [LoupeRuntimeLog] = []
    private var metadataByTestID: [String: [String: LoupeMetadataValue]] = [:]
    private var overlayWindow: UIWindow?
    private var didInstallEventHook = false
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

    public func startRecording(alias: String? = nil, showControls: Bool = true) -> LoupeRecording {
        installEventHookIfNeeded()
        let recording = LoupeRecording(alias: nonEmpty(alias), appIdentity: identity)
        self.recording = recording
        completedRecording = nil
        var metadata: [String: LoupeMetadataValue] = ["id": .string(recording.id)]
        if let alias = recording.alias {
            metadata["alias"] = .string(alias)
        }
        log(level: "info", "recording_started", metadata: metadata)

        if showControls {
            showRecordingControls()
        }

        return recording
    }

    public func stopRecording() -> LoupeRecording? {
        guard var recording else {
            hideRecordingControls()
            return completedRecording
        }

        recording.endedAt = Date()
        self.recording = nil
        completedRecording = recording
        hideRecordingControls()
        log(level: "info", "recording_stopped", metadata: ["id": .string(recording.id)])
        return recording
    }

    public func runtimeState() -> LoupeRuntimeState {
        LoupeRuntimeState(identity: identity, recording: recording ?? completedRecording, logs: logs)
    }

    public func currentRecording() -> LoupeRecording? {
        recording ?? completedRecording
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

    fileprivate func capture(_ event: UIEvent) {
        guard recording != nil, event.type == .touches else {
            return
        }

        let touches = event.allTouches ?? []
        let points = touches.compactMap { touch -> LoupePoint? in
            guard let window = touch.window else {
                return nil
            }
            guard window !== overlayWindow else {
                return nil
            }
            let point = window.convert(touch.location(in: window), to: nil)
            return LoupePoint(x: Double(point.x), y: Double(point.y))
        }

        guard !points.isEmpty else {
            return
        }

        appendRuntimeEvent(
            LoupeRuntimeEvent(
                kind: .touch,
                phase: touches.first.map(touchPhase),
                points: points,
                targetCandidates: recordedTargetCandidates(for: points.first, phase: touches.first.map(touchPhase))
            )
        )
    }

    private func recordedTargetCandidates(
        for point: LoupePoint?,
        phase: LoupeTouchPhase?
    ) -> [LoupeRecordedTargetCandidate] {
        guard phase == .began, let point else {
            return []
        }

        let agent = LoupeAgent()
        let snapshot = agent.captureSnapshot()
        let accessibilityTree = agent.captureAccessibilityTree()
        var candidates: [LoupeRecordedTargetCandidate] = []

        candidates.append(contentsOf: accessibilityCandidates(at: point, in: accessibilityTree))
        candidates.append(contentsOf: viewCandidates(at: point, in: snapshot))

        var seen = Set<String>()
        return candidates
            .sorted { lhs, rhs in
                if lhs.score != rhs.score {
                    return lhs.score > rhs.score
                }
                return area(lhs.frame) < area(rhs.frame)
            }
            .filter { candidate in
                let key = "\(candidate.tree):\(candidate.selector.kind.rawValue):\(candidate.selector.role ?? ""):\(candidate.selector.value)"
                guard !seen.contains(key) else {
                    return false
                }
                seen.insert(key)
                return true
            }
            .prefix(5)
            .map { $0 }
    }

    private func accessibilityCandidates(
        at point: LoupePoint,
        in tree: LoupeAccessibilityTree
    ) -> [LoupeRecordedTargetCandidate] {
        tree.nodes.values.compactMap { node in
            guard node.isVisible,
                  contains(point, in: node.frame),
                  let selector = recordedSelector(
                testID: node.testID,
                role: node.role,
                text: LoupeAccessibilityTreeQuery.displayText(for: node),
                ref: node.ref
            ),
                  !shouldSkipRecordedCandidate(
                    frame: node.frame,
                    screen: tree.screen.size,
                    role: node.role,
                    selector: selector
                  ) else {
                return nil
            }

            return LoupeRecordedTargetCandidate(
                tree: "accessibility",
                selector: selector,
                ref: node.ref,
                sourceRef: node.sourceRef,
                role: node.role,
                testID: node.testID,
                text: LoupeAccessibilityTreeQuery.displayText(for: node),
                frame: node.frame,
                activationPoint: node.activationPoint,
                score: recordedSelectorScore(selector, role: node.role, isInteractive: node.isInteractive)
            )
        }
    }

    private func viewCandidates(at point: LoupePoint, in snapshot: LoupeSnapshot) -> [LoupeRecordedTargetCandidate] {
        let swiftUIRefs = swiftUISubtreeRefs(in: snapshot)
        return snapshot.nodes.values.compactMap { node in
            guard !swiftUIRefs.contains(node.ref),
                  node.isVisible,
                  contains(point, in: node.frame),
                  let selector = recordedSelector(
                testID: node.testID,
                role: node.role,
                text: LoupeObservationCompactor.displayText(for: node),
                ref: node.ref
            ),
                  !shouldSkipRecordedCandidate(
                    frame: node.frame,
                    screen: snapshot.screen.size,
                    role: node.role,
                    selector: selector
                  ) else {
                return nil
            }

            return LoupeRecordedTargetCandidate(
                tree: "view",
                selector: selector,
                ref: node.ref,
                role: node.role,
                testID: node.testID,
                text: LoupeObservationCompactor.displayText(for: node),
                frame: node.frame,
                score: recordedSelectorScore(selector, role: node.role, isInteractive: node.isInteractive)
            )
        }
    }

    private func appendRuntimeEvent(_ event: LoupeRuntimeEvent) {
        guard var recording else {
            return
        }

        recording.events.append(event)
        self.recording = recording
    }

    private func installEventHookIfNeeded() {
        guard !didInstallEventHook else {
            return
        }

        UIApplication.installLoupeSendEventHook()
        didInstallEventHook = true
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

    @objc private func receiveLogNotification(_ notification: Notification) {
        let userInfo = notification.userInfo ?? [:]
        guard let message = nonEmpty(userInfo["message"] as? String) else {
            return
        }

        log(
            level: nonEmpty(userInfo["level"] as? String) ?? "info",
            message,
            metadata: metadataPayload(from: userInfo)
        )
    }

    @objc private func receiveViewMetadataNotification(_ notification: Notification) {
        let userInfo = notification.userInfo ?? [:]
        let metadata = metadataPayload(from: userInfo)
        guard !metadata.isEmpty else {
            return
        }

        if let view = (notification.object as? UIView) ?? (userInfo["view"] as? UIView) {
            view.loupeMetadata.merge(metadata) { _, new in new }
        }

        if let testID = nonEmpty(userInfo["testID"] as? String ?? userInfo["id"] as? String) {
            var existing = metadataByTestID[testID] ?? [:]
            existing.merge(metadata) { _, new in new }
            metadataByTestID[testID] = existing
        }
    }

    private func showRecordingControls() {
        guard overlayWindow == nil else {
            return
        }

        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else {
            return
        }

        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 16, y: 48, width: 104, height: 44)
        window.windowLevel = .alert + 100
        window.backgroundColor = .clear
        window.rootViewController = LoupeRecordingControlsViewController()
        window.isHidden = false
        overlayWindow = window
    }

    private func hideRecordingControls() {
        overlayWindow?.isHidden = true
        overlayWindow = nil
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

private final class LoupeRecordingControlsViewController: UIViewController {
    override func loadView() {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.systemRed.withAlphaComponent(0.92)
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.titleLabel?.font = .boldSystemFont(ofSize: 13)
        button.setTitle("Stop", for: .normal)
        button.accessibilityIdentifier = "loupe.recording.stop"
        button.addTarget(self, action: #selector(stopRecording), for: .touchUpInside)
        view = button
    }

    @objc private func stopRecording() {
        LoupeRuntime.shared.stopRecording()
    }
}

private func touchPhase(_ touch: UITouch) -> LoupeTouchPhase {
    switch touch.phase {
    case .began:
        return .began
    case .moved, .stationary:
        return .moved
    case .ended:
        return .ended
    case .cancelled, .regionEntered, .regionMoved, .regionExited:
        return .cancelled
    @unknown default:
        return .cancelled
    }
}

private func recordedSelector(
    testID: String?,
    role: String?,
    text: String?,
    ref: String
) -> LoupeRecordedSelector? {
    if let testID = nonEmpty(testID) {
        return LoupeRecordedSelector(kind: .testID, value: testID)
    }
    if let role = nonEmpty(role), let text = nonEmpty(text) {
        return LoupeRecordedSelector(kind: .roleAndText, value: text, role: role, exact: true)
    }
    if let text = nonEmpty(text) {
        return LoupeRecordedSelector(kind: .text, value: text, exact: true)
    }
    return LoupeRecordedSelector(kind: .ref, value: ref)
}

private func recordedSelectorScore(_ selector: LoupeRecordedSelector, role: String?, isInteractive: Bool) -> Int {
    let base: Int
    switch selector.kind {
    case .testID:
        base = 100
    case .roleAndText:
        base = 70
    case .text:
        base = 50
    case .ref:
        base = 10
    }
    let interactiveBonus = isInteractive ? 5 : 0
    let containerPenalty = ["tableView", "collectionView", "scrollView", "tabBar"].contains(role ?? "") ? 20 : 0
    return base + interactiveBonus - containerPenalty
}

private func contains(_ point: LoupePoint, in rect: LoupeRect?) -> Bool {
    guard let rect, !rect.isEmpty else {
        return false
    }
    return point.x >= rect.x && point.x <= rect.maxX && point.y >= rect.y && point.y <= rect.maxY
}

private func area(_ rect: LoupeRect?) -> Double {
    guard let rect else {
        return Double.greatestFiniteMagnitude
    }
    return max(0, rect.width) * max(0, rect.height)
}

private func shouldSkipRecordedCandidate(
    frame: LoupeRect?,
    screen: LoupeSize,
    role: String?,
    selector: LoupeRecordedSelector
) -> Bool {
    guard let frame else {
        return false
    }
    let screenArea = max(1, screen.width * screen.height)
    guard area(frame) / screenArea > 0.45 else {
        return false
    }

    if selector.kind == .ref {
        return true
    }

    guard let role else {
        return true
    }

    return [
        "application",
        "scene",
        "window",
        "tableView",
        "collectionView",
        "scrollView",
        "tabBar",
        "toolbar",
        "navigationBar"
    ].contains(role)
}

private func swiftUISubtreeRefs(in snapshot: LoupeSnapshot) -> Set<String> {
    var refs = Set<String>()

    func visit(_ ref: String, inheritedSwiftUI: Bool) {
        guard let node = snapshot.nodes[ref] else {
            return
        }

        let isSwiftUI = inheritedSwiftUI || isSwiftUIBackedNode(node)
        if isSwiftUI {
            refs.insert(ref)
        }

        node.children.forEach { visit($0, inheritedSwiftUI: isSwiftUI) }
    }

    snapshot.rootRefs.forEach { visit($0, inheritedSwiftUI: false) }
    return refs
}

private func isSwiftUIBackedNode(_ node: LoupeNode) -> Bool {
    node.runtime?.frameworkBundleIdentifier == "com.apple.SwiftUI"
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

public extension Notification.Name {
    static let loupeLog = Notification.Name("dev.loupe.log")
    static let loupeViewMetadata = Notification.Name("dev.loupe.viewMetadata")
}

private extension UIApplication {
    static func installLoupeSendEventHook() {
        guard
            let original = class_getInstanceMethod(UIApplication.self, #selector(sendEvent(_:))),
            let replacement = class_getInstanceMethod(UIApplication.self, #selector(loupe_sendEvent(_:)))
        else {
            return
        }

        method_exchangeImplementations(original, replacement)
    }

    @objc func loupe_sendEvent(_ event: UIEvent) {
        LoupeRuntime.shared.capture(event)
        loupe_sendEvent(event)
    }
}

#endif
