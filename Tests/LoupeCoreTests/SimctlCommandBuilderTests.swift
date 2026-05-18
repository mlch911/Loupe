import Testing
@testable import LoupeCore

struct SimctlCommandBuilderTests {
    @Test func launchArgumentsPutDeviceBeforeBundleID() {
        let request = SimctlLaunchRequest(
            device: "booted",
            bundleID: "com.example.App",
            environment: [
                "Z_FLAG": "1",
                "DYLD_INSERT_LIBRARIES": "/tmp/libProbe.dylib",
            ]
        )

        #expect(
            SimctlCommandBuilder.launchArguments(for: request) == [
                "simctl",
                "launch",
                "booted",
                "com.example.App",
            ]
        )
    }

    @Test func launchEnvironmentUsesSIMCTLChildPrefix() {
        let request = SimctlLaunchRequest(
            bundleID: "com.example.App",
            environment: [
                "DYLD_INSERT_LIBRARIES": "/tmp/libProbe.dylib",
            ]
        )

        #expect(
            SimctlCommandBuilder.launchEnvironment(for: request, inheriting: [:]) == [
                "SIMCTL_CHILD_DYLD_INSERT_LIBRARIES": "/tmp/libProbe.dylib",
            ]
        )
    }
}
