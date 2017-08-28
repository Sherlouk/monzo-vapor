import Foundation
import HTTP

enum Requests {
    case ping
    
    case whoami(User)
    
    case listAccounts(User, Bool)
    case balance(Account)
    
    case transactions(Account, Bool, [PaginationOptions])
    case transaction(Account, String)
    case updateTransaction(Transaction)
    
    case webhooks(Account)
    case registerWebhook(Account, URL)
    case deleteWebhook(Webhook)
    
    case sendFeedItem(Account, FeedItem)
    
    case refreshToken(User)
    case exchangeToken(MonzoClient, URL, String)
    
    case registerAttachment(Transaction, URL)
    case deregisterAttachment(Attachment)
}

extension Requests {
    var bearerToken: String? {
        switch self {
        case .ping, .refreshToken, .exchangeToken: return nil
        case .listAccounts(let user, _): return user.accessToken
        case .balance(let account): return account.user.accessToken
        case .transactions(let account, _, _): return account.user.accessToken
        case .transaction(let account, _): return account.user.accessToken
        case .updateTransaction(let transaction): return transaction.account.user.accessToken
        case .webhooks(let account): return account.user.accessToken
        case .registerWebhook(let account, _): return account.user.accessToken
        case .deleteWebhook(let webhook): return webhook.account.user.accessToken
        case .sendFeedItem(let account, _): return account.user.accessToken
        case .whoami(let user): return user.accessToken
        case .registerAttachment(let transaction, _): return transaction.account.user.accessToken
        case .deregisterAttachment(let attachment): return attachment.transaction.account.user.accessToken
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
        case .registerAttachment: return "attachment/register"
        case .deregisterAttachment: return "attachment/deregister"
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
        case .registerAttachment: return "attachment"
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
        case .registerAttachment, .deregisterAttachment: return .post
        default: return .get
        }
    }
    
    var params: [Parameters] {
        switch self {
        case .listAccounts(_, let loadCurrentAccounts):
            guard loadCurrentAccounts else { return [] }
            return [.basic("account_type", "uk_retail")]
        case .balance(let account): return [.account(account)]
        case .transactions(let account, let expandMerchant, let options):
            var builder: [Parameters] = [
                .account(account)
            ]
            
            if expandMerchant {
                builder.append(.array("expand", ["merchant"]))
            }
            
            var existing = [String]()
            options.forEach {
                switch $0 {
                case .before(let string):
                    guard !existing.contains("before") else { return }
                    existing.append("before")
                    builder.append(.basic("before", string))
                case .since(let string):
                    guard !existing.contains("since") else { return }
                    existing.append("since")
                    builder.append(.basic("since", string))
                case .limit(let count):
                    guard !existing.contains("limit") else { return }
                    existing.append("limit")
                    builder.append(.basic("limit", "\(count)"))
                }
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
        case .registerAttachment(let transaction, let url):
            let filePath = url.absoluteString
            let fileType: String? = {
                if let fileExtension = filePath.components(separatedBy: ".").last {
                    return Request.mediaTypes[fileExtension]
                }
                
                return nil
            }()
            
            return [.basic("external_id", transaction.id),
                    .basic("file_url", filePath),
                    .basic("file_type", fileType ?? "image/png")]
        case .deregisterAttachment(let attachment):
            return [.basic("id", attachment.id)]
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
