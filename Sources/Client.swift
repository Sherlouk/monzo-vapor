import S4
import Foundation

public final class Client {
    let publicKey: String
    let privateKey: String
    let httpClient: Responder
    
    public init(publicKey: String, privateKey: String, httpClient: Responder) {
        self.publicKey = publicKey
        self.privateKey = privateKey
        self.httpClient = httpClient
    }
    
    func createUser(accessToken: String, refreshToken: String?) -> User {
        return User(client: self, accessToken: accessToken, refreshToken: refreshToken)
    }
}

extension Client {
    
    typealias JSONObject = [String: Any]
    
    func makeRequest(method: S4.Method = .get, path: String) throws -> JSONObject {
        let uri = URI(scheme: "https", host: "api.monzo.com", path: path)
        let request = Request(method: method, uri: uri, version: Version(major: 1, minor: 0), headers: Headers(), body: .buffer([]))
        return try makeRequest(request)
    }
    
    private func makeRequest(_ request: Request) throws -> JSONObject {
        let response = try httpClient.respond(to: request)
        try validateResponseStatus(response.status)
        
        guard case .buffer(let data) = response.body else { throw ClientError.parsingError }
        let foundationData = Foundation.Data(bytes: data.bytes)
        let json = try JSONSerialization.jsonObject(with: foundationData, options: .init(rawValue: 0))
        
        guard let object = json as? JSONObject else { throw ClientError.parsingError }
        return object
    }
    
    private func validateResponseStatus(_ status: Status) throws {
        switch status.statusCode {
        case 200: break // OK
        case 400: throw ClientError.badRequest
        case 401: throw ClientError.unauthorised
        case 403: throw ClientError.forbidden
        case 405: throw ClientError.methodNotAllowed
        case 404: throw ClientError.notFound
        case 406: throw ClientError.notAcceptable
        case 429: throw ClientError.tooManyRequests
        case 500: throw ClientError.internalError
        case 504: throw ClientError.gatewayTimeout
        default: throw ClientError.other(status.statusCode, status.reasonPhrase)
        }
    }
    
}

protocol StringProtocol { }
extension String : StringProtocol { }
extension Dictionary where Key: StringProtocol {
    func value<T>(forKey key: Key) throws -> T {
        guard let value = self[key] as? T else { print("hmm?"); throw ClientError.parsingError }
        return value
    }
    
    func dateValue(forKey key: Key) throws -> Date {
        guard let value = self[key] as? String else { throw ClientError.parsingError }
        guard let date = DateFormatter.iso8601Formatter().date(from: value) else { throw ClientError.parsingError }
        return date
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

enum ClientError: Error {
    case badRequest // Missing Arguments or Malformed Request
    case unauthorised // User is not authenticated
    case forbidden // Request is authenticated, but doesn't have sufficient priviledges
    case methodNotAllowed // Incorrect HTTP verb, check correct usage of POST/GET/DELETE/etc
    case notFound // Endpoint requested does not exist
    case notAcceptable // Your application does not accept the content format returned according to the Accept headers sent in the request
    case tooManyRequests // Your application is exceeding its rate limit
    case internalError // Something is wrong on Monzo's end
    case gatewayTimeout // Something has timed out on Monzo's end
    case parsingError // Failed to create JSON from response
    case other(Int, String)
    
    var localizedDescription: String {
        switch self {
        case .badRequest: return "Missing Arguments or Malformed Request"
        case .unauthorised: return "User is not authenticated"
        case .forbidden: return "Request is authenticated, but doesn't have sufficient priviledges"
        case .methodNotAllowed: return "Incorrect HTTP verb, check correct usage of POST/GET/DELETE/etc"
        case .notFound: return "Endpoint requested does not exist"
        case .notAcceptable: return "Your application does not accept the content format returned according to the Accept headers sent in the request"
        case .tooManyRequests: return "Your application is exceeding its rate limit"
        case .internalError: return "Something is wrong on Monzo's end"
        case .gatewayTimeout: return "Something has timed out on Monzo's end"
        case .parsingError: return "Failed to create JSON from response"
        case .other(let code, let message): return "\(code): \(message)"
        }
    }
}
