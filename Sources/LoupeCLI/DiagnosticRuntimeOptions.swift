import Foundation
import LoupeCLIModel
import LoupeCore

struct DiagnosticRuntimeOptions {
    var host: URL
    var hostWasExplicit: Bool
    var udid: String?
    var bundleID: String?
    var outputURL: URL?
    var timeout: TimeInterval
    var point: String?
    var testID: String?
    var ref: String?
    var text: String?
    var role: String?
    var value: LoupeMetadataValue?

    var runtimeFetchOptions: RuntimeFetchOptions {
        RuntimeFetchOptions(
            host: host,
            hostWasExplicit: hostWasExplicit,
            udid: udid,
            bundleID: bundleID,
            outputURL: outputURL,
            timeout: timeout
        )
    }

    init(_ arguments: [String], usage: String) throws {
        host = URL(string: "http://127.0.0.1:8765")!
        hostWasExplicit = false
        timeout = 5

        var index = 0
        while index < arguments.count {
            switch arguments[index] {
            case "--host":
                let raw = try Self.value(after: "--host", in: arguments, index: &index)
                guard let url = URL(string: raw) else {
                    throw CLIError("Invalid --host URL: \(raw)")
                }
                host = url
                hostWasExplicit = true
            case "--udid", "--device":
                udid = try Self.value(after: arguments[index], in: arguments, index: &index)
            case "--bundle-id":
                bundleID = try Self.value(after: "--bundle-id", in: arguments, index: &index)
            case "--output":
                outputURL = URL(fileURLWithPath: try Self.value(after: "--output", in: arguments, index: &index))
            case "--timeout":
                timeout = try Self.double(after: "--timeout", in: arguments, index: &index)
            case "--point":
                point = try Self.value(after: "--point", in: arguments, index: &index)
            case "--test-id":
                testID = try Self.value(after: "--test-id", in: arguments, index: &index)
            case "--ref":
                ref = try Self.value(after: "--ref", in: arguments, index: &index)
            case "--text":
                text = try Self.value(after: "--text", in: arguments, index: &index)
            case "--role":
                role = try Self.value(after: "--role", in: arguments, index: &index)
            case "--bool":
                let raw = try Self.value(after: "--bool", in: arguments, index: &index)
                guard let bool = Bool(raw) else {
                    throw CLIError("--bool expects true or false")
                }
                value = .bool(bool)
            case "--number":
                let raw = try Self.value(after: "--number", in: arguments, index: &index)
                if let int = Int(raw) {
                    value = .int(int)
                } else if let double = Double(raw) {
                    value = .double(double)
                } else {
                    throw CLIError("--number expects a number")
                }
            case "--help", "-h":
                throw CLIError(usage)
            default:
                throw CLIError("Unknown diagnostic option: \(arguments[index])")
            }
            index += 1
        }

        guard timeout > 0 else {
            throw CLIError("--timeout must be greater than 0")
        }
    }

    func selectorQuery() throws -> String {
        if let testID {
            return "test-id=\(LoupeCLI.urlEncode(testID))"
        }
        if let ref {
            return "ref=\(LoupeCLI.urlEncode(ref))"
        }
        if let text {
            return "text=\(LoupeCLI.urlEncode(text))"
        }
        if let role {
            return "role=\(LoupeCLI.urlEncode(role))"
        }
        throw CLIError("Expected --test-id, --ref, --text, or --role")
    }

    private static func value(after option: String, in arguments: [String], index: inout Int) throws -> String {
        let valueIndex = index + 1
        guard valueIndex < arguments.count else {
            throw CLIError("\(option) requires a value")
        }
        index = valueIndex
        return arguments[valueIndex]
    }

    private static func double(after option: String, in arguments: [String], index: inout Int) throws -> Double {
        let raw = try value(after: option, in: arguments, index: &index)
        guard let value = Double(raw) else {
            throw CLIError("\(option) expects a number")
        }
        return value
    }
}
