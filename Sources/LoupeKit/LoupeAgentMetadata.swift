import Foundation
import LoupeCore

#if canImport(UIKit)
import ObjectiveC
import UIKit

private nonisolated(unsafe) var loupeMetadataKey: UInt8 = 0

public extension UIView {
    var loupeMetadata: [String: LoupeMetadataValue] {
        get {
            objc_getAssociatedObject(self, &loupeMetadataKey) as? [String: LoupeMetadataValue] ?? [:]
        }
        set {
            objc_setAssociatedObject(
                self,
                &loupeMetadataKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    func testID(_ id: String) {
        accessibilityIdentifier = id
        loupeMetadata["id"] = .string(id)
    }

    func testProperty(_ key: String, _ value: String) {
        loupeMetadata[key] = .string(value)
    }

    func testProperty(_ key: String, _ value: Bool) {
        loupeMetadata[key] = .bool(value)
    }

    func testProperty(_ key: String, _ value: Int) {
        loupeMetadata[key] = .int(value)
    }

    func testProperty(_ key: String, _ value: Double) {
        loupeMetadata[key] = .double(value)
    }
}
#endif
