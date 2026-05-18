import Foundation

public struct LoupeNodeSummary: Codable, Equatable {
    public var ref: String
    public var typeName: String
    public var className: String?
    public var role: String?
    public var text: String?
    public var testID: String?
    public var frame: LoupeRect?
    public var isVisible: Bool
    public var isInteractive: Bool

    public init(node: LoupeNode) {
        ref = node.ref
        typeName = node.typeName
        className = node.uiKit?.className
        role = node.role
        text = LoupeObservationCompactor.displayText(for: node)
        testID = node.testID
        frame = node.frame
        isVisible = node.isVisible
        isInteractive = node.isInteractive
    }
}

public struct LoupeNodeInspection: Codable, Equatable {
    public var node: LoupeNode
    public var parent: LoupeNodeSummary?
    public var siblings: [LoupeNodeSummary]
    public var children: [LoupeNodeSummary]

    public init(
        node: LoupeNode,
        parent: LoupeNodeSummary?,
        siblings: [LoupeNodeSummary],
        children: [LoupeNodeSummary]
    ) {
        self.node = node
        self.parent = parent
        self.siblings = siblings
        self.children = children
    }
}

public struct LoupeSubtree: Codable, Equatable {
    public var root: LoupeNode
    public var maxDepth: Int
    public var nodes: [String: LoupeNode]

    public init(root: LoupeNode, maxDepth: Int, nodes: [String: LoupeNode]) {
        self.root = root
        self.maxDepth = maxDepth
        self.nodes = nodes
    }
}

public enum LoupeSnapshotInspector {
    public static func inspect(
        _ selector: LoupeSelector,
        in snapshot: LoupeSnapshot,
        options: LoupeQueryOptions = LoupeQueryOptions()
    ) -> LoupeNodeInspection? {
        guard
            let result = LoupeSnapshotQuery.first(selector, in: snapshot, options: options),
            let node = snapshot.nodes[result.ref]
        else {
            return nil
        }

        let parent = node.parentRef
            .flatMap { snapshot.nodes[$0] }
            .map(LoupeNodeSummary.init)

        let siblings = node.parentRef
            .flatMap { snapshot.nodes[$0] }?
            .children
            .filter { $0 != node.ref }
            .compactMap { snapshot.nodes[$0] }
            .map(LoupeNodeSummary.init) ?? []

        let children = node.children
            .compactMap { snapshot.nodes[$0] }
            .map(LoupeNodeSummary.init)

        return LoupeNodeInspection(
            node: node,
            parent: parent,
            siblings: siblings,
            children: children
        )
    }

    public static func subtree(
        _ selector: LoupeSelector,
        in snapshot: LoupeSnapshot,
        maxDepth: Int,
        options: LoupeQueryOptions = LoupeQueryOptions()
    ) -> LoupeSubtree? {
        guard
            maxDepth >= 0,
            let result = LoupeSnapshotQuery.first(selector, in: snapshot, options: options),
            let root = snapshot.nodes[result.ref]
        else {
            return nil
        }

        var included: [String: LoupeNode] = [:]
        collectSubtree(root, in: snapshot, depth: 0, maxDepth: maxDepth, included: &included)
        return LoupeSubtree(root: root, maxDepth: maxDepth, nodes: included)
    }

    private static func collectSubtree(
        _ node: LoupeNode,
        in snapshot: LoupeSnapshot,
        depth: Int,
        maxDepth: Int,
        included: inout [String: LoupeNode]
    ) {
        included[node.ref] = node
        guard depth < maxDepth else {
            return
        }

        for childRef in node.children {
            guard let child = snapshot.nodes[childRef] else { continue }
            collectSubtree(child, in: snapshot, depth: depth + 1, maxDepth: maxDepth, included: &included)
        }
    }
}
