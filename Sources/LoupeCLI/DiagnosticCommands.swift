import Foundation
import LoupeCLIModel
import LoupeCore

extension LoupeCLI {
    static let debugUsage = """
    Usage: loupe debug <subcommand>

    SUBCOMMANDS:
      console                 Fetch app-authored runtime logs.
      network                 Fetch app-authored network events.
      refs                    Fetch app-authored object reference evidence.
    """

    static let stateUsage = """
    Usage: loupe state <subcommand>

    SUBCOMMANDS:
      defaults get|set|unset  Read or change UserDefaults.
      flags get|set|unset     Alias for feature flags stored in UserDefaults.
      keychain list           List current app keychain item metadata.
    """

    static let envUsage = """
    Usage: loupe env <subcommand>

    SUBCOMMANDS:
      appearance light|dark|system
    """

    static let perfUsage = """
    Usage: loupe perf <subcommand>

    SUBCOMMANDS:
      scroll                  Dispatch a scroll gesture and record elapsed time.
    """

    static func debug(_ arguments: [String]) async throws {
        guard let subcommand = arguments.first else {
            throw CLIError(debugUsage)
        }
        let rest = Array(arguments.dropFirst())
        switch subcommand {
        case "console", "logs":
            try await runtimeFetch(
                rest,
                path: "/logs",
                usage: "loupe debug console [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>]"
            )
        case "network":
            try await runtimeFetch(
                rest,
                path: "/network",
                usage: "loupe debug network [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>]"
            )
        case "refs", "heap", "object-graph":
            try await runtimeFetch(
                rest,
                path: "/refs",
                usage: "loupe debug refs [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>]"
            )
        default:
            throw CLIError("Unknown debug command: \(subcommand)")
        }
    }

    static func state(_ arguments: [String]) async throws {
        guard let area = arguments.first else {
            throw CLIError(stateUsage)
        }
        let rest = Array(arguments.dropFirst())
        switch area {
        case "defaults":
            try await stateDefaults(rest, path: "state/defaults", usagePrefix: "loupe state defaults")
        case "flags":
            try await stateDefaults(rest, path: "state/flags", usagePrefix: "loupe state flags")
        case "keychain":
            guard rest.first == "list" else {
                throw CLIError("Usage: loupe state keychain list [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>]")
            }
            try await runtimeFetch(
                Array(rest.dropFirst()),
                path: "/state/keychain",
                usage: "loupe state keychain list [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>]"
            )
        default:
            throw CLIError("Unknown state command: \(area)")
        }
    }

    static func env(_ arguments: [String]) async throws {
        guard let subcommand = arguments.first else {
            throw CLIError(envUsage)
        }
        switch subcommand {
        case "appearance":
            let rest = Array(arguments.dropFirst())
            let appearance: String?
            let optionArgs: [String]
            if let first = rest.first, !first.hasPrefix("-") {
                appearance = first
                optionArgs = Array(rest.dropFirst())
            } else {
                appearance = nil
                optionArgs = rest
            }
            let options = try DiagnosticRuntimeOptions(optionArgs, usage: "loupe env appearance [light|dark|system] [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>]")
            guard let appearance else {
                let data = try await runtimeData(path: "/environment", options: options.runtimeFetchOptions)
                try write(data: data, outputURL: options.outputURL)
                return
            }
            let request = LoupeEnvironmentMutationRequest(appearance: appearance)
            let data = try await postRuntimeJSON(request, path: "environment", options: options)
            try write(data: data, outputURL: options.outputURL)
        default:
            throw CLIError("Unknown env command: \(subcommand)")
        }
    }

    static func perf(_ arguments: [String]) async throws {
        guard let subcommand = arguments.first else {
            throw CLIError(perfUsage)
        }
        let rest = Array(arguments.dropFirst())
        switch subcommand {
        case "scroll":
            let output = outputValue(in: rest)
            let actionArguments = argumentsRemovingOutput(rest)
            let startedAt = Date()
            try await action(command: "swipe", arguments: actionArguments)
            let traceDirectory = traceDirectoryValue(in: rest)
            let traceProfile = try scrollProfile(traceDirectory: traceDirectory)
            let profile = LoupeScrollProfile(
                ref: traceProfile?.ref,
                testID: traceProfile?.testID,
                beforeOffset: traceProfile?.beforeOffset,
                afterOffset: traceProfile?.afterOffset,
                delta: traceProfile?.delta,
                actionElapsed: Date().timeIntervalSince(startedAt),
                traceDirectory: traceDirectory
            )
            let data = try diagnosticJSONEncoder().encode(profile)
            try write(data: data, outputURL: output.map { URL(fileURLWithPath: $0) })
        default:
            throw CLIError("Unknown perf command: \(subcommand)")
        }
    }

    static func hitTest(_ arguments: [String]) async throws {
        let options = try DiagnosticRuntimeOptions(arguments, usage: "loupe ui hit-test --point x,y [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>]")
        guard let point = options.point else {
            throw CLIError("loupe ui hit-test requires --point x,y")
        }
        let data = try await runtimeData(path: "/hit-test?point=\(urlEncode(point))", options: options.runtimeFetchOptions)
        try write(data: data, outputURL: options.outputURL)
    }

    static func responderChain(_ arguments: [String]) async throws {
        let options = try DiagnosticRuntimeOptions(arguments, usage: "loupe ui responder-chain (--test-id <id> | --ref <ref> | --text <text> | --role <role>) [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>]")
        let selectorQuery = try options.selectorQuery()
        let data = try await runtimeData(path: "/responder-chain?\(selectorQuery)", options: options.runtimeFetchOptions)
        try write(data: data, outputURL: options.outputURL)
    }

    private static func stateDefaults(_ arguments: [String], path: String, usagePrefix: String) async throws {
        guard let action = arguments.first else {
            throw CLIError("Usage: \(usagePrefix) get|set|unset <key> [value] [--host <url>] [--output <path>]")
        }
        let rest = Array(arguments.dropFirst())
        switch action {
        case "get":
            guard let key = rest.first else {
                throw CLIError("Usage: \(usagePrefix) get <key> [--host <url>] [--output <path>]")
            }
            let options = try DiagnosticRuntimeOptions(Array(rest.dropFirst()), usage: "\(usagePrefix) get <key> [--host <url>] [--output <path>]")
            let data = try await runtimeData(path: "/\(path)?key=\(urlEncode(key))", options: options.runtimeFetchOptions)
            try write(data: data, outputURL: options.outputURL)
        case "set":
            guard let key = rest.first else {
                throw CLIError("Usage: \(usagePrefix) set <key> [value] [--bool true|false|--number n] [--host <url>] [--output <path>]")
            }
            let remaining = Array(rest.dropFirst())
            let positionalValue = remaining.first.map { !$0.hasPrefix("-") } == true ? remaining[0] : nil
            let valueArgs = positionalValue == nil ? remaining : Array(remaining.dropFirst())
            let options = try DiagnosticRuntimeOptions(valueArgs, usage: "\(usagePrefix) set <key> [value] [--bool true|false|--number n] [--host <url>] [--output <path>]")
            guard let value = options.value ?? positionalValue.map(LoupeMetadataValue.string) else {
                throw CLIError("Usage: \(usagePrefix) set <key> [value] [--bool true|false|--number n] [--host <url>] [--output <path>]")
            }
            let request = LoupeStateMutationRequest(key: key, value: value)
            let data = try await postRuntimeJSON(request, path: path, options: options)
            try write(data: data, outputURL: options.outputURL)
        case "unset", "remove":
            guard let key = rest.first else {
                throw CLIError("Usage: \(usagePrefix) unset <key> [--host <url>] [--output <path>]")
            }
            let options = try DiagnosticRuntimeOptions(Array(rest.dropFirst()), usage: "\(usagePrefix) unset <key> [--host <url>] [--output <path>]")
            let request = LoupeStateMutationRequest(key: key, value: nil)
            let data = try await postRuntimeJSON(request, path: path, options: options)
            try write(data: data, outputURL: options.outputURL)
        default:
            throw CLIError("Unknown \(usagePrefix) command: \(action)")
        }
    }

    private static func postRuntimeJSON<T: Encodable>(_ body: T, path: String, options: DiagnosticRuntimeOptions) async throws -> Data {
        let host = try await resolvedRuntimeHost(
            requestedHost: options.host,
            hostWasExplicit: options.hostWasExplicit,
            udid: options.udid,
            bundleID: options.bundleID
        )
        if let udid = options.udid {
            try await validateRuntimeIdentity(host: host, expectedUDID: udid, timeout: options.timeout)
        }
        var request = URLRequest(url: host.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))))
        request.httpMethod = "POST"
        request.timeoutInterval = options.timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try diagnosticJSONEncoder().encode(body)
        let (data, response) = try await httpData(for: request, timeout: options.timeout, label: "runtime post")
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CLIError("runtime post expected an HTTP response")
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw CLIError("runtime post failed with HTTP \(httpResponse.statusCode): \(String(decoding: data, as: UTF8.self))")
        }
        return data
    }

    private static func diagnosticJSONEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static func traceDirectoryValue(in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: "--trace-dir"), index + 1 < arguments.count else {
            return nil
        }
        return arguments[index + 1]
    }

    private static func outputValue(in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: "--output"), index + 1 < arguments.count else {
            return nil
        }
        return arguments[index + 1]
    }

    private static func argumentsRemovingOutput(_ arguments: [String]) -> [String] {
        var result: [String] = []
        var index = 0
        while index < arguments.count {
            if arguments[index] == "--output" {
                index += 2
            } else {
                result.append(arguments[index])
                index += 1
            }
        }
        return result
    }

    private struct ScrollTraceProfile {
        var ref: String
        var testID: String?
        var beforeOffset: LoupePoint
        var afterOffset: LoupePoint
        var delta: LoupePoint
    }

    private static func scrollProfile(traceDirectory: String?) throws -> ScrollTraceProfile? {
        guard let traceDirectory else {
            return nil
        }
        let directory = URL(fileURLWithPath: traceDirectory)
        let beforeURL = directory.appendingPathComponent("before-snapshot.json")
        let afterURL = directory.appendingPathComponent("after-snapshot.json")
        guard FileManager.default.fileExists(atPath: beforeURL.path),
              FileManager.default.fileExists(atPath: afterURL.path) else {
            return nil
        }
        let before = try decodeDiagnosticSnapshot(from: beforeURL)
        let after = try decodeDiagnosticSnapshot(from: afterURL)
        for (ref, beforeNode) in before.nodes {
            guard let beforeOffset = beforeNode.uiKit?.scrollView?.contentOffset,
                  let afterOffset = after.nodes[ref]?.uiKit?.scrollView?.contentOffset,
                  beforeOffset != afterOffset else {
                continue
            }
            return ScrollTraceProfile(
                ref: ref,
                testID: beforeNode.testID,
                beforeOffset: beforeOffset,
                afterOffset: afterOffset,
                delta: LoupePoint(x: afterOffset.x - beforeOffset.x, y: afterOffset.y - beforeOffset.y)
            )
        }
        return nil
    }

    private static func decodeDiagnosticSnapshot(from url: URL) throws -> LoupeSnapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(LoupeSnapshot.self, from: Data(contentsOf: url))
    }

    static func urlEncode(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
    }
}
