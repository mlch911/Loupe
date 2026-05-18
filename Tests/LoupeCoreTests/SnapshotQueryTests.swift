import Foundation
import Testing
@testable import LoupeCore

struct SnapshotQueryTests {
    @Test func findByTestIDPrefersInteractiveResultOrder() {
        let snapshot = makeSnapshot(nodes: [
            LoupeNode(
                ref: "n1",
                parentRef: nil,
                kind: .view,
                typeName: "UILabel",
                role: "staticText",
                testID: "checkout.payButton",
                text: "Pay now",
                frame: LoupeRect(x: 24, y: 100, width: 120, height: 30),
                isVisible: true,
                isEnabled: true,
                isInteractive: false
            ),
            LoupeNode(
                ref: "n2",
                parentRef: nil,
                kind: .view,
                typeName: "UIButton",
                role: "button",
                testID: "checkout.payButton",
                text: "Pay now",
                frame: LoupeRect(x: 24, y: 200, width: 200, height: 52),
                isVisible: true,
                isEnabled: true,
                isInteractive: true
            ),
        ])

        let results = LoupeSnapshotQuery.find(.testID("checkout.payButton"), in: snapshot)

        #expect(results.map { $0.ref } == ["n2", "n1"])
    }

    @Test func findByTextCanUsePartialCaseInsensitiveMatching() {
        let snapshot = makeSnapshot(nodes: [
            LoupeNode(
                ref: "n1",
                parentRef: nil,
                kind: .view,
                typeName: "UILabel",
                role: "staticText",
                text: "Payment complete",
                frame: LoupeRect(x: 24, y: 100, width: 200, height: 30),
                isVisible: true,
                isEnabled: true,
                isInteractive: false
            ),
        ])

        let results = LoupeSnapshotQuery.find(.text("complete", exact: false), in: snapshot)

        #expect(results.map { $0.ref } == ["n1"])
    }

    @Test func hiddenNodesAreExcludedByDefault() {
        let snapshot = makeSnapshot(nodes: [
            LoupeNode(
                ref: "n1",
                parentRef: nil,
                kind: .view,
                typeName: "UIButton",
                role: "button",
                testID: "hidden.button",
                frame: LoupeRect(x: 24, y: 100, width: 200, height: 52),
                isVisible: false,
                isEnabled: true,
                isInteractive: true
            ),
        ])

        #expect(LoupeSnapshotQuery.find(.testID("hidden.button"), in: snapshot).isEmpty)
        #expect(
            LoupeSnapshotQuery.find(
                .testID("hidden.button"),
                in: snapshot,
                options: LoupeQueryOptions(includeHidden: true)
            ).map { $0.ref } == ["n1"]
        )
    }

    private func makeSnapshot(nodes: [LoupeNode]) -> LoupeSnapshot {
        LoupeSnapshot(
            id: "s1",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 390, height: 844), scale: 3),
            rootRefs: [],
            nodes: Dictionary(uniqueKeysWithValues: nodes.map { ($0.ref, $0) })
        )
    }
}
