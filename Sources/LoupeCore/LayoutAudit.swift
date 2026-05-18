import Foundation

public enum LoupeLayoutIssueKind: String, Codable, Equatable {
    case overlappingSiblings
    case childOutsideParent
    case duplicateTestID
    case missingTestID
    case smallInteractiveTarget
    case lowTextContrast
}

public struct LoupeLayoutIssue: Codable, Equatable {
    public var kind: LoupeLayoutIssueKind
    public var ref: String
    public var otherRef: String?
    public var testID: String?
    public var otherTestID: String?
    public var frame: LoupeRect?
    public var otherFrame: LoupeRect?
    public var overlapArea: Double?
    public var measuredValue: Double?
    public var expectedValue: Double?
    public var message: String

    public init(
        kind: LoupeLayoutIssueKind,
        ref: String,
        otherRef: String? = nil,
        testID: String? = nil,
        otherTestID: String? = nil,
        frame: LoupeRect? = nil,
        otherFrame: LoupeRect? = nil,
        overlapArea: Double? = nil,
        measuredValue: Double? = nil,
        expectedValue: Double? = nil,
        message: String
    ) {
        self.kind = kind
        self.ref = ref
        self.otherRef = otherRef
        self.testID = testID
        self.otherTestID = otherTestID
        self.frame = frame
        self.otherFrame = otherFrame
        self.overlapArea = overlapArea
        self.measuredValue = measuredValue
        self.expectedValue = expectedValue
        self.message = message
    }
}

public struct LoupeLayoutAuditOptions: Equatable {
    public var tolerance: Double
    public var minOverlapArea: Double
    public var minTouchTarget: Double
    public var minContrastRatio: Double

    public init(
        tolerance: Double = 1,
        minOverlapArea: Double = 16,
        minTouchTarget: Double = 44,
        minContrastRatio: Double = 4.5
    ) {
        self.tolerance = tolerance
        self.minOverlapArea = minOverlapArea
        self.minTouchTarget = minTouchTarget
        self.minContrastRatio = minContrastRatio
    }
}

public struct LoupeLayoutAudit: Codable, Equatable {
    public var snapshotID: String
    public var issueCount: Int
    public var issues: [LoupeLayoutIssue]

    public init(snapshotID: String, issues: [LoupeLayoutIssue]) {
        self.snapshotID = snapshotID
        self.issueCount = issues.count
        self.issues = issues
    }
}

public enum LoupeLayoutAuditor {
    public static func audit(
        _ snapshot: LoupeSnapshot,
        options: LoupeLayoutAuditOptions = LoupeLayoutAuditOptions()
    ) -> LoupeLayoutAudit {
        var issues: [LoupeLayoutIssue] = []
        issues.append(contentsOf: duplicateTestIDIssues(in: snapshot))
        issues.append(contentsOf: interactiveIssues(in: snapshot, options: options))
        issues.append(contentsOf: contrastIssues(in: snapshot, options: options))

        for parent in snapshot.nodes.values {
            let visibleChildren = parent.children
                .compactMap { snapshot.nodes[$0] }
                .filter { $0.isVisible && $0.frame != nil }

            if let parentFrame = parent.frame {
                for child in visibleChildren {
                    guard let childFrame = child.frame else { continue }
                    if !parentFrame.contains(childFrame, tolerance: options.tolerance) {
                        issues.append(
                            LoupeLayoutIssue(
                                kind: .childOutsideParent,
                                ref: child.ref,
                                otherRef: parent.ref,
                                testID: child.testID,
                                otherTestID: parent.testID,
                                frame: childFrame,
                                otherFrame: parentFrame,
                                message: "\(displayName(child)) is outside parent \(displayName(parent))"
                            )
                        )
                    }
                }
            }

            for index in visibleChildren.indices {
                for otherIndex in visibleChildren.indices.dropFirst(index + 1) {
                    let first = visibleChildren[index]
                    let second = visibleChildren[otherIndex]
                    guard let firstFrame = first.frame, let secondFrame = second.frame else { continue }
                    let overlapArea = firstFrame.intersectionArea(with: secondFrame)
                    if overlapArea >= options.minOverlapArea {
                        issues.append(
                            LoupeLayoutIssue(
                                kind: .overlappingSiblings,
                                ref: first.ref,
                                otherRef: second.ref,
                                testID: first.testID,
                                otherTestID: second.testID,
                                frame: firstFrame,
                                otherFrame: secondFrame,
                                overlapArea: overlapArea,
                                message: "\(displayName(first)) overlaps sibling \(displayName(second))"
                            )
                        )
                    }
                }
            }
        }

        return LoupeLayoutAudit(snapshotID: snapshot.id, issues: issues)
    }

    private static func duplicateTestIDIssues(in snapshot: LoupeSnapshot) -> [LoupeLayoutIssue] {
        let groups = Dictionary(grouping: snapshot.nodes.values.compactMap { node -> (String, LoupeNode)? in
            guard let testID = node.testID, !testID.isEmpty else { return nil }
            return (testID, node)
        }, by: { $0.0 })

        return groups.values.flatMap { entries -> [LoupeLayoutIssue] in
            let nodes = entries.map(\.1)
            guard nodes.count > 1 else { return [] }
            return nodes.map { node in
                LoupeLayoutIssue(
                    kind: .duplicateTestID,
                    ref: node.ref,
                    testID: node.testID,
                    frame: node.frame,
                    message: "\(displayName(node)) shares a duplicate testID"
                )
            }
        }
    }

    private static func interactiveIssues(
        in snapshot: LoupeSnapshot,
        options: LoupeLayoutAuditOptions
    ) -> [LoupeLayoutIssue] {
        snapshot.nodes.values.flatMap { node -> [LoupeLayoutIssue] in
            guard node.isVisible, node.isInteractive, let frame = node.frame else {
                return []
            }

            var issues: [LoupeLayoutIssue] = []
            if shouldRequireTestID(node), node.testID == nil {
                issues.append(
                    LoupeLayoutIssue(
                        kind: .missingTestID,
                        ref: node.ref,
                        testID: nil,
                        frame: frame,
                        message: "\(displayName(node)) is interactive but has no testID"
                    )
                )
            }

            let minimumSide = min(frame.width, frame.height)
            if minimumSide < options.minTouchTarget {
                issues.append(
                    LoupeLayoutIssue(
                        kind: .smallInteractiveTarget,
                        ref: node.ref,
                        testID: node.testID,
                        frame: frame,
                        measuredValue: minimumSide,
                        expectedValue: options.minTouchTarget,
                        message: "\(displayName(node)) has touch target side \(minimumSide), below \(options.minTouchTarget)"
                    )
                )
            }
            return issues
        }
    }

    private static func contrastIssues(
        in snapshot: LoupeSnapshot,
        options: LoupeLayoutAuditOptions
    ) -> [LoupeLayoutIssue] {
        snapshot.nodes.values.compactMap { node in
            guard
                node.isVisible,
                LoupeObservationCompactor.displayText(for: node) != nil,
                let textColor = node.style?.textColor,
                let backgroundColor = effectiveBackgroundColor(for: node, in: snapshot)
            else {
                return nil
            }

            let ratio = contrastRatio(textColor, backgroundColor)
            guard ratio < options.minContrastRatio else {
                return nil
            }

            return LoupeLayoutIssue(
                kind: .lowTextContrast,
                ref: node.ref,
                testID: node.testID,
                frame: node.frame,
                measuredValue: ratio,
                expectedValue: options.minContrastRatio,
                message: "\(displayName(node)) text contrast \(ratio) is below \(options.minContrastRatio)"
            )
        }
    }

    private static func effectiveBackgroundColor(for node: LoupeNode, in snapshot: LoupeSnapshot) -> LoupeColor? {
        if let color = node.style?.backgroundColor, color.alpha > 0 {
            return color
        }

        var parentRef = node.parentRef
        while let ref = parentRef, let parent = snapshot.nodes[ref] {
            if let color = parent.style?.backgroundColor, color.alpha > 0 {
                return color
            }
            parentRef = parent.parentRef
        }
        return nil
    }

    private static func shouldRequireTestID(_ node: LoupeNode) -> Bool {
        let className = node.uiKit?.className ?? node.typeName
        guard !className.hasPrefix("_") else {
            return false
        }

        let publicInteractiveClasses = [
            "UIButton",
            "UISwitch",
            "UISlider",
            "UISegmentedControl",
            "UITextField",
            "UITextView",
            "UITableViewCell",
            "UICollectionViewCell",
        ]
        return publicInteractiveClasses.contains { className == $0 || className.hasSuffix(".\($0)") }
    }

    private static func contrastRatio(_ lhs: LoupeColor, _ rhs: LoupeColor) -> Double {
        let first = relativeLuminance(lhs)
        let second = relativeLuminance(rhs)
        let lighter = max(first, second)
        let darker = min(first, second)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private static func relativeLuminance(_ color: LoupeColor) -> Double {
        func linear(_ channel: Double) -> Double {
            channel <= 0.03928 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(color.red)
            + 0.7152 * linear(color.green)
            + 0.0722 * linear(color.blue)
    }

    private static func displayName(_ node: LoupeNode) -> String {
        node.testID ?? node.typeName
    }
}
