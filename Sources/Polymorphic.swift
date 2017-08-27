import Foundation
import FormData
import Vapor

extension StructuredDataWrapper {
    var url: URL? {
        return wrapped.string?.url
    }
}

// MARK: - String+Polymorphic

extension String {
    /// Attempts to convert the `String` to a `URL`.
    /// The conversion uses the `URL(string: String)` initializer.
    var url: URL? {
        return URL(string: self)
    }
}
