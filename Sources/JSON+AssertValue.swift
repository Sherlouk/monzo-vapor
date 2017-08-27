import Foundation
import JSON

extension JSON {
    /// Obtain the value for a given key, throws if the value can not be found and casted
    func value<T>(forKey key: String) throws -> T {
        if T.self is String.Type, let value = self[key]?.string as? T { return value }
        if T.self is Bool.Type, let value = self[key]?.bool as? T { return value }
        if T.self is URL.Type, let value = self[key]?.url as? T { return value }
        if T.self is Date.Type, let value = self[key]?.date as? T { return value }
        if T.self is Int.Type, let value = self[key]?.int as? T { return value }
        
        if self[key] != nil {
            throw MonzoJSONError.unsupportedType(String(describing: T.self))
        }
        
        throw MonzoJSONError.missingKey(key)
    }
    
}
