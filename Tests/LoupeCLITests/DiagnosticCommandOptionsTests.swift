@testable import LoupeCLI
import LoupeCore
import Testing

@Suite struct DiagnosticCommandOptionsTests {
    @Test func parsesRoleSelector() throws {
        let options = try DiagnosticRuntimeOptions(["--role", "button"], usage: "usage")

        #expect(try options.selectorQuery() == "role=button")
    }

    @Test func parsesTypedBooleanValueWithoutPositionalValue() throws {
        let options = try DiagnosticRuntimeOptions(["--bool", "false"], usage: "usage")

        #expect(options.value == .bool(false))
    }

    @Test func parsesTypedNumberValueWithoutPositionalValue() throws {
        let options = try DiagnosticRuntimeOptions(["--number", "42"], usage: "usage")

        #expect(options.value == .int(42))
    }
}
