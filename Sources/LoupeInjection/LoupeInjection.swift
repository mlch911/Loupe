import Foundation
import LoupeKit

#if canImport(UIKit)
import UIKit

@_cdecl("LoupeInjectorStart")
public func LoupeInjectorStart() {
    runLoupeInjectorStartOnMainActor()
}

private func runLoupeInjectorStartOnMainActor() {
    if Thread.isMainThread {
        MainActor.assumeIsolated {
            LoupeInjectedRuntime.shared.start()
        }
    } else {
        DispatchQueue.main.sync {
            MainActor.assumeIsolated {
                LoupeInjectedRuntime.shared.start()
            }
        }
    }
}

@MainActor
private final class LoupeInjectedRuntime {
    static let shared = LoupeInjectedRuntime()

    private var server: LoupeServer?

    private init() {}

    func start() {
        LoupeRuntime.shared.activateBridge()

        guard server == nil else {
            return
        }

        let port = UInt16(ProcessInfo.processInfo.environment["LOUPE_PORT"] ?? "")
            ?? LoupeServer.defaultPort
        let server = LoupeServer()

        do {
            try server.start(port: port)
            self.server = server
            NSLog("LoupeInjector started on port \(port)")
        } catch {
            NSLog("LoupeInjector failed to start: \(String(describing: error))")
        }
    }
}

#endif
