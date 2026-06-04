import Foundation
import LoupeCore

#if canImport(SwiftUI) && (canImport(UIKit) || canImport(AppKit))
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public extension View {
    /// Adds a tiny platform view anchor that Loupe can capture as a stable `ui node`.
    func loupeProbe(_ id: String, label: String? = nil) -> some View {
        background {
            LoupeSwiftUIProbeRepresentable(id: id, label: label)
                .frame(width: 1, height: 1)
        }
    }
}

#if canImport(UIKit)
private struct LoupeSwiftUIProbeRepresentable: UIViewRepresentable {
    var id: String
    var label: String?

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.testID(id)
        view.testProperty("loupe.probe", true)
        view.isAccessibilityElement = true
        view.accessibilityLabel = label ?? id
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.testID(id)
        uiView.testProperty("loupe.probe", true)
        uiView.isAccessibilityElement = true
        uiView.accessibilityLabel = label ?? id
        uiView.backgroundColor = .clear
    }
}
#elseif canImport(AppKit)
private struct LoupeSwiftUIProbeRepresentable: NSViewRepresentable {
    var id: String
    var label: String?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.testID(id)
        view.testProperty("loupe.probe", true)
        view.setAccessibilityElement(true)
        view.setAccessibilityLabel(label ?? id)
        view.setAccessibilityRole(.group)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.testID(id)
        nsView.testProperty("loupe.probe", true)
        nsView.setAccessibilityElement(true)
        nsView.setAccessibilityLabel(label ?? id)
        nsView.setAccessibilityRole(.group)
        nsView.wantsLayer = true
        nsView.layer?.backgroundColor = NSColor.clear.cgColor
    }
}
#endif
#endif
