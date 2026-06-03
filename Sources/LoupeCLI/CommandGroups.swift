import Foundation
import LoupeCLIModel

extension LoupeCLI {
    static func helpPath(command: String, arguments: [String]) -> [String] {
        guard isCommandGroup(command),
              let subcommand = arguments.first,
              !subcommand.hasPrefix("-") else {
            return [command]
        }
        return [command, subcommand]
    }

    static func isCommandGroup(_ command: String) -> Bool {
        ["target", "runtime", "observe", "inspect", "act", "ui", "trace", "debug", "state", "env", "perf"].contains(command)
    }

    static func target(_ arguments: [String]) async throws {
        guard let subcommand = arguments.first else {
            throw CLIError(targetUsage)
        }
        let rest = Array(arguments.dropFirst())
        switch subcommand {
        case "list", "runtimes", "apps":
            try await runtimes(rest)
        case "use":
            try await use(rest)
        case "current":
            try await current(rest)
        default:
            throw CLIError("Unknown target command: \(subcommand)")
        }
    }

    static func runtimeGroup(_ arguments: [String]) async throws {
        guard let subcommand = arguments.first, !subcommand.hasPrefix("-") else {
            try await runtimeFetch(
                arguments,
                path: "/runtime",
                usage: "loupe runtime info [--host <url>] [--udid <sim>] [--output <path>]"
            )
            return
        }

        let rest = Array(arguments.dropFirst())
        switch subcommand {
        case "start":
            try await start(rest)
        case "launch":
            try await launch(rest)
        case "list", "runtimes", "apps":
            try await runtimes(rest)
        case "use":
            try await use(rest)
        case "current":
            try await current(rest)
        case "info":
            try await runtimeFetch(
                rest,
                path: "/runtime",
                usage: "loupe runtime info [--host <url>] [--udid <sim>] [--output <path>]"
            )
        case "logs":
            try await runtimeFetch(
                rest,
                path: "/logs",
                usage: "loupe runtime logs [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>]"
            )
        case "cleanup":
            try await cleanup(rest)
        default:
            throw CLIError("Unknown runtime command: \(subcommand)")
        }
    }

    static func observe(_ arguments: [String]) async throws {
        guard let subcommand = arguments.first else {
            throw CLIError(observeUsage)
        }
        let rest = Array(arguments.dropFirst())
        switch subcommand {
        case "capture", "capture-report":
            try await captureReport(rest)
        case "tree":
            try await tree(rest)
        case "text", "text-map":
            try await tree(rest + ["--text"])
        case "screen", "screen-map":
            try await screenMap(rest)
        case "accessibility":
            try accessibility(rest)
        case "compact":
            try compact(rest)
        case "screenshot":
            try screenshot(rest)
        case "fetch":
            try await fetch(rest)
        default:
            throw CLIError("Unknown observe command: \(subcommand)")
        }
    }

    static func inspectGroup(_ arguments: [String]) async throws {
        guard let subcommand = arguments.first, !subcommand.hasPrefix("-") else {
            try inspect(arguments)
            return
        }

        let rest = Array(arguments.dropFirst())
        switch subcommand {
        case "node":
            try inspect(rest)
        case "query":
            try await query(rest)
        case "subtree":
            try subtree(rest)
        case "paint", "paint-stack":
            try await paintStack(rest)
        case "accessibility":
            try accessibility(rest)
        default:
            try inspect(arguments)
        }
    }

    static func act(_ arguments: [String]) async throws {
        guard let subcommand = arguments.first else {
            throw CLIError(actUsage)
        }
        let rest = Array(arguments.dropFirst())
        switch subcommand {
        case "tap", "swipe", "drag", "pinch", "type":
            try await action(command: subcommand, arguments: rest)
        case "wait":
            try await wait(rest)
        case "wait-for-visible":
            try await waitFor(rest, mode: .visible)
        case "wait-for-gone":
            try await waitFor(rest, mode: .gone)
        case "wait-for-value":
            try await waitFor(rest, mode: .value)
        default:
            throw CLIError("Unknown act command: \(subcommand)")
        }
    }

    static func wait(_ arguments: [String]) async throws {
        guard let mode = arguments.first else {
            throw CLIError("Usage: loupe act wait visible|gone|value <selector> [--timeout <seconds>]")
        }
        let rest = Array(arguments.dropFirst())
        switch mode {
        case "visible":
            try await waitFor(rest, mode: .visible)
        case "gone":
            try await waitFor(rest, mode: .gone)
        case "value":
            try await waitFor(rest, mode: .value)
        default:
            throw CLIError("Unknown wait mode: \(mode)")
        }
    }

    static func ui(_ arguments: [String]) async throws {
        guard let subcommand = arguments.first else {
            throw CLIError(uiUsage)
        }
        let rest = Array(arguments.dropFirst())
        switch subcommand {
        case "audit":
            try audit(rest)
        case "mutations":
            try await mutations(rest)
        case "set":
            try await set(rest)
        case "set-many":
            try await setMany(rest)
        case "constraints":
            try await constraints(rest)
        case "set-constraint":
            try await mutateConstraint(rest, deactivate: false)
        case "deactivate-constraint":
            try await mutateConstraint(rest, deactivate: true)
        case "reflect":
            try reflect(rest)
        case "compare-design":
            try compareDesign(rest)
        case "hit-test":
            try await hitTest(rest)
        case "responder-chain":
            try await responderChain(rest)
        default:
            throw CLIError("Unknown ui command: \(subcommand)")
        }
    }

    static func trace(_ arguments: [String]) async throws {
        guard let subcommand = arguments.first else {
            throw CLIError(traceUsage)
        }
        let rest = Array(arguments.dropFirst())
        switch subcommand {
        case "summary", "trace-summary":
            try traceSummary(rest)
        case "diff":
            try diff(rest)
        case "explore", "explore-routes":
            try await exploreRoutes(rest)
        case "cleanup":
            try await cleanup(rest)
        default:
            throw CLIError("Unknown trace command: \(subcommand)")
        }
    }
}
