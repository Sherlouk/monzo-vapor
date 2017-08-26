import Foundation
import JSON

extension JSON {
    
    func value<T>(forKey key: String) throws -> T {
        if T.self is String.Type, let value = self[key]?.string as? T { return value }
        if T.self is URL.Type, let value = self[key]?.url as? T { return value }
        if T.self is Date.Type, let value = self[key]?.date as? T { return value }
        if T.self is Int64.Type, let value = self[key]?.int64 as? T { return value }
        
        throw ClientError.other(1, ":(")
    }
    
}
