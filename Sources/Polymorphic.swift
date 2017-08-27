import Foundation
import FormData
import Vapor

extension StructuredData {
    var url: URL? {
        switch self {
        case .string(let string):
            return string.url
        default:
            return nil
        }
    }
}

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

// MARK: - FormData+Polymorphic

extension FormData.Field {
    var url: URL? {
        return part.body.makeString().url
    }
}
