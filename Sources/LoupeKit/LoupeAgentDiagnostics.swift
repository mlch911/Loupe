import Foundation
import LoupeCore

#if canImport(UIKit)
import Security
import UIKit

public extension LoupeAgent {
    func defaultsEntry(key: String) -> LoupeStateEntry {
        LoupeStateEntry(key: key, value: metadataValue(fromDefault: UserDefaults.standard.object(forKey: key)))
    }

    func setDefault(_ request: LoupeStateMutationRequest) -> LoupeStateMutationResponse {
        let before = metadataValue(fromDefault: UserDefaults.standard.object(forKey: request.key))
        if let value = request.value {
            UserDefaults.standard.set(defaultObject(from: value), forKey: request.key)
        } else {
            UserDefaults.standard.removeObject(forKey: request.key)
        }
        let after = metadataValue(fromDefault: UserDefaults.standard.object(forKey: request.key))
        return LoupeStateMutationResponse(key: request.key, before: before, after: after)
    }

    func keychainItems() -> [LoupeKeychainItem] {
        queryKeychainItems(itemClass: kSecClassGenericPassword as String)
            + queryKeychainItems(itemClass: kSecClassInternetPassword as String)
    }

    func setEnvironment(_ request: LoupeEnvironmentMutationRequest) throws -> LoupeEnvironmentMutationResponse {
        if let appearance = request.appearance {
            let style: UIUserInterfaceStyle
            switch appearance.lowercased() {
            case "light":
                style = .light
            case "dark":
                style = .dark
            case "unspecified", "system":
                style = .unspecified
            default:
                throw LoupeDiagnosticError(message: "Unknown appearance: \(appearance)")
            }

            for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
                for window in scene.windows {
                    window.overrideUserInterfaceStyle = style
                }
            }
        }

        return LoupeEnvironmentMutationResponse(appearance: currentAppearance())
    }

    func currentEnvironment() -> LoupeEnvironmentMutationResponse {
        LoupeEnvironmentMutationResponse(appearance: currentAppearance())
    }
}

public struct LoupeDiagnosticError: Error, CustomStringConvertible {
    public var message: String
    public var description: String { message }
}

@MainActor
private func currentAppearance() -> String {
    UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow?.traitCollection.userInterfaceStyle }
        .first
        .map(interfaceStyleNameForDiagnostics) ?? "unspecified"
}

private func interfaceStyleNameForDiagnostics(_ style: UIUserInterfaceStyle) -> String {
    switch style {
    case .light:
        return "light"
    case .dark:
        return "dark"
    case .unspecified:
        return "unspecified"
    @unknown default:
        return "unknown"
    }
}

private func metadataValue(fromDefault value: Any?) -> LoupeMetadataValue? {
    switch value {
    case let value as String:
        return .string(value)
    case let value as Bool:
        return .bool(value)
    case let value as Int:
        return .int(value)
    case let value as Double:
        return .double(value)
    case let value as Float:
        return .double(Double(value))
    case let value as NSNumber:
        if CFGetTypeID(value) == CFBooleanGetTypeID() {
            return .bool(value.boolValue)
        }
        let doubleValue = value.doubleValue
        if doubleValue.rounded() == doubleValue {
            return .int(value.intValue)
        }
        return .double(doubleValue)
    default:
        return nil
    }
}

private func defaultObject(from value: LoupeMetadataValue) -> Any {
    switch value {
    case let .string(value):
        return value
    case let .bool(value):
        return value
    case let .int(value):
        return value
    case let .double(value):
        return value
    }
}

private func queryKeychainItems(itemClass: String) -> [LoupeKeychainItem] {
    let query: [String: Any] = [
        kSecClass as String: itemClass,
        kSecReturnAttributes as String: true,
        kSecMatchLimit as String: kSecMatchLimitAll,
    ]

    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    guard status == errSecSuccess else {
        return []
    }

    let dictionaries: [[String: Any]]
    if let array = result as? [[String: Any]] {
        dictionaries = array
    } else if let dictionary = result as? [String: Any] {
        dictionaries = [dictionary]
    } else {
        dictionaries = []
    }

    return dictionaries.map { dictionary in
        LoupeKeychainItem(
            itemClass: itemClass,
            service: dictionary[kSecAttrService as String] as? String,
            account: dictionary[kSecAttrAccount as String] as? String,
            accessGroup: dictionary[kSecAttrAccessGroup as String] as? String
        )
    }
}
#endif
