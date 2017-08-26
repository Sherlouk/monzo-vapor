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
    
    func request(_ req: Requests) throws -> JSONObject {
        let jsonObject = try client.makeRequest(path: req.path, headers: requestHeaders(req))
        return jsonObject
    }
    
    func requestArray(_ req: Requests) throws -> [JSONObject] {
        guard let nestedArrayKey = req.nestedArrayKey else { throw ClientError.other(0, "Oops") }
        return try request(req)[nestedArrayKey].arrayValue
    }
    
    func requestHeaders(_ req: Requests) -> Headers {
        if let token = req.bearerToken {
            return Headers(["Authorization": "Bearer \(token)"])
        }
        
        return Headers()
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
}
