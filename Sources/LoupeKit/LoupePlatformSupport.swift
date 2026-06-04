import Foundation
import LoupeCore

#if canImport(UIKit) && !os(watchOS)
import UIKit
typealias LoupePlatformView = UIView
#elseif canImport(AppKit)
import AppKit
typealias LoupePlatformView = NSView
#endif

enum LoupePlatformSupport {
    static var platformName: String {
        #if os(iOS)
        return "iOS"
        #elseif os(tvOS)
        return "tvOS"
        #elseif os(macOS)
        return "macOS"
        #elseif os(visionOS)
        return "visionOS"
        #elseif os(watchOS)
        return "watchOS"
        #else
        return "Apple"
        #endif
    }

    @MainActor
    static var deviceName: String? {
        #if canImport(UIKit) && !os(watchOS)
        UIDevice.current.name
        #elseif canImport(AppKit)
        Host.current().localizedName
        #else
        nil
        #endif
    }

    static func installAutomaticNetworkCapture() {
        #if ((canImport(UIKit) && !os(watchOS)) || canImport(AppKit)) && canImport(ObjectiveC)
        LoupeNetworkCaptureProtocol.install()
        #endif
    }

    #if (canImport(UIKit) && !os(watchOS)) || canImport(AppKit)
    static func metadataView(from notification: Notification, userInfo: [AnyHashable: Any]) -> LoupePlatformView? {
        (notification.object as? LoupePlatformView) ?? (userInfo["view"] as? LoupePlatformView)
    }

    @MainActor
    static func mergeMetadata(_ metadata: [String: LoupeMetadataValue], into view: LoupePlatformView) {
        view.loupeMetadata.merge(metadata) { _, new in new }
    }
    #endif
}
