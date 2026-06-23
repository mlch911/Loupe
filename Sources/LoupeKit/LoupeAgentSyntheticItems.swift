import Foundation
import LoupeCore

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension LoupeAgent {
    func captureSyntheticBarButtonItems(
        in view: UIView,
        parentRef: String,
        inheritedVisible: Bool,
        nodes: inout [String: LoupeNode]
    ) -> [String] {
        guard let navigationBar = view as? UINavigationBar, let item = navigationBar.topItem else {
            return []
        }

        let leftItems = item.leftBarButtonItems ?? item.leftBarButtonItem.map { [$0] } ?? []
        let rightItems = item.rightBarButtonItems ?? item.rightBarButtonItem.map { [$0] } ?? []
        let candidates = barButtonCandidateViews(in: navigationBar)
        var consumedCandidateIDs = Set<ObjectIdentifier>()
        var refs: [String] = []

        for (index, barButtonItem) in leftItems.enumerated() {
            let ref = makeRef()
            let match = matchedBarButtonView(
                for: barButtonItem,
                position: "left",
                index: index,
                candidates: candidates,
                consumedCandidateIDs: &consumedCandidateIDs
            )
            nodes[ref] = syntheticBarButtonNode(
                barButtonItem,
                ref: ref,
                parentRef: parentRef,
                position: "left",
                index: index,
                matchedView: match,
                inheritedVisible: inheritedVisible
            )
            refs.append(ref)
        }

        for (index, barButtonItem) in rightItems.enumerated() {
            let ref = makeRef()
            let match = matchedBarButtonView(
                for: barButtonItem,
                position: "right",
                index: index,
                candidates: candidates,
                consumedCandidateIDs: &consumedCandidateIDs
            )
            nodes[ref] = syntheticBarButtonNode(
                barButtonItem,
                ref: ref,
                parentRef: parentRef,
                position: "right",
                index: index,
                matchedView: match,
                inheritedVisible: inheritedVisible
            )
            refs.append(ref)
        }

        return refs
    }

    func captureSyntheticTabBarItems(
        in view: UIView,
        parentRef: String,
        inheritedVisible: Bool,
        nodes: inout [String: LoupeNode]
    ) -> [String] {
        guard let tabBar = view as? UITabBar, let items = tabBar.items, !items.isEmpty else {
            return []
        }

        let candidates = tabBarItemCandidateViews(in: tabBar)
        var consumedCandidateIDs = Set<ObjectIdentifier>()
        var refs: [String] = []

        for (index, tabBarItem) in items.enumerated() {
            let ref = makeRef()
            let match = matchedTabBarItemView(
                for: tabBarItem,
                candidates: candidates,
                consumedCandidateIDs: &consumedCandidateIDs
            )
            nodes[ref] = syntheticTabBarItemNode(
                tabBarItem,
                ref: ref,
                parentRef: parentRef,
                index: index,
                selected: tabBar.selectedItem === tabBarItem,
                matchedView: match,
                inheritedVisible: inheritedVisible
            )
            refs.append(ref)
        }

        return refs
    }
}

@MainActor
func syntheticBarButtonNode(
    _ item: UIBarButtonItem,
    ref: String,
    parentRef: String,
    position: String,
    index: Int,
    matchedView: UIView?,
    inheritedVisible: Bool
) -> LoupeNode {
    let frame = matchedView.flatMap(frameInScreen(for:))
    let visible = inheritedVisible && item.isEnabled && frame.map(frameIntersectsScreen) == true
    var custom: [String: LoupeMetadataValue] = [
        "synthetic": .bool(true),
        "source": .string("UIBarButtonItem"),
        "barPosition": .string(position),
        "barIndex": .int(index)
    ]
    if let title = item.title {
        custom["title"] = .string(title)
    }

    let className = matchedView.map(typeName(of:)) ?? "UIBarButtonItem"
    return LoupeNode(
        ref: ref,
        parentRef: parentRef,
        kind: .view,
        typeName: "UIBarButtonItem",
        role: "button",
        testID: item.accessibilityIdentifier,
        label: item.accessibilityLabel ?? item.title,
        value: item.accessibilityValue,
        text: item.title,
        frame: frame,
        isVisible: visible,
        isEnabled: item.isEnabled,
        isInteractive: item.isEnabled,
        accessibility: LoupeAccessibility(
            identifier: item.accessibilityIdentifier,
            label: item.accessibilityLabel ?? item.title,
            value: item.accessibilityValue,
            hint: item.accessibilityHint,
            traits: ["button"],
            frame: frame,
            activationPoint: frame.map { LoupePoint(x: $0.x + $0.width / 2, y: $0.y + $0.height / 2) },
            isElement: true
        ),
        uikit: LoupeUIKitProperties(
            className: className,
            tag: matchedView?.tag ?? 0,
            alpha: matchedView.flatMap { finiteDouble($0.alpha.doubleValue) } ?? 1,
            isHidden: matchedView?.isHidden ?? false,
            isOpaque: matchedView?.isOpaque ?? false,
            clipsToBounds: matchedView?.clipsToBounds ?? false,
            contentMode: matchedView.map { contentModeName($0.contentMode) },
            userInteractionEnabled: matchedView?.isUserInteractionEnabled ?? true,
            gestureRecognizers: matchedView?.gestureRecognizers?.map { typeName(of: $0) } ?? [],
            isFirstResponder: matchedView?.isFirstResponder ?? false,
            control: matchedView.flatMap(controlProperties(for:)),
            button: matchedView.flatMap(buttonProperties(for:))
        ),
        custom: custom
    )
}

@MainActor
func syntheticTabBarItemNode(
    _ item: UITabBarItem,
    ref: String,
    parentRef: String,
    index: Int,
    selected: Bool,
    matchedView: UIView?,
    inheritedVisible: Bool
) -> LoupeNode {
    let frame = matchedView.flatMap(frameInScreen(for:))
    let visible = inheritedVisible && item.isEnabled && frame != nil
    var custom: [String: LoupeMetadataValue] = [
        "synthetic": .bool(true),
        "source": .string("UITabBarItem"),
        "tabIndex": .int(index),
        "tabTag": .int(item.tag),
        "selected": .bool(selected)
    ]
    if let title = item.title {
        custom["title"] = .string(title)
    }

    let className = matchedView.map(typeName(of:)) ?? "UITabBarItem"
    return LoupeNode(
        ref: ref,
        parentRef: parentRef,
        kind: .view,
        typeName: "UITabBarItem",
        role: "button",
        testID: item.accessibilityIdentifier,
        label: item.accessibilityLabel ?? item.title,
        value: item.accessibilityValue,
        text: item.title,
        frame: frame,
        isVisible: visible,
        isEnabled: item.isEnabled,
        isInteractive: item.isEnabled,
        accessibility: LoupeAccessibility(
            identifier: item.accessibilityIdentifier,
            label: item.accessibilityLabel ?? item.title,
            value: item.accessibilityValue,
            hint: item.accessibilityHint,
            traits: selected ? ["button", "selected"] : ["button"],
            frame: frame,
            activationPoint: frame.map { LoupePoint(x: $0.x + $0.width / 2, y: $0.y + $0.height / 2) },
            isElement: true
        ),
        uikit: LoupeUIKitProperties(
            className: className,
            tag: matchedView?.tag ?? item.tag,
            alpha: matchedView.flatMap { finiteDouble($0.alpha.doubleValue) } ?? 1,
            isHidden: matchedView?.isHidden ?? false,
            isOpaque: matchedView?.isOpaque ?? false,
            clipsToBounds: matchedView?.clipsToBounds ?? false,
            contentMode: matchedView.map { contentModeName($0.contentMode) },
            userInteractionEnabled: matchedView?.isUserInteractionEnabled ?? true,
            gestureRecognizers: matchedView?.gestureRecognizers?.map { typeName(of: $0) } ?? [],
            isFirstResponder: matchedView?.isFirstResponder ?? false,
            control: matchedView.flatMap(controlProperties(for:)),
            button: matchedView.flatMap(buttonProperties(for:))
        ),
        custom: custom
    )
}

@MainActor
func matchedBarButtonView(
    for item: UIBarButtonItem,
    position: String,
    index: Int,
    candidates: [UIView],
    consumedCandidateIDs: inout Set<ObjectIdentifier>
) -> UIView? {
    if let customView = item.customView {
        let id = ObjectIdentifier(customView)
        guard !consumedCandidateIDs.contains(id) else {
            return nil
        }
        consumedCandidateIDs.insert(id)
        return customView
    }

    let searchableTexts = [item.title, item.accessibilityLabel, item.accessibilityIdentifier]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

    guard !searchableTexts.isEmpty else {
        return nil
    }

    for candidate in candidates where !consumedCandidateIDs.contains(ObjectIdentifier(candidate)) {
        let text = descendantText(in: candidate)
        let identifier = candidate.accessibilityIdentifier ?? ""
        if searchableTexts.contains(where: { text.contains($0) || identifier == $0 }) {
            consumedCandidateIDs.insert(ObjectIdentifier(candidate))
            return candidate
        }
    }

    let positionedCandidates = candidates
        .filter { !consumedCandidateIDs.contains(ObjectIdentifier($0)) }
        .filter { candidate in
            guard let frame = frameInScreen(for: candidate) else {
                return false
            }
            return frameIntersectsScreen(frame)
        }
        .sorted { lhs, rhs in
            let lhsFrame = frameInScreen(for: lhs)
            let rhsFrame = frameInScreen(for: rhs)
            switch position {
            case "right":
                return (lhsFrame?.maxX ?? 0) > (rhsFrame?.maxX ?? 0)
            default:
                return (lhsFrame?.x ?? 0) < (rhsFrame?.x ?? 0)
            }
        }

    guard positionedCandidates.indices.contains(index) else {
        return nil
    }

    let fallback = positionedCandidates[index]
    consumedCandidateIDs.insert(ObjectIdentifier(fallback))
    return fallback
}

@MainActor
func barButtonCandidateViews(in view: UIView) -> [UIView] {
    var result: [UIView] = []

    func walk(_ current: UIView) {
        if current is UIControl {
            result.append(current)
        }
        for subview in current.subviews {
            walk(subview)
        }
    }

    for subview in view.subviews {
        walk(subview)
    }
    return result.sorted { lhs, rhs in
        barButtonCandidateArea(lhs) > barButtonCandidateArea(rhs)
    }
}

@MainActor
func matchedTabBarItemView(
    for item: UITabBarItem,
    candidates: [UIView],
    consumedCandidateIDs: inout Set<ObjectIdentifier>
) -> UIView? {
    let searchableTexts = [item.title, item.accessibilityLabel, item.accessibilityIdentifier]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

    guard !searchableTexts.isEmpty else {
        return nil
    }

    for candidate in candidates where !consumedCandidateIDs.contains(ObjectIdentifier(candidate)) {
        let text = descendantText(in: candidate)
        let identifier = candidate.accessibilityIdentifier ?? ""
        if searchableTexts.contains(where: { text.contains($0) || identifier == $0 }) {
            consumedCandidateIDs.insert(ObjectIdentifier(candidate))
            return candidate
        }
    }

    return nil
}

@MainActor
func frameIntersectsScreen(_ frame: LoupeRect) -> Bool {
    #if os(visionOS)
    let windowFrames = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap(\.windows)
        .compactMap { frameInScreen(for: $0) }
    guard !windowFrames.isEmpty else {
        return true
    }
    return windowFrames.contains { frame.intersects($0) }
    #else
    let bounds = UIScreen.main.bounds
    let screenFrame = LoupeRect(
        x: bounds.origin.x.doubleValue,
        y: bounds.origin.y.doubleValue,
        width: bounds.width.doubleValue,
        height: bounds.height.doubleValue
    )
    return frame.intersects(screenFrame)
    #endif
}

@MainActor
func tabBarItemCandidateViews(in view: UIView) -> [UIView] {
    var result: [UIView] = []

    func walk(_ current: UIView) {
        if current is UIControl {
            result.append(current)
        }
        for subview in current.subviews {
            walk(subview)
        }
    }

    for subview in view.subviews {
        walk(subview)
    }
    return result.sorted {
        let lhsFrame = frameInScreen(for: $0)
        let rhsFrame = frameInScreen(for: $1)
        return (lhsFrame?.x ?? 0) < (rhsFrame?.x ?? 0)
    }
}

@MainActor
func barButtonCandidateArea(_ view: UIView) -> Double {
    guard let frame = frameInScreen(for: view) else {
        return 0
    }
    return frame.width * frame.height
}

@MainActor
func descendantText(in view: UIView) -> String {
    var parts: [String] = []

    func walk(_ current: UIView) {
        if let value = text(for: current), !value.isEmpty {
            parts.append(value)
        }
        if let label = current.accessibilityLabel, !label.isEmpty {
            parts.append(label)
        }
        for subview in current.subviews {
            walk(subview)
        }
    }

    walk(view)
    return parts.joined(separator: " ")
}

#endif
