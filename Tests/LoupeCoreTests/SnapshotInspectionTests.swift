import Foundation
import Testing
@testable import LoupeCore

struct SnapshotInspectionTests {
    @Test func inspectReturnsFullNodeAndLocalTreeContext() throws {
        let snapshot = makeInspectionSnapshot()

        let inspection = try #require(
            LoupeSnapshotInspector.inspect(.testID("components.switch"), in: snapshot)
        )

        #expect(inspection.node.testID == "components.switch")
        #expect(inspection.node.uiKit?.className == "UISwitch")
        #expect(inspection.node.uiKit?.switchControl?.isOn == true)
        #expect(inspection.parent?.testID == "components.row")
        #expect(inspection.siblings.map { $0.testID } == ["components.label"])
    }

    @Test func subtreeReturnsBoundedDescendants() throws {
        let snapshot = makeInspectionSnapshot()

        let subtree = try #require(
            LoupeSnapshotInspector.subtree(.testID("components.row"), in: snapshot, maxDepth: 1)
        )

        #expect(subtree.root.testID == "components.row")
        #expect(Set(subtree.nodes.keys) == Set(["row", "label", "switch"]))
    }

    private func makeInspectionSnapshot() -> LoupeSnapshot {
        LoupeSnapshot(
            id: "inspect-1",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 390, height: 844), scale: 3),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .view,
                    typeName: "UIView",
                    frame: LoupeRect(x: 0, y: 0, width: 390, height: 844),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["row"]
                ),
                "row": LoupeNode(
                    ref: "row",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UIStackView",
                    testID: "components.row",
                    frame: LoupeRect(x: 20, y: 100, width: 350, height: 44),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["label", "switch"]
                ),
                "label": LoupeNode(
                    ref: "label",
                    parentRef: "row",
                    kind: .view,
                    typeName: "UILabel",
                    role: "staticText",
                    testID: "components.label",
                    text: "Enabled",
                    frame: LoupeRect(x: 20, y: 100, width: 120, height: 44),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
                "switch": LoupeNode(
                    ref: "switch",
                    parentRef: "row",
                    kind: .view,
                    typeName: "UISwitch",
                    role: "switch",
                    testID: "components.switch",
                    frame: LoupeRect(x: 300, y: 100, width: 51, height: 31),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    uiKit: LoupeUIKitProperties(
                        className: "UISwitch",
                        tag: 0,
                        alpha: 1,
                        isHidden: false,
                        isOpaque: false,
                        clipsToBounds: false,
                        userInteractionEnabled: true,
                        isFirstResponder: false,
                        switchControl: LoupeUISwitchProperties(isOn: true)
                    )
                ),
            ]
        )
    }
}
