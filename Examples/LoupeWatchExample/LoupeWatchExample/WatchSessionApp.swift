import Foundation
import SwiftUI

@main
struct LoupeWatchExampleApp: App {
    @StateObject private var model = WatchSessionModel()

    var body: some Scene {
        WindowGroup {
            WatchSessionDashboard(model: model)
        }
    }
}

@MainActor
private final class WatchSessionModel: ObservableObject {
    @Published var elapsedMinutes = 18
    @Published var heartRate = 142
    @Published var hydrationDue = true
    @Published var currentInterval = 3
    @Published var activeFocus = "Tempo"

    private let store = WatchSessionStore()
    private var didPublishLaunchEvidence = false

    func publishLaunchEvidenceIfNeeded() {
        guard !didPublishLaunchEvidence else {
            return
        }
        didPublishLaunchEvidence = true

        UserDefaults.standard.set(true, forKey: "watch-session-active")
        UserDefaults.standard.set(activeFocus, forKey: "watch-session-focus")
        UserDefaults.standard.set(currentInterval, forKey: "watch-session-interval")

        loupeLog(
            "watch_example_dashboard_visible",
            metadata: [
                "screen": "dashboard",
                "focus": activeFocus,
                "interval": currentInterval,
                "hydrationDue": hydrationDue,
            ]
        )
        loupeNetwork(
            url: "watch://session/summary",
            method: "LOCAL",
            statusCode: 200,
            responseBody: #"{"session":"Tempo","interval":3,"status":"active"}"#,
            metadata: [
                "platform": "watchOS",
                "source": "app-authored",
                "screen": "dashboard",
            ]
        )
        loupeReference(
            owner: "WatchSessionDashboard",
            target: "WatchSessionStore",
            kind: "strong",
            label: "watch session store",
            metadata: [
                "platform": "watchOS",
                "screen": "dashboard",
            ]
        )
        loupeLifetimeProbe(
            store,
            name: "watch session store",
            expectedDeallocated: false,
            metadata: ["platform": "watchOS"]
        )
    }

    func beginNextInterval() {
        currentInterval += 1
        elapsedMinutes += 4
        heartRate += 3
        UserDefaults.standard.set(currentInterval, forKey: "watch-session-interval")
        loupeLog(
            "watch_example_next_interval",
            metadata: [
                "interval": currentInterval,
                "elapsedMinutes": elapsedMinutes,
            ]
        )
    }

    func clearHydrationReminder() {
        hydrationDue = false
        UserDefaults.standard.set(false, forKey: "watch-hydration-due")
        loupeLog("watch_example_hydration_cleared")
    }
}

private final class WatchSessionStore: NSObject {}

private struct WatchSessionDashboard: View {
    @ObservedObject var model: WatchSessionModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header
                metrics
                intervalCard
                hydrationCard
                controls
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
        }
        .background(Color.black)
        .onAppear {
            model.publishLaunchEvidenceIfNeeded()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.35), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: 0.72)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(model.elapsedMinutes)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                    Text("min")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 3) {
                Text("Tempo Session")
                    .font(.headline)
                Text("Interval \(model.currentInterval) active")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(model.activeFocus)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.green)
            }
        }
        .localLoupeProbe("watch.example.summary", label: "Tempo session summary")
    }

    private var metrics: some View {
        HStack(spacing: 8) {
            MetricTile(title: "Heart", value: "\(model.heartRate)", unit: "bpm")
                .localLoupeProbe("watch.example.metric.heartRate", label: "Heart rate metric")
            MetricTile(title: "Pace", value: "5:12", unit: "km")
                .localLoupeProbe("watch.example.metric.pace", label: "Pace metric")
        }
        .localLoupeProbe("watch.example.metrics", label: "Session metrics")
    }

    private var intervalCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Current interval")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Hold tempo for 6 min")
                .font(.subheadline.weight(.semibold))
            ProgressView(value: 0.58)
                .tint(.green)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
        .localLoupeProbe("watch.example.interval", label: "Current interval card")
    }

    private var hydrationCard: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Hydration")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(model.hydrationDue ? "Due after interval" : "Reminder cleared")
                    .font(.subheadline.weight(.semibold))
            }
            Spacer(minLength: 4)
            Circle()
                .fill(model.hydrationDue ? Color.cyan : Color.gray)
                .frame(width: 14, height: 14)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cyan.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
        .localLoupeProbe("watch.example.hydration", label: "Hydration reminder")
    }

    private var controls: some View {
        VStack(spacing: 8) {
            Button("Next interval") {
                model.beginNextInterval()
            }
            .buttonStyle(.borderedProminent)
            .localLoupeProbe("watch.example.nextInterval", label: "Next interval button")

            Button("Clear hydration") {
                model.clearHydrationReminder()
            }
            .buttonStyle(.bordered)
            .localLoupeProbe("watch.example.clearHydration", label: "Clear hydration button")
        }
        .localLoupeProbe("watch.example.controls", label: "Session controls")
    }
}

private struct MetricTile: View {
    var title: String
    var value: String
    var unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

private extension View {
    func localLoupeProbe(_ id: String, label: String? = nil) -> some View {
        modifier(LoupeFallbackProbeModifier(id: id, label: label))
    }
}

private struct LoupeFallbackProbeModifier: ViewModifier {
    var id: String
    var label: String?

    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            loupeProbe(id, label: label, frame: proxy.frame(in: .global))
                        }
                        .onChange(of: proxy.frame(in: .global)) { frame in
                            loupeProbe(id, label: label, frame: frame)
                        }
                }
            }
            .onDisappear {
                loupeRemoveProbe(id)
            }
    }
}

private func loupeLog(_ message: String, metadata: [String: Any] = [:]) {
    var userInfo: [String: Any] = ["message": message]
    if !metadata.isEmpty {
        userInfo["metadata"] = metadata
    }
    NotificationCenter.default.post(
        name: Notification.Name("dev.loupe.log"),
        object: nil,
        userInfo: userInfo
    )
}

private func loupeNetwork(
    url: String,
    method: String,
    statusCode: Int,
    responseBody: String,
    metadata: [String: Any]
) {
    NotificationCenter.default.post(
        name: Notification.Name("dev.loupe.network"),
        object: nil,
        userInfo: [
            "url": url,
            "method": method,
            "statusCode": statusCode,
            "responseBody": responseBody,
            "metadata": metadata,
        ]
    )
}

private func loupeReference(
    owner: String,
    target: String,
    kind: String,
    label: String,
    metadata: [String: Any]
) {
    NotificationCenter.default.post(
        name: Notification.Name("dev.loupe.reference"),
        object: nil,
        userInfo: [
            "owner": owner,
            "target": target,
            "kind": kind,
            "label": label,
            "metadata": metadata,
        ]
    )
}

private func loupeLifetimeProbe(
    _ object: AnyObject,
    name: String,
    expectedDeallocated: Bool,
    metadata: [String: Any]
) {
    NotificationCenter.default.post(
        name: Notification.Name("dev.loupe.lifetimeProbe"),
        object: object,
        userInfo: [
            "name": name,
            "expectedDeallocated": expectedDeallocated,
            "metadata": metadata,
        ]
    )
}

private func loupeProbe(_ id: String, label: String?, frame: CGRect? = nil) {
    var userInfo: [String: Any] = [
        "id": id,
        "metadata": ["source": "local-fallback"],
    ]
    if let label {
        userInfo["label"] = label
    }
    if let frame, frame.isFinite {
        userInfo["frame"] = [
            "x": Double(frame.origin.x),
            "y": Double(frame.origin.y),
            "width": Double(frame.width),
            "height": Double(frame.height),
        ]
    }

    NotificationCenter.default.post(
        name: Notification.Name("dev.loupe.probe"),
        object: nil,
        userInfo: userInfo
    )
}

private func loupeRemoveProbe(_ id: String) {
    NotificationCenter.default.post(
        name: Notification.Name("dev.loupe.removeProbe"),
        object: nil,
        userInfo: ["id": id]
    )
}

private extension CGRect {
    var isFinite: Bool {
        origin.x.isFinite && origin.y.isFinite && width.isFinite && height.isFinite
    }
}
