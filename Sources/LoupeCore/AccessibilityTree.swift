import Foundation

public struct LoupeAccessibilityNode: Codable, Equatable {
    public var ref: String
    public var sourceRef: String
    public var parentRef: String?
    public var role: String?
    public var label: String?
    public var value: String?
    public var hint: String?
    public var testID: String?
    public var traits: [String]
    public var frame: LoupeRect?
    public var activationPoint: LoupePoint?
    public var isVisible: Bool
    public var isEnabled: Bool
    public var isInteractive: Bool
    public var children: [String]

    public init(
        ref: String,
        sourceRef: String,
        parentRef: String? = nil,
        role: String? = nil,
        label: String? = nil,
        value: String? = nil,
        hint: String? = nil,
        testID: String? = nil,
        traits: [String] = [],
        frame: LoupeRect? = nil,
        activationPoint: LoupePoint? = nil,
        isVisible: Bool,
        isEnabled: Bool,
        isInteractive: Bool,
        children: [String] = []
    ) {
        self.ref = ref
        self.sourceRef = sourceRef
        self.parentRef = parentRef
        self.role = role
        self.label = label
        self.value = value
        self.hint = hint
        self.testID = testID
        self.traits = traits
        self.frame = frame
        self.activationPoint = activationPoint
        self.isVisible = isVisible
        self.isEnabled = isEnabled
        self.isInteractive = isInteractive
        self.children = children
    }
}

public struct LoupeAccessibilityTree: Codable, Equatable {
    public var snapshotID: String
    public var screen: LoupeScreen
    public var rootRefs: [String]
    public var nodes: [String: LoupeAccessibilityNode]

    public init(
        snapshotID: String,
        screen: LoupeScreen,
        rootRefs: [String],
        nodes: [String: LoupeAccessibilityNode]
    ) {
        self.snapshotID = snapshotID
        self.screen = screen
        self.rootRefs = rootRefs
        self.nodes = nodes
    }

    public static func build(
        from snapshot: LoupeSnapshot,
        includeHidden: Bool = false
    ) -> LoupeAccessibilityTree {
        let sourceNodes = snapshot.nodes.values.filter { shouldInclude($0, includeHidden: includeHidden) }
        let includedSourceRefs = Set(sourceNodes.map(\.ref))
        var nodes: [String: LoupeAccessibilityNode] = [:]
        var childrenByParent: [String: [String]] = [:]
        var rootRefs: [String] = []

        for source in sourceNodes {
            let ref = accessibilityRef(for: source.ref)
            let parentRef = nearestAccessibilityParentRef(
                for: source,
                in: snapshot,
                includedSourceRefs: includedSourceRefs
            )
            let accessibility = source.accessibility
            let frame = accessibility?.frame ?? source.frame
            nodes[ref] = LoupeAccessibilityNode(
                ref: ref,
                sourceRef: source.ref,
                parentRef: parentRef.map(accessibilityRef(for:)),
                role: accessibilityRole(for: source),
                label: nonEmpty(accessibility?.label) ?? nonEmpty(source.label) ?? nonEmpty(source.text),
                value: nonEmpty(accessibility?.value) ?? nonEmpty(source.value) ?? nonEmpty(source.placeholder),
                hint: nonEmpty(accessibility?.hint),
                testID: nonEmpty(accessibility?.identifier) ?? nonEmpty(source.testID),
                traits: accessibility?.traits ?? [],
                frame: frame,
                activationPoint: validActivationPoint(accessibility?.activationPoint, frame: frame),
                isVisible: source.isVisible,
                isEnabled: source.isEnabled,
                isInteractive: source.isInteractive || (accessibility?.traits.contains("button") ?? false),
                children: []
            )

            if let parentRef {
                childrenByParent[accessibilityRef(for: parentRef), default: []].append(ref)
            } else {
                rootRefs.append(ref)
            }
        }

        for (parentRef, children) in childrenByParent {
            let sortedChildren = children.sorted { lhs, rhs in
                visualOrder(nodes[lhs], nodes[rhs])
            }
            if var parent = nodes[parentRef] {
                parent.children = sortedChildren
                nodes[parentRef] = parent
            }
        }

        rootRefs.sort { lhs, rhs in
            visualOrder(nodes[lhs], nodes[rhs])
        }

        return LoupeAccessibilityTree(
            snapshotID: snapshot.id,
            screen: snapshot.screen,
            rootRefs: rootRefs,
            nodes: nodes
        )
    }

    private static func shouldInclude(_ node: LoupeNode, includeHidden: Bool) -> Bool {
        if !includeHidden, !node.isVisible {
            return false
        }

        let accessibility = node.accessibility
        if accessibility?.isElement == true {
            return true
        }
        if node.isInteractive {
            return true
        }
        if nonEmpty(node.testID) != nil || nonEmpty(accessibility?.identifier) != nil {
            return true
        }
        if nonEmpty(node.label) != nil || nonEmpty(node.text) != nil || nonEmpty(node.value) != nil {
            return true
        }
        return accessibility?.traits.isEmpty == false
    }

    private static func nearestAccessibilityParentRef(
        for node: LoupeNode,
        in snapshot: LoupeSnapshot,
        includedSourceRefs: Set<String>
    ) -> String? {
        var parentRef = node.parentRef
        while let ref = parentRef {
            if includedSourceRefs.contains(ref) {
                return ref
            }
            parentRef = snapshot.nodes[ref]?.parentRef
        }
        return nil
    }

    private static func accessibilityRef(for sourceRef: String) -> String {
        "ax-\(sourceRef)"
    }

    private static func accessibilityRole(for node: LoupeNode) -> String? {
        if let role = node.role {
            return role
        }
        if node.accessibility?.traits.contains("button") == true {
            return "button"
        }
        if node.accessibility?.traits.contains("link") == true {
            return "link"
        }
        if node.accessibility?.traits.contains("image") == true {
            return "image"
        }
        if node.accessibility?.traits.contains("staticText") == true {
            return "staticText"
        }
        return nil
    }

    private static func visualOrder(_ lhs: LoupeAccessibilityNode?, _ rhs: LoupeAccessibilityNode?) -> Bool {
        guard let lhsFrame = lhs?.frame else { return false }
        guard let rhsFrame = rhs?.frame else { return true }

        if abs(lhsFrame.y - rhsFrame.y) > 1 {
            return lhsFrame.y < rhsFrame.y
        }

        return lhsFrame.x < rhsFrame.x
    }

    private static func validActivationPoint(_ point: LoupePoint?, frame: LoupeRect?) -> LoupePoint? {
        guard let point, let frame, !frame.isEmpty else {
            return nil
        }

        guard point.x >= frame.x, point.x <= frame.maxX, point.y >= frame.y, point.y <= frame.maxY else {
            return nil
        }

        return point
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}

public struct LoupeAccessibilityQueryResult: Codable, Equatable {
    public var ref: String
    public var sourceRef: String
    public var role: String?
    public var text: String?
    public var testID: String?
    public var frame: LoupeRect?
    public var activationPoint: LoupePoint?
    public var isVisible: Bool
    public var isEnabled: Bool
    public var isInteractive: Bool

    public init(node: LoupeAccessibilityNode) {
        ref = node.ref
        sourceRef = node.sourceRef
        role = node.role
        text = LoupeAccessibilityTreeQuery.displayText(for: node)
        testID = node.testID
        frame = node.frame
        activationPoint = node.activationPoint
        isVisible = node.isVisible
        isEnabled = node.isEnabled
        isInteractive = node.isInteractive
    }
}

public enum LoupeAccessibilityTreeQuery {
    public static func find(
        _ selector: LoupeSelector,
        in tree: LoupeAccessibilityTree,
        options: LoupeQueryOptions = LoupeQueryOptions()
    ) -> [LoupeAccessibilityQueryResult] {
        tree.nodes.values
            .filter { matchesVisibilityAndState($0, options: options) }
            .filter { matches(selector, node: $0) }
            .sorted(by: resultOrder)
            .prefix(options.maxResults)
            .map(LoupeAccessibilityQueryResult.init)
    }

    public static func first(
        _ selector: LoupeSelector,
        in tree: LoupeAccessibilityTree,
        options: LoupeQueryOptions = LoupeQueryOptions()
    ) -> LoupeAccessibilityQueryResult? {
        find(selector, in: tree, options: options).first
    }

    public static func displayText(for node: LoupeAccessibilityNode) -> String? {
        [node.label, node.value, node.hint]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }

    private static func matchesVisibilityAndState(
        _ node: LoupeAccessibilityNode,
        options: LoupeQueryOptions
    ) -> Bool {
        if !options.includeHidden, !node.isVisible {
            return false
        }

        if !options.includeDisabled, !node.isEnabled {
            return false
        }

        return true
    }

    private static func matches(_ selector: LoupeSelector, node: LoupeAccessibilityNode) -> Bool {
        switch selector {
        case let .testID(testID):
            return node.testID == testID
        case let .text(text, exact):
            return matchesText(text, exact: exact, node: node)
        case let .role(role):
            return node.role == role || node.traits.contains(role)
        case let .roleAndText(role, text, exact):
            return (node.role == role || node.traits.contains(role)) && matchesText(text, exact: exact, node: node)
        case let .ref(ref):
            return node.ref == ref || node.sourceRef == ref
        }
    }

    private static func matchesText(
        _ text: String,
        exact: Bool,
        node: LoupeAccessibilityNode
    ) -> Bool {
        guard let displayText = displayText(for: node) else {
            return false
        }

        if exact {
            return displayText == text
        }

        return displayText.localizedCaseInsensitiveContains(text)
    }

    private static func resultOrder(_ lhs: LoupeAccessibilityNode, _ rhs: LoupeAccessibilityNode) -> Bool {
        if lhs.isInteractive != rhs.isInteractive {
            return lhs.isInteractive && !rhs.isInteractive
        }

        if (lhs.testID != nil) != (rhs.testID != nil) {
            return lhs.testID != nil
        }

        guard let lhsFrame = lhs.frame else { return false }
        guard let rhsFrame = rhs.frame else { return true }

        if abs(lhsFrame.y - rhsFrame.y) > 1 {
            return lhsFrame.y < rhsFrame.y
        }

        return lhsFrame.x < rhsFrame.x
    }
}
