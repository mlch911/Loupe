import Foundation
import LoupeCore

#if canImport(SwiftUI) && os(watchOS)
import SwiftUI

public extension View {
    /// Registers SwiftUI bounds as a Loupe probe for the watchOS runtime.
    func loupeProbe(_ id: String, label: String? = nil) -> some View {
        modifier(LoupeWatchProbeModifier(id: id, label: label))
    }
}

private struct LoupeWatchProbeModifier: ViewModifier {
    var id: String
    var label: String?

    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            register(frame: proxy.frame(in: .global))
                        }
                        .onChange(of: proxy.frame(in: .global)) { frame in
                            register(frame: frame)
                        }
                }
            }
            .onDisappear {
                Task { @MainActor in
                    Loupe.unregisterProbe(id)
                }
            }
    }

    private func register(frame: CGRect) {
        Task { @MainActor in
            Loupe.registerProbe(
                id,
                label: label,
                frame: loupeRect(from: frame)
            )
        }
    }
}

private func loupeRect(from rect: CGRect) -> LoupeRect? {
    guard rect.isNull == false,
          rect.isInfinite == false,
          rect.width.isFinite,
          rect.height.isFinite else {
        return nil
    }
    return LoupeRect(
        x: Double(rect.origin.x),
        y: Double(rect.origin.y),
        width: Double(rect.width),
        height: Double(rect.height)
    )
}
#endif
