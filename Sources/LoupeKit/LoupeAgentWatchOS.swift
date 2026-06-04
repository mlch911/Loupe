import Foundation
import LoupeCore

#if os(watchOS)
@MainActor
public final class LoupeAgent {
    public init() {}

    public func captureSnapshot() -> LoupeSnapshot {
        let appRef = "n0"
        var nodes: [String: LoupeNode] = [:]
        let probes = LoupeRuntime.shared.registeredProbes()
        let probeRefs = probes.enumerated().map { index, probe -> String in
            let ref = "n\(index + 1)"
            nodes[ref] = LoupeNode(
                ref: ref,
                parentRef: appRef,
                kind: .view,
                typeName: "LoupeWatchProbe",
                role: probe.role,
                testID: probe.id,
                label: probe.label,
                text: probe.label,
                frame: probe.frame,
                isVisible: probe.isVisible,
                isEnabled: probe.isEnabled,
                isInteractive: probe.isInteractive,
                accessibility: LoupeAccessibility(
                    identifier: probe.id,
                    label: probe.label ?? probe.id,
                    traits: probe.isInteractive ? ["button"] : [],
                    frame: probe.frame,
                    activationPoint: probe.frame?.center,
                    isElement: true
                ),
                custom: mergedMetadata(probe.metadata, with: LoupeRuntime.shared.metadata(forTestID: probe.id))
            )
            return ref
        }

        nodes[appRef] = LoupeNode(
            ref: appRef,
            parentRef: nil,
            kind: .application,
            typeName: "WKApplication",
            role: "application",
            frame: nil,
            isVisible: true,
            isEnabled: true,
            isInteractive: false,
            custom: [
                "platform": .string("watchOS"),
                "observationBackend": .string("registered-probes"),
            ],
            children: probeRefs
        )

        return LoupeSnapshot(
            id: UUID().uuidString,
            capturedAt: Date(),
            screen: LoupeScreen(size: LoupeSize(width: 0, height: 0), scale: 1),
            rootRefs: [appRef],
            nodes: nodes
        )
    }

    public func captureAccessibilityTree() -> LoupeAccessibilityTree {
        LoupeAccessibilityTree.build(from: captureSnapshot())
    }

    public func captureCompactObservation(
        options: LoupeObservationOptions = LoupeObservationOptions()
    ) -> LoupeCompactObservation {
        LoupeObservationCompactor.compact(captureSnapshot(), options: options)
    }

    public func encodedSnapshot() throws -> Data {
        try encodedSnapshot(encoder: makeLoupeJSONEncoder())
    }

    public func encodedSnapshot(encoder: JSONEncoder) throws -> Data {
        try encoder.encode(captureSnapshot())
    }

    func defaultsEntry(key: String) -> LoupeStateEntry {
        LoupeStateEntry(key: key, value: metadataValue(fromDefault: UserDefaults.standard.object(forKey: key)))
    }

    func setDefault(_ request: LoupeStateMutationRequest) -> LoupeStateMutationResponse {
        let before = metadataValue(fromDefault: UserDefaults.standard.object(forKey: request.key))
        if let value = request.value {
            UserDefaults.standard.set(defaultObject(from: value), forKey: request.key)
        } else {
            UserDefaults.standard.removeObject(forKey: request.key)
        }
        let after = metadataValue(fromDefault: UserDefaults.standard.object(forKey: request.key))
        return LoupeStateMutationResponse(key: request.key, before: before, after: after)
    }

    func keychainItems() -> [LoupeKeychainItem] {
        []
    }

    func setEnvironment(_ request: LoupeEnvironmentMutationRequest) throws -> LoupeEnvironmentMutationResponse {
        if let appearance = request.appearance, !appearance.isEmpty {
            throw LoupeDiagnosticError(message: "watchOS appearance mutation is not supported")
        }
        return currentEnvironment()
    }

    func currentEnvironment() -> LoupeEnvironmentMutationResponse {
        LoupeEnvironmentMutationResponse(appearance: nil)
    }

    public func hitTest(point: LoupePoint) -> LoupeHitTestReport {
        LoupeHitTestReport(point: point)
    }

    public func responderChain(selector: LoupeSelector) -> LoupeHitTestReport? {
        nil
    }

    func mutationCapabilities() -> [LoupeMutationCapability] {
        []
    }

    func mutate(_ request: LoupeMutationRequest) throws -> LoupeMutationResponse {
        throw LoupeDiagnosticError(message: "watchOS mutation backend is not supported")
    }

    func activate(_ request: LoupeActivationRequest) throws -> LoupeActivationResponse {
        throw LoupeDiagnosticError(message: "watchOS activation backend is not supported")
    }

    func mutateConstraint(_ request: LoupeConstraintMutationRequest) throws -> LoupeConstraintMutationResponse {
        throw LoupeDiagnosticError(message: "watchOS constraint mutation backend is not supported")
    }
}

private func metadataValue(fromDefault value: Any?) -> LoupeMetadataValue? {
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

private func mergedMetadata(
    _ base: [String: LoupeMetadataValue],
    with override: [String: LoupeMetadataValue]
) -> [String: LoupeMetadataValue] {
    var merged = base
    merged.merge(override) { _, new in new }
    return merged
}

private func defaultObject(from value: LoupeMetadataValue) -> Any {
    switch value {
    case let .string(value):
        return value
    case let .bool(value):
        return value
    case let .int(value):
        return value
    case let .double(value):
        return value
    }
}
#endif
