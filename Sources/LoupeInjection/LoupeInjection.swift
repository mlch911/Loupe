import Foundation
import LoupeKit

#if canImport(UIKit) || canImport(AppKit)
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

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
        let bindHost = ProcessInfo.processInfo.environment["LOUPE_BIND_HOST"] ?? "127.0.0.1"
        let server = LoupeServer()

        do {
            try server.start(port: port, bindHost: bindHost)
            self.server = server
            NSLog("LoupeInjector started on \(bindHost):\(port)")
        } catch {
            NSLog("LoupeInjector failed to start: \(String(describing: error))")
        }
    }
}

#endif
