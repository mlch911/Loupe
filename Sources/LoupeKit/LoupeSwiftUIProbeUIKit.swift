import Foundation
import LoupeCore

#if canImport(SwiftUI) && canImport(UIKit) && !os(watchOS)
import SwiftUI
import UIKit

public extension View {
    /// Adds a UIKit probe view that Loupe can capture as a stable `ui node`.
    func loupeProbe(_ id: String, label: String? = nil) -> some View {
        background {
            LoupeSwiftUIProbeRepresentable(id: id, label: label)
        }
    }
}

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
#endif
