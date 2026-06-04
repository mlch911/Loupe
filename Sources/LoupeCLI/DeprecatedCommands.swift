import Foundation

// Temporary compatibility layer for the pre-command-group CLI surface that
// existed on `main`. Keep deprecated aliases out of public help, and remove
// this file once downstream scripts have migrated to `app`, `ui`, `act`, and
// `debug` command groups.
extension LoupeCLI {
    static func deprecatedCommandReplacement(_ command: String) -> [String]? {
        switch command {
        case "accessibility":
            return ["ui", "accessibility"]
        case "audit":
            return ["ui", "audit"]
        case "compact":
            return ["ui", "compact"]
        case "capture-report":
            return ["ui", "report"]
        case "compare-design":
            return ["ui", "compare-design"]
        case "constraints":
            return ["ui", "constraints"]
        case "cleanup":
            return ["app", "cleanup"]
        case "deactivate-constraint":
            return ["ui", "deactivate-constraint"]
        case "diff":
            return ["debug", "trace", "diff"]
        case "explore-routes":
            return ["debug", "trace", "explore"]
        case "fetch":
            return ["ui", "snapshot"]
        case "install-skills":
            return ["skills", "install"]
        case "logs":
            return ["debug", "logs"]
        case "apps", "runtimes":
            return ["app", "list"]
        case "inspect":
            return ["ui", "node"]
        case "reflect":
            return ["ui", "reflect"]
        case "runtime":
            return ["app", "info"]
        case "mutations":
            return ["ui", "mutations"]
        case "paint-stack":
            return ["ui", "paint"]
        case "set-many":
            return ["ui", "set-many"]
        case "set", "mutate":
            return ["ui", "set"]
        case "set-constraint":
            return ["ui", "set-constraint"]
        case "query":
            return ["ui", "query"]
        case "launch", "start":
            return ["app", "launch"]
        case "screenshot":
            return ["ui", "screenshot"]
        case "screen-map":
            return ["ui", "screen"]
        case "subtree":
            return ["ui", "subtree"]
        case "tree":
            return ["ui", "tree"]
        case "use":
            return ["app", "use"]
        case "current":
            return ["app", "current"]
        case "text-map":
            return ["ui", "text"]
        case "trace-summary":
            return ["debug", "trace", "summary"]
        case "tap", "swipe", "drag", "pinch", "type":
            return ["act", command]
        case "wait-for-visible", "wait-for-gone", "wait-for-value":
            return ["act", "wait"]
        default:
            return nil
        }
    }

    static func runDeprecatedTopLevelCommand(_ command: String, arguments: [String]) async throws -> Bool {
        guard let replacement = deprecatedCommandReplacement(command) else {
            return false
        }
        printDeprecatedCommandWarning(command: command, replacement: replacement)

        switch command {
        case "accessibility":
            try accessibility(arguments)
        case "audit":
            try audit(arguments)
        case "compact":
            try compact(arguments)
        case "capture-report":
            try await captureReport(arguments)
        case "compare-design":
            try compareDesign(arguments)
        case "constraints":
            try await constraints(arguments)
        case "cleanup":
            try await cleanup(arguments)
        case "deactivate-constraint":
            try await mutateConstraint(arguments, deactivate: true)
        case "diff":
            try diff(arguments)
        case "explore-routes":
            try await exploreRoutes(arguments)
        case "fetch":
            try await runtimeFetch(
                arguments,
                path: "/snapshot",
                usage: "loupe fetch [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>]"
            )
        case "install-skills":
            try skills(["install"] + arguments)
        case "logs":
            try await runtimeFetch(
                arguments,
                path: "/logs",
                usage: "loupe logs [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>]"
            )
        case "apps", "runtimes":
            try await runtimes(arguments)
        case "inspect":
            try inspect(arguments)
        case "reflect":
            try reflect(arguments)
        case "runtime":
            try await runtimeFetch(
                arguments,
                path: "/runtime",
                usage: "loupe runtime [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>]"
            )
        case "mutations":
            try await mutations(arguments)
        case "paint-stack":
            try await paintStack(arguments)
        case "set-many":
            try await setMany(arguments)
        case "set", "mutate":
            try await set(arguments)
        case "set-constraint":
            try await mutateConstraint(arguments, deactivate: false)
        case "query":
            try await query(arguments)
        case "launch":
            try await launch(arguments)
        case "screenshot":
            try screenshot(arguments)
        case "screen-map":
            try await screenMap(arguments)
        case "start":
            try await start(arguments)
        case "subtree":
            try subtree(arguments)
        case "tree":
            try await tree(arguments)
        case "use":
            try await use(arguments)
        case "current":
            try await current(arguments)
        case "text-map":
            try await tree(arguments + ["--text"])
        case "trace-summary":
            try traceSummary(arguments)
        case "tap", "swipe", "drag", "pinch", "type":
            try await action(command: command, arguments: arguments)
        case "wait-for-visible":
            try await waitFor(arguments, mode: .visible)
        case "wait-for-gone":
            try await waitFor(arguments, mode: .gone)
        case "wait-for-value":
            try await waitFor(arguments, mode: .value)
        default:
            return false
        }
        return true
    }

    static func printDeprecatedCommandWarning(command: String, replacement: [String]) {
        let replacementText = (["loupe"] + replacement).joined(separator: " ")
        FileHandle.standardError.write(
            Data("warning: `loupe \(command)` is deprecated; use `\(replacementText)` instead.\n".utf8)
        )
    }
}
