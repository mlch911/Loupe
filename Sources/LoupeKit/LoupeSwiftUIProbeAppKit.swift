import Foundation
import LoupeCore

#if canImport(SwiftUI) && canImport(AppKit)
import AppKit
import SwiftUI

public extension View {
    /// Adds an AppKit probe view that Loupe can capture as a stable `ui node`.
    func loupeProbe(_ id: String, label: String? = nil) -> some View {
        background {
            LoupeSwiftUIProbeRepresentable(id: id, label: label)
        }
    }
}

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
