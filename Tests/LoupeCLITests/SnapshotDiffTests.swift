@testable import LoupeCLI
import Foundation
import LoupeCore
import Testing

@Suite struct SnapshotDiffTests {
    @Test func reportsStyleColorChanges() {
        let before = snapshot(
            id: "before",
            node: node(style: LoupeStyle())
        )
        let after = snapshot(
            id: "after",
            node: node(style: LoupeStyle(
                backgroundColor: LoupeColor(red: 1, green: 0.894, blue: 0.902, alpha: 1),
                tintColor: LoupeColor(red: 0, green: 0.478, blue: 1, alpha: 1),
                shadowOpacity: 0.2
            ))
        )

        let diff = LoupeCLI.snapshotDiff(before: before, after: after)

        #expect(diff.changed.count == 1)
        #expect(diff.changed[0].changes.contains { change in
            change.field == "style.backgroundColor"
                && change.before == nil
                && change.after == "rgba(1,0.894,0.902,1)"
        })
        #expect(diff.changed[0].changes.contains { change in
            change.field == "style.tintColor"
                && change.after == "rgba(0,0.478,1,1)"
        })
        #expect(diff.changed[0].changes.contains { change in
            change.field == "style.shadowOpacity"
                && change.after == "0.2"
        })
    }

    @Test func reportsScrollViewPropertyChanges() {
        let before = snapshot(
            id: "before",
            node: scrollNode(offsetY: 0, paging: false)
        )
        let after = snapshot(
            id: "after",
            node: scrollNode(offsetY: 240, paging: true)
        )

        let diff = LoupeCLI.snapshotDiff(before: before, after: after)

        #expect(diff.changed[0].changes.contains { change in
            change.field == "uiKit.scrollView.contentOffset"
                && change.before == "0,0"
                && change.after == "0,240"
        })
        #expect(diff.changed[0].changes.contains { change in
            change.field == "uiKit.scrollView.isPagingEnabled"
                && change.before == "false"
                && change.after == "true"
        })
        #expect(diff.changed[0].changes.contains { change in
            change.field == "uiKit.scrollView.bounces"
                && change.before == "true"
                && change.after == "false"
        })
    }

    private func snapshot(id: String, node: LoupeNode) -> LoupeSnapshot {
        LoupeSnapshot(
            id: id,
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 390, height: 844), scale: 3),
            rootRefs: [node.ref],
            nodes: [node.ref: node]
        )
    }

    private func node(style: LoupeStyle?) -> LoupeNode {
        LoupeNode(
            ref: "n1",
            parentRef: nil,
            kind: .view,
            typeName: "UIView",
            testID: "settings.cell.background",
            frame: LoupeRect(x: 0, y: 100, width: 390, height: 44),
            isVisible: true,
            isEnabled: true,
            isInteractive: false,
            style: style
        )
    }

    private func scrollNode(offsetY: Double, paging: Bool) -> LoupeNode {
        LoupeNode(
            ref: "scroll",
            parentRef: nil,
            kind: .view,
            typeName: "UIScrollView",
            role: "scrollView",
            testID: "results.scroll",
            frame: LoupeRect(x: 0, y: 0, width: 390, height: 500),
            isVisible: true,
            isEnabled: true,
            isInteractive: true,
            uiKit: LoupeUIKitProperties(
                className: "UIScrollView",
                tag: 0,
                alpha: 1,
                isHidden: false,
                isOpaque: false,
                clipsToBounds: true,
                userInteractionEnabled: true,
                isFirstResponder: false,
                scrollView: LoupeUIScrollViewProperties(
                    contentOffset: LoupePoint(x: 0, y: offsetY),
                    contentSize: LoupeSize(width: 390, height: 1_200),
                    adjustedContentInset: LoupeInsets(top: 0, left: 0, bottom: 34, right: 0),
                    isScrollEnabled: true,
                    isPagingEnabled: paging,
                    bounces: !paging,
                    alwaysBounceVertical: true,
                    alwaysBounceHorizontal: false
                )
            )
        )
    }
}
