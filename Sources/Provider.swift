import Foundation
import Vapor
import HTTP

final class Provider {
    
    private let client: MonzoClient
    
    init(client: MonzoClient) {
        self.client = client
    }
    
    func createRequest(_ req: Requests) throws -> Request {
        let uri = URI(scheme: "https", hostname: "api.monzo.com", path: req.path, query: req.query)
        
        let request = Request(method: req.method, uri: uri)
        request.headers = req.headers
        request.body = req.body
        return request
    }
    
    func deliver(_ req: Requests, user: User? = nil, allowRefresh: Bool = true) throws {
        let request = try createRequest(req)
        let response = try client.httpClient.respond(to: request)
        
        if allowRefresh, try refreshTokenIfNeeded(response, user: user) {
            return try deliver(req, user: user, allowRefresh: false)
        }
        
        if let json = response.json, json["error"]?.string != nil, let message = json["message"]?.string {
            throw MonzoAPIError.response(message)
        }
        
        try validateResponseStatus(response.status)
    }
    
    func request(_ req: Requests, user: User? = nil, allowRefresh: Bool = true) throws -> JSON {
        let request = try createRequest(req)
        let response = try client.httpClient.respond(to: request)
        
        if allowRefresh, try refreshTokenIfNeeded(response, user: user) {
            return try self.request(req, user: user, allowRefresh: false)
        }
        
        if let json = response.json, json["error"]?.string != nil, let message = json["message"]?.string {
            throw MonzoAPIError.response(message)
        }
        
        try validateResponseStatus(response.status)
        
        guard let json = response.json else { throw MonzoJSONError.missingJSON }

        if let nestedKey = req.nestedKey {
            if let nestedJSON = json[nestedKey] {
                return nestedJSON
            }
            
            throw MonzoJSONError.missingNestedEntry(nestedKey)
        }
        
        return json
    }
    
    func requestArray(_ req: Requests, user: User? = nil) throws -> [JSON] {
        guard let json = try request(req, user: user).array else { throw MonzoJSONError.missingJSON }
        return json
    }
    
    private func validateResponseStatus(_ status: Status) throws {
        if status.statusCode == 200 {
            return
        }
        
        if let error = MonzoAPIError(statusCode: status.statusCode) {
            throw error
        }
        
        throw MonzoAPIError.other(status.statusCode, status.reasonPhrase)
    }
    
    func refreshTokenIfNeeded(_ response: Response, user: User?) throws -> Bool {
        guard let user = user, user.autoRefreshToken else { return false }
        guard user.refreshToken != nil else { return false }
        guard response.status.statusCode != 200 else { return false }
        guard response.json?["error"]?.string == "invalid_token" else { return false }
        
        try user.refreshAccessToken()
        return true
    }
}

enum Parameters {
    enum Encoder {
        case urlQuery
        case urlForm
        
        func encode(_ string: String) -> String {
            switch self {
            case .urlQuery: return string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? string
            case .urlForm:
                // https://tools.ietf.org/html/rfc3986#page-13
                // Under RFC3986 unreserved characters for form encoding include:
                // ALPHA / DIGIT / "-" / "." / "_" / "~"
                
                let allowed = CharacterSet.alphanumerics.union(.init(charactersIn: "-._~"))
                
                return string.components(separatedBy: " ").map({
                    $0.addingPercentEncoding(withAllowedCharacters: allowed) ?? $0
                }).joined(separator: "+")
            }
        }
    }
    
    case account(Account)
    case basic(String, String)
    case dictionary(String, [String: String?])
    case array(String, [String])
    
    func encoded(_ encoder: Encoder) -> String {
        switch self {
        case .account(let account):
            return encoder.encode("account_id") + "=" + encoder.encode(account.id)
        case .basic(let key, let value):
            return encoder.encode(key) + "=" + encoder.encode(value)
        case .dictionary(let key, let dictionary):
            let keyEncoded = encoder.encode(key)
            
            return dictionary.map({ (dictKey, dictValue) in
                return "\(keyEncoded)[\(encoder.encode(dictKey))]=\(encoder.encode(dictValue ?? ""))"
            }).joined(separator: "&")
        case .array(let key, let array):
            let keyEncoded = encoder.encode(key)
            
            return array.map({ (arrayValue) in
                return "\(keyEncoded)[]=\(encoder.encode(arrayValue))"
            }).joined(separator: "&")
        }
    }
}

public enum PaginationOptions {
    /// How many items to return, Maximum 100
    case limit(Int)
    
    /// A RFC3339 timestamp
    case before(String)
    
    /// Either a RFC3339 timestamp, or a transaction ID
    case since(String)
}

extension DateFormatter {
    /// Monzo Data Formatter, based on RFC3339
    @nonobjc static let rfc3339: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        return formatter
    }()
}
