import Foundation
import Testing
import LoupeCore
import LoupeKit

#if canImport(AppKit) && !canImport(UIKit)
import AppKit
#endif

#if canImport(UIKit) || canImport(AppKit)
@Suite struct LoupeRuntimeBridgeTests {
    @MainActor
    @Test func runtimeLogBridgeKeepsMostRecentFiveHundredEntries() {
        let runtime = LoupeRuntime.shared
        runtime.activateBridge()

        for index in 0...500 {
            NotificationCenter.default.post(
                name: .loupeLog,
                object: nil,
                userInfo: [
                    "level": "debug",
                    "message": "platform-log-\(index)",
                    "metadata": ["index": index]
                ]
            )
        }

        let logs = runtime.runtimeLogs()

        #expect(logs.count == 500)
        #expect(!logs.contains { $0.message == "platform-log-0" })
        #expect(logs.contains { log in
            log.level == "debug"
                && log.message == "platform-log-500"
                && log.metadata["index"] == .int(500)
        })
    }
}
#endif

#if canImport(AppKit) && !canImport(UIKit)
@Suite struct LoupeAgentAppKitTests {
    @MainActor
    @Test func appKitSnapshotCapturesWindowTestIDMetadataAndDiagnostics() throws {
        let fixture = AppKitFixture()
        defer { fixture.tearDown() }

        LoupeRuntime.shared.activateBridge()
        NotificationCenter.default.post(
            name: .loupeViewMetadata,
            object: nil,
            userInfo: [
                "testID": fixture.buttonTestID,
                "metadata": [
                    "runtimeTag": "posted-by-test-id",
                    "priority": 7
                ]
            ]
        )

        let agent = LoupeAgent()
        let snapshot = agent.captureSnapshot()
        let appNode = try #require(snapshot.rootRefs.compactMap { snapshot.nodes[$0] }.first)
        let windowNode = try #require(snapshot.nodes.values.first { $0.testID == fixture.windowTestID })
        let buttonNode = try #require(snapshot.nodes.values.first { $0.testID == fixture.buttonTestID })

        #expect(appNode.kind == .application)
        #expect(appNode.typeName == "NSApplication")
        #expect(windowNode.kind == .window)
        #expect(windowNode.typeName == "NSWindow")
        #expect(buttonNode.typeName == "NSButton")
        #expect(buttonNode.text == "Run")
        #expect(buttonNode.custom["fixture"] == .string("appkit"))
        #expect(buttonNode.custom["runtimeTag"] == .string("posted-by-test-id"))
        #expect(buttonNode.custom["priority"] == .int(7))

        let buttonFrame = try #require(buttonNode.frame)
        let hitTest = agent.hitTest(point: buttonFrame.center)

        #expect(hitTest.hitRef == buttonNode.ref)
        #expect(hitTest.hitTestID == fixture.buttonTestID)
        #expect(hitTest.hitTypeName == "NSButton")
        #expect(hitTest.responderChain.contains { $0.ref == buttonNode.ref })

        let responderReport = try #require(agent.responderChain(selector: .testID(fixture.buttonTestID)))

        #expect(responderReport.hitRef == buttonNode.ref)
        #expect(responderReport.hitTestID == fixture.buttonTestID)
        #expect(responderReport.responderChain.contains { $0.testID == fixture.buttonTestID })
        #expect(!agent.mutationCapabilities().isEmpty)
    }
}

@MainActor
private final class AppKitFixture {
    let windowTestID = "platform.window"
    let buttonTestID = "platform.primaryButton"

    private let window: NSWindow

    init() {
        _ = NSApplication.shared

        window = NSWindow(
            contentRect: NSRect(x: 120, y: 140, width: 360, height: 240),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.identifier = NSUserInterfaceItemIdentifier(windowTestID)
        window.title = "Loupe Platform Fixture"

        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 360, height: 240))
        contentView.identifier = NSUserInterfaceItemIdentifier("platform.content")

        let button = NSButton(frame: NSRect(x: 80, y: 96, width: 120, height: 44))
        button.title = "Run"
        button.bezelStyle = .rounded
        button.testID(buttonTestID)
        button.testProperty("fixture", "appkit")

        contentView.addSubview(button)
        window.contentView = contentView
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        contentView.layoutSubtreeIfNeeded()
    }

    func tearDown() {
        window.orderOut(nil)
        window.close()
    }
}
#endif
