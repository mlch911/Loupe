@testable import LoupeCLI
import Testing

@Suite struct LaunchOptionsTests {
    @Test func udidAliasesDevice() throws {
        let options = try LaunchOptions([
            "--bundle-id", "com.apple.Preferences",
            "--udid", "SIM-UDID",
        ])

        #expect(options.device == "SIM-UDID")
    }

    @Test func bootedResolutionPrefersIPhoneWhenMultiplePlatformsAreBooted() throws {
        let device = try #require(LoupeCLI.preferredBootedDevice(in: [
            "com.apple.CoreSimulator.SimRuntime.tvOS-18-5": [
                ["name": "Apple TV 4K", "state": "Booted", "udid": "TV-UDID"],
            ],
            "com.apple.CoreSimulator.SimRuntime.iOS-18-5": [
                ["name": "iPhone 16 Pro", "state": "Booted", "udid": "PHONE-UDID"],
            ],
        ]))

        #expect(device["udid"] as? String == "PHONE-UDID")
    }

    @Test func bootedResolutionKeepsSingleBootedNonIPhoneDevice() throws {
        let device = try #require(LoupeCLI.preferredBootedDevice(in: [
            "com.apple.CoreSimulator.SimRuntime.tvOS-18-5": [
                ["name": "Apple TV 4K", "state": "Booted", "udid": "TV-UDID"],
            ],
        ]))

        #expect(device["udid"] as? String == "TV-UDID")
    }

    @Test func bootedResolutionRejectsMultipleBootedPhones() {
        let device = LoupeCLI.preferredBootedDevice(in: [
            "com.apple.CoreSimulator.SimRuntime.iOS-18-5": [
                ["name": "iPhone 16 Pro", "state": "Booted", "udid": "PHONE-1"],
                ["name": "iPhone 15", "state": "Booted", "udid": "PHONE-2"],
            ],
            "com.apple.CoreSimulator.SimRuntime.tvOS-18-5": [
                ["name": "Apple TV 4K", "state": "Booted", "udid": "TV-UDID"],
            ],
        ])

        #expect(device == nil)
    }

    @Test func terminateTimeoutDefaultsToLaunchTimeout() {
        #expect(LoupeCLI.simctlTerminateTimeout(launchTimeout: 12, environment: [:]) == 12)
    }

    @Test func terminateTimeoutCanUseEnvironmentOverride() {
        #expect(
            LoupeCLI.simctlTerminateTimeout(
                launchTimeout: 12,
                environment: ["LOUPE_SIMCTL_TERMINATE_TIMEOUT": "25"]
            ) == 25
        )
    }

    @Test func invalidTerminateTimeoutFallsBackToLaunchTimeout() {
        #expect(
            LoupeCLI.simctlTerminateTimeout(
                launchTimeout: 12,
                environment: ["LOUPE_SIMCTL_TERMINATE_TIMEOUT": "0"]
            ) == 12
        )
        #expect(
            LoupeCLI.simctlTerminateTimeout(
                launchTimeout: 12,
                environment: ["LOUPE_SIMCTL_TERMINATE_TIMEOUT": "nope"]
            ) == 12
        )
    }
}
