import Foundation
import Vapor
import HTTP

final class Provider {
    
    enum Requests {
        case ping
        case listAccounts(User, Bool)
        case balance(Account)
        case transactions(Account, Bool)
        case transaction(Account, String)
        case updateTransaction(Transaction)
        case webhooks(Account)
        case registerWebhook(Account, URL)
        case deleteWebhook(Webhook)
        case sendFeedItem(Account, FeedItem)
        case refreshToken(User)
        case exchangeToken(MonzoClient, URL, String)
        case whoami(User)
    }
    
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

extension Provider.Requests {
    var bearerToken: String? {
        switch self {
        case .ping, .refreshToken, .exchangeToken: return nil
        case .listAccounts(let user, _): return user.accessToken
        case .balance(let account): return account.user.accessToken
        case .transactions(let account, _): return account.user.accessToken
        case .transaction(let account, _): return account.user.accessToken
        case .updateTransaction(let transaction): return transaction.account.user.accessToken
        case .webhooks(let account): return account.user.accessToken
        case .registerWebhook(let account, _): return account.user.accessToken
        case .deleteWebhook(let webhook): return webhook.account.user.accessToken
        case .sendFeedItem(let account, _): return account.user.accessToken
        case .whoami(let user): return user.accessToken
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
        case .sendFeedItem: return "feed"
        case .refreshToken, .exchangeToken: return "oauth2/token"
        case .whoami: return "ping/whoami"
        }
    }
    
    var nestedKey: String? {
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
    
    var method: HTTP.Method {
        switch self {
        case .updateTransaction: return .patch
        case .registerWebhook: return .post
        case .deleteWebhook: return .delete
        case .sendFeedItem: return .post
        case .refreshToken, .exchangeToken: return .post
        default: return .get
        }
    }
    
    var params: [Parameters] {
        switch self {
        case .listAccounts(_, let loadCurrentAccounts):
            guard loadCurrentAccounts else { return [] }
            return [.basic("account_type", "uk_retail")]
        case .balance(let account): return [.account(account)]
        case .transactions(let account, let expandMerchant):
            var builder: [Parameters] = [
                .account(account)
            ]
            
            if expandMerchant {
                builder.append(.array("expand", ["merchant"]))
            }
            
            return builder
        case .updateTransaction(let transaction): return [.dictionary("metadata", transaction.metadata)]
        case .webhooks(let account): return [.account(account)]
        case .registerWebhook(let account, let url): return [.account(account), .basic("url", url.absoluteString)]
        case .sendFeedItem(let account, let feedItem):
            var builder: [Parameters] = [
                .account(account),
                .basic("type", feedItem.type),
                .dictionary("params", feedItem.params)
            ]
            
            if let url = feedItem.url {
                builder.append(.basic("url", url.absoluteString))
            }
            
            return builder
        case .refreshToken(let user):
            guard let refreshToken = user.refreshToken else { return [] }
            
            return [.basic("grant_type", "refresh_token"),
                    .basic("client_id", user.client.publicKey),
                    .basic("client_secret", user.client.privateKey),
                    .basic("refresh_token", refreshToken)]
        case .exchangeToken(let client, let url, let code):
            return [.basic("grant_type", "authorization_code"),
                    .basic("client_id", client.publicKey),
                    .basic("client_secret", client.privateKey),
                    .basic("redirect_uri", url.absoluteString),
                    .basic("code", code)]
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
        let empty: Body = .init("")
        guard !params.isEmpty else { return empty }
        
        switch method {
        case .post, .patch:
            let string = params.map({ $0.encoded(.urlForm) }).joined(separator: "&")
            return Body(string)
        default: return empty
        }
    }
    
    var headers: [HeaderKey: String] {
        var builder = [HeaderKey: String]()
        
        if let token = bearerToken {
            builder[.authorization] = "Bearer \(token)"
        }
        
        if method == .post || method == .patch {
            builder[.contentType] = "application/x-www-form-urlencoded; charset=utf-8"
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
