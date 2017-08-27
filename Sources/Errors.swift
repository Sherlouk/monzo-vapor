import Debugging

public enum MonzoAPIError: Error {
    case badRequest
    case unauthorised
    case forbidden
    case methodNotAllowed
    case notFound
    case notAcceptable
    case tooManyRequests
    case internalError
    case gatewayTimeout
    case other(Int, String)
    
    init?(statusCode: Int) {
        switch statusCode {
        case 400: self = .badRequest
        case 401: self = .unauthorised
        case 403: self = .forbidden
        case 405: self = .methodNotAllowed
        case 404: self = .notFound
        case 406: self = .notAcceptable
        case 429: self = .tooManyRequests
        case 500: self = .internalError
        case 504: self = .gatewayTimeout
        default: return nil
        }
    }
}

extension MonzoAPIError: Debuggable {
    public var identifier: String {
        switch self {
        case .badRequest: return "400"
        case .unauthorised: return "401"
        case .forbidden: return "403"
        case .methodNotAllowed: return "405"
        case .notFound: return "404"
        case .notAcceptable: return "406"
        case .tooManyRequests: return "429"
        case .internalError: return "500"
        case .gatewayTimeout: return "504"
        case .other(let code, _): return "\(code)"
        }
    }
    
    public var reason: String {
        switch self {
        case .badRequest: return "Your request has missing arguments or is malformed."
        case .unauthorised: return "Your request is not authenticated."
        case .forbidden: return "Your request is authenticated but has insufficient permissions."
        case .methodNotAllowed: return "You are using an incorrect HTTP verb. Double check whether it should be POST/GET/DELETE/etc."
        case .notFound: return "The endpoint requested does not exist."
        case .notAcceptable: return "Your application does not accept the content format returned according to the Accept headers sent in the request."
        case .tooManyRequests: return "Your application is exceeding its rate limit"
        case .internalError: return "Something is wrong on Monzo's end"
        case .gatewayTimeout: return "Something has timed out on Monzo's end"
        case .other(_, let message): return message
        }
    }
    
    public var suggestedFixes: [String] {
        switch self {
        case .badRequest, .forbidden, .methodNotAllowed, .notFound, .notAcceptable:
            return ["Raise a bug here: https://github.com/Sherlouk/monzo-vapor/issues/new"]
        case .unauthorised: return ["If you have a refresh token, then refresh the access token", "Send the user to get authenticated again"]
        case .tooManyRequests: return ["Take a break from sending requests to the Monzo API"]
        case .internalError, .gatewayTimeout: return ["Try again later"]
        default: return []
        }
    }
    
    public var possibleCauses: [String] {
        switch self {
        case .badRequest, .forbidden, .methodNotAllowed, .notFound, .notAcceptable:
            return ["Something went wrong creating the request for Monzo"]
        case .unauthorised: return ["The user's access token has expired"]
        case .tooManyRequests: return ["You have requested too many things from the Monzo API"]
        case .internalError, .gatewayTimeout: return ["Something went wrong on Monzo's side"]
        default: return []
        }
    }
}

public enum MonzoJSONError: Error {
    case unsupportedType(String)
    case missingKey(String)
    case missingJSON
    case missingNestedEntry(String)
}

extension MonzoJSONError: Debuggable {
    
    public var identifier: String {
        switch self {
        case .unsupportedType: return "unsupportedType"
        case .missingKey: return "missingKey"
        case .missingJSON: return "missingJSON"
        case .missingNestedEntry: return "missingNestedEntry"
        }
    }
    
    public var reason: String {
        switch self {
        case .unsupportedType(let typeName): return "Tried to get value for unsupported type: \(typeName)"
        case .missingKey(let key): return "Tried to get value for non-existing key: \(key)"
        case .missingJSON: return "Response returned missing or malformed JSON"
        case .missingNestedEntry(let key): return "Expected nested array with key: \(key)"
        }
    }
    
    public var suggestedFixes: [String] {
        return ["Raise a bug here: https://github.com/Sherlouk/monzo-vapor/issues/new"]
    }
    
    public var possibleCauses: [String] {
        return []
    }
}

public enum MonzoUsageError: Error {
    case noRefreshToken
    case invalidFeedItem
}

extension MonzoUsageError: Debuggable {
    public var identifier: String {
        switch self {
        case .noRefreshToken: return "noRefreshToken"
        case .invalidFeedItem: return "invalidFeedItem"
        }
    }
    
    public var reason: String {
        switch self {
        case .noRefreshToken: return "Tried to refresh the access token with no refresh token!"
        case .invalidFeedItem: return "Feed Item was invalid"
        }
    }
    
    public var suggestedFixes: [String] {
        switch self {
        case .noRefreshToken: return ["Provide a refresh token", "Don't attempt to refresh the access token"]
        case .invalidFeedItem: return ["Ensure all necessary values are there"]
        }
    }
    
    public var possibleCauses: [String] {
        switch self {
        case .noRefreshToken: return ["\"refreshAccessToken\" was called with no refresh token"]
        case .invalidFeedItem: return ["Your feed item title is likely an empty string"]
        }
    }
}
