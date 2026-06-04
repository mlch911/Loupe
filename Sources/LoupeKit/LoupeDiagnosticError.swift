import Foundation

public struct LoupeDiagnosticError: Error, CustomStringConvertible {
    public var message: String
    public var description: String { message }

    public init(message: String) {
        self.message = message
    }
}
