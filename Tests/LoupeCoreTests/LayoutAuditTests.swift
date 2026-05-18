import Foundation
import Testing
@testable import LoupeCore

struct LayoutAuditTests {
    @Test func auditReportsOverlappingSiblingsAndChildrenOutsideParents() {
        let snapshot = LoupeSnapshot(
            id: "layout-1",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 390, height: 844), scale: 3),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .view,
                    typeName: "UIView",
                    testID: "root",
                    frame: LoupeRect(x: 0, y: 0, width: 200, height: 200),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["a", "b", "c"]
                ),
                "a": LoupeNode(
                    ref: "a",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UIView",
                    testID: "card.a",
                    frame: LoupeRect(x: 20, y: 20, width: 80, height: 80),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
                "b": LoupeNode(
                    ref: "b",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UIView",
                    testID: "card.b",
                    frame: LoupeRect(x: 60, y: 60, width: 80, height: 80),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
                "c": LoupeNode(
                    ref: "c",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UIView",
                    testID: "card.c",
                    frame: LoupeRect(x: 180, y: 180, width: 60, height: 60),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(audit.issueCount == 2)
        #expect(audit.issues.contains { $0.kind == .overlappingSiblings })
        #expect(audit.issues.contains { $0.kind == .childOutsideParent })
    }

    @Test func auditReportsInteractiveTargetAndTestIDIssues() {
        let snapshot = LoupeSnapshot(
            id: "layout-2",
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
                    children: ["small", "missing", "duplicate-a", "duplicate-b"]
                ),
                "small": button(ref: "small", testID: "small.button", frame: LoupeRect(x: 20, y: 20, width: 30, height: 30)),
                "missing": button(ref: "missing", testID: nil, frame: LoupeRect(x: 20, y: 80, width: 80, height: 44)),
                "duplicate-a": button(ref: "duplicate-a", testID: "duplicate.button", frame: LoupeRect(x: 20, y: 140, width: 80, height: 44)),
                "duplicate-b": button(ref: "duplicate-b", testID: "duplicate.button", frame: LoupeRect(x: 120, y: 140, width: 80, height: 44)),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(audit.issues.contains { $0.kind == .smallInteractiveTarget && $0.testID == "small.button" })
        #expect(audit.issues.contains { $0.kind == .missingTestID && $0.ref == "missing" })
        #expect(audit.issues.filter { $0.kind == .duplicateTestID }.count == 2)
    }

    private func button(ref: String, testID: String?, frame: LoupeRect) -> LoupeNode {
        LoupeNode(
            ref: ref,
            parentRef: "root",
            kind: .view,
            typeName: "UIButton",
            role: "button",
            testID: testID,
            frame: frame,
            isVisible: true,
            isEnabled: true,
            isInteractive: true,
            uiKit: LoupeUIKitProperties(
                className: "UIButton",
                tag: 0,
                alpha: 1,
                isHidden: false,
                isOpaque: false,
                clipsToBounds: false,
                userInteractionEnabled: true,
                isFirstResponder: false
            )
        )
    }
}
