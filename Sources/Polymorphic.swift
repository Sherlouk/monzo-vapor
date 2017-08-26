import Foundation
import FormData
import Vapor

extension StructuredData {
    public var url: URL? {
        switch self {
        case .string(let string):
            return string.url
        default:
            return nil
        }
    }
    
    public var int64: Int64? {
        switch self {
        case .string(let string):
            return string.int64
        default:
            return nil
        }
    }
}

extension StructuredDataWrapper {
    public var url: URL? {
        return wrapped.string?.url
    }
    
    public var int64: Int64? {
        return wrapped.string?.int64
    }
}

// MARK: - String+Polymorphic

extension String {
    /// Attempts to convert the `String` to a `Int64`.
    /// The conversion uses the `Int64(_: String)` initializer.
    public var int64: Int64? {
        return Int64(self)
    }
    
    /// Attempts to convert the `String` to a `URL`.
    /// The conversion uses the `URL(string: String)` initializer.
    public var url: URL? {
        return URL(string: self)
    }
}

// MARK: - FormData+Polymorphic

extension FormData.Field {
    public var int64: Int64? {
        return part.body.makeString().int64
    }
    
    public var url: URL? {
        return part.body.makeString().url
    }
}
