import S4
import Foundation

final class Provider {
    
    enum Requests {
        case ping
        case listAccounts(User)
        case balance(Account)
        case transactions(Account)
        case transaction(Account, String)
        case updateTransaction(Transaction)
        case webhooks(Account)
        case registerWebhook(Account, URL)
        case deleteWebhook(Webhook)
        case createFeedItem(Account, String) // WIP
    }
    
    let client: Client
    
    init(client: Client) {
        self.client = client
    }
    
    func createRequest(_ req: Requests) throws -> Request {
        let uri = URI(scheme: "https", host: "api.monzo.com", path: req.path, query: req.query)
        let version = Version(major: 1, minor: 0)
        
        return Request(method: req.method, uri: uri, version: version, headers: req.headers, body: req.body)
    }
    
    func request(_ req: Requests) throws -> JSONObject {
        let request = try createRequest(req)
        let response = try client.httpClient.respond(to: request)

        try validateResponseStatus(response.status)
        
        guard case .buffer(let data) = response.body else { throw ClientError.parsingError }
        let foundationData = Foundation.Data(bytes: data.bytes)
        return try JSONObject(data: foundationData)
    }
    
    func requestArray(_ req: Requests) throws -> [JSONObject] {
        guard let nestedArrayKey = req.nestedArrayKey else { throw ClientError.other(0, "Oops") }
        return try request(req)[nestedArrayKey].arrayValue
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

extension Provider.Requests {
    var bearerToken: String? {
        switch self {
        case .ping: return nil
        case .listAccounts(let user): return user.accessToken
        case .balance(let account): return account.user.accessToken
        case .transactions(let account): return account.user.accessToken
        case .transaction(let account, _): return account.user.accessToken
        case .updateTransaction(let transaction): return transaction.account.user.accessToken
        case .webhooks(let account): return account.user.accessToken
        case .registerWebhook(let account, _): return account.user.accessToken
        case .deleteWebhook(let webhook): return webhook.account.user.accessToken
        case .createFeedItem(let account, _): return account.user.accessToken
        }
    }
    
    var path: String {
        switch self {
        case .ping: return "ping"
        case .listAccounts: return "accounts"
        case .balance: return "balance"
        case .transactions: return "transactions"
        case .transaction(_, let id): return "transactions/\(id)"
        case .updateTransaction(let transaction): return "transactions/\(transaction.id)"
        case .webhooks: return "webhooks"
        case .registerWebhook: return "webhooks"
        case .deleteWebhook(let webhook): return "webhooks/\(webhook.id)"
        case .createFeedItem: return "feed"
        }
    }
    
    var nestedArrayKey: String? {
        switch self {
        case .listAccounts: return "accounts"
        case .transactions: return "transactions"
        case .transaction: return "transaction"
        case .updateTransaction: return "transaction"
        case .webhooks: return "webhooks"
        case .registerWebhook: return "webhook"
        default: return nil
        }
    }
    
    var method: S4.Method {
        switch self {
        case .updateTransaction: return .patch
        case .registerWebhook: return .post
        case .deleteWebhook: return .delete
        case .createFeedItem: return .post
        default: return .get
        }
    }
    
    var params: [Parameters] {
        switch self {
        case .balance(let account): return [.account(account)]
        case .transactions(let account): return [.account(account)]
        case .updateTransaction(let transaction): return [.dictionary("metadata", transaction.metadata)]
        case .webhooks(let account): return [.account(account)]
        case .registerWebhook(let account, let url): return [.account(account), .basic("url", url.absoluteString)]
        case .createFeedItem: return [.basic("WIP", "")]
        default: return []
        }
    }
    
    var query: String? {
        switch method {
        case .get where !params.isEmpty: return params.map({ $0.encoded(.urlQuery) }).joined(separator: "&")
        default: return nil
        }
    }
    
    var body: Body {
        let empty: Body = .buffer([])
        guard !params.isEmpty else { return empty }
        
        switch method {
        case .post, .patch:
            let string = params.map({ $0.encoded(.urlForm) }).joined(separator: "&")
            guard let data = string.data(using: .utf8, allowLossyConversion: true) else { return empty }
            return .buffer(S4.Data(data))
        default: return empty
        }
    }
    
    var headers: Headers {
        var builder = Headers()
        
        if let token = bearerToken {
            builder["Authorization"] = "Bearer \(token)"
        }
        
        return builder
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
