import Foundation

final class JSONObject {
    
    typealias JSONDictionary = [String: Any]
    
    enum `Type`: Int {
        case dictionary
        case string
        case array
        case null
    }
    
    var rawDictionary: JSONDictionary = [:]
    var rawString: String = ""
    var rawArray: [Any] = []
    
    var error: JSONError?
    var type: Type = .null
    
    convenience init(data: Data) throws {
        let jsonObject = try JSONSerialization.jsonObject(with: data, options:.init(rawValue: 0))
        try self.init(jsonObject)
    }
    
    init(_ jsonObject: Any) throws {
        if let jsonDict = jsonObject as? JSONDictionary {
            self.rawDictionary = jsonDict
            self.type = .dictionary
        } else if let jsonString = jsonObject as? String {
            self.rawString = jsonString
            self.type = .string
        } else if let jsonArray = jsonObject as? [Any] {
            self.rawArray = jsonArray
            self.type = .array
        } else {
            print("Unknown Type")
            print(jsonObject)
            throw JSONError.couldNotSerialise
        }
    }
    
    subscript(path: String...) -> JSONObject {
        get {
            return path.reduce(self) {
                if type == .dictionary, let value = rawDictionary[$1] {
                    if let response = try? JSONObject(value) {
                        return response
                    }
                    
                    error = JSONError.couldNotSerialise
                    return self
                }
                
                error = JSONError.noValueAtKeyPath
                return self
            }
        }
    }
    
    var stringValue: String {
        switch self.type {
        case .string: return rawString
        default: return ""
        }
    }
    
    var iso8601Value: Date {
        switch self.type {
        case .string:
            guard let date = DateFormatter.iso8601Formatter().date(from: rawString) else { return Date() }
            return date
        default: return Date()
        }
    }
    
    var arrayValue: [JSONObject] {
        switch self.type {
        case .array: return (try? rawArray.map { try JSONObject($0) }) ?? []
        default: return []
        }
    }
}

extension DateFormatter {
    static func iso8601Formatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        
        return formatter
    }
}

protocol JSONInitalization {
    init(json: JSONObject)
}

enum JSONError: Error {
    case couldNotSerialise
    case noValueAtKeyPath
}
