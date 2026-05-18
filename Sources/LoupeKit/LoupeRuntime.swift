import Foundation
import LoupeCore

#if canImport(UIKit)
import ObjectiveC
import UIKit

@MainActor
public final class LoupeRuntime {
    public static let shared = LoupeRuntime()

    private var recording: LoupeRecording?
    private var completedRecording: LoupeRecording?
    private var logs: [LoupeRuntimeLog] = []
    private var overlayWindow: UIWindow?
    private var didInstallEventHook = false

    private init() {}

    public func startRecording(showControls: Bool = true) -> LoupeRecording {
        installEventHookIfNeeded()
        let recording = LoupeRecording()
        self.recording = recording
        completedRecording = nil
        log(level: "info", "recording_started", metadata: ["id": .string(recording.id)])

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
        LoupeRuntimeState(recording: recording ?? completedRecording, logs: logs)
    }

    public func currentRecording() -> LoupeRecording? {
        recording ?? completedRecording
    }

    public func runtimeLogs() -> [LoupeRuntimeLog] {
        logs
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
                points: points
            )
        )
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
