@testable import LoupeCLI
import Foundation
import Testing

@Suite struct CLIHelpTests {
    @Test func versionFallsBackToDevelopmentVersionOutsideHomebrew() {
        #expect(LoupeCLI.versionString(executablePath: "/tmp/loupe/.build/debug/loupe") == "0.1.4-dev")
    }

    @Test func versionCanBeDetectedFromHomebrewCellarPath() {
        #expect(
            LoupeCLI.versionString(
                executablePath: "/opt/homebrew/Cellar/loupe/1.2.3/bin/loupe"
            ) == "1.2.3"
        )
    }

    @Test func versionCanBeDetectedFromResolvedHomebrewSymlinkPath() {
        #expect(
            LoupeCLI.versionString(
                executablePath: "/opt/homebrew/bin/loupe",
                resolvedExecutablePath: "/opt/homebrew/Cellar/loupe/1.2.3/bin/loupe"
            ) == "1.2.3"
        )
    }

    @Test func summaryHelpUsesConciseTuistStyleOverview() {
        let output = LoupeCLI.summaryHelp(version: "1.2.3")

        #expect(output.contains("OVERVIEW:"))
        #expect(output.contains("VERSION: 1.2.3"))
        #expect(output.contains("USAGE: loupe <subcommand>"))
        #expect(output.contains("RUNTIME SUBCOMMANDS:"))
        #expect(output.contains("See 'loupe help <subcommand>' for detailed help."))
        #expect(LoupeCLI.summaryHelpLineCount(version: "1.2.3") <= 50)
        #expect(!output.contains("accessibility <snapshot.json>"))
        #expect(!output.contains("wait-for-value"))
    }

    @Test func publicCommandUsageFirstLinesStayStable() throws {
        let expectedUsage: [String: String] = [
            "start": "Usage: loupe start --bundle-id <id> [--device <sim>|--udid <sim>] [--port <port>] [--env KEY=VALUE] [--timeout <seconds>]",
            "capture-report": "Usage: loupe capture-report [--host <url>] [--udid <sim>] [--bundle-id <id>] --output <dir> [--screen-map-limit <n>] [--timeout <seconds>]",
            "logs": "Usage: loupe logs [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>]",
            "tree": "Usage: loupe tree [snapshot.json] [--host <url>] [--udid <sim>] [--bundle-id <id>] [--view|--accessibility] [--depth <n>]",
            "tap": "Usage: loupe tap (--test-id <id> | --ref <ref> | --x <n> --y <n>) --udid <sim> [--host <url>] [--snapshot <snapshot.json>] [--trace-dir <path>] [--expect-visible <testID>]",
            "swipe": "Usage: loupe swipe --from x,y --to x,y --udid <sim> [--host <url>] [--duration <seconds>] [--no-verify-scroll] [--trace-dir <path>]",
            "drag": "Usage: loupe drag --from x,y --to x,y --udid <sim> [--host <url>] [--duration <seconds>] [--trace-dir <path>]",
            "type": "Usage: loupe type <text> --udid <sim> [--host <url>] [--trace-dir <path>]",
            "trace-summary": "Usage: loupe trace-summary <trace-dir> [--json] [--limit <n>]",
            "diff": "Usage: loupe diff <before-snapshot.json> <after-snapshot.json> [--json] [--changed-only] [--limit <n>]",
            "screenshot": "Usage: loupe screenshot --udid <sim> --output <path> [--timeout <seconds>]",
            "cleanup": "Usage: loupe cleanup [--dry-run] [--no-runtimes] [--no-traces] [--traces-older-than <duration>|--all-traces] [--timeout <seconds>]",
            "set": "Usage: loupe set (--test-id <id> | --ref <ref> | --role <role> | --text <text>) <property> <value> [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>]",
            "set-many": "Usage: loupe set-many (--refs <refs> | --type-name <name> | --role <role>) <property> (--value <value> | --number <n> | --bool <bool> | --color <color> | --colors <colors>)",
            "mutations": "Usage: loupe mutations [--host <url>] [--udid <sim>] [--bundle-id <id>]",
            "constraints": "Usage: loupe constraints [snapshot.json] (--ref <ref> | --test-id <id> | --text <text>) [--json]",
            "set-constraint": "Usage: loupe set-constraint --id <constraint-id> constant <value> [priority <value>] [active true|false]",
        ]

        for (command, expected) in expectedUsage {
            #expect(try firstNonEmptyLine(from: LoupeCLI.commandUsage(command)) == expected)
        }
    }

    @Test func publicCommandHelpIsAvailableForActionAndMutationCommands() {
        let publicCommands = [
            "start",
            "capture-report",
            "logs",
            "tree",
            "tap",
            "swipe",
            "drag",
            "type",
            "trace-summary",
            "diff",
            "screenshot",
            "cleanup",
            "set",
            "set-many",
            "mutations",
            "constraints",
            "set-constraint",
            "deactivate-constraint",
        ]

        for command in publicCommands {
            #expect(LoupeCLI.commandUsage(command) != nil)
        }
    }

    private func firstNonEmptyLine(from text: String?) throws -> String {
        let text = try #require(text)
        return try #require(
            text.split(separator: "\n")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty }
        )
    }
}
