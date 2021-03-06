import Foundation
import JSON

public final class Account {
    public enum AccountType {
        /// Monzo Prepaid Account
        case prepaid
        
        /// Monzo Current Account
        case current
        
        /// Unknown Account
        case unknown
        
        init(rawValue: String) {
            switch rawValue {
            case "uk_prepaid": self = .prepaid
            case "uk_retail": self = .current
            default: self = .unknown
            }
        }
    }
    
    // MARK: Variables
    
    /// The user the account belongs to
    let user: User
    
    /// The type of account (e.g. prepaid or current account)
    public let type: AccountType
    
    /// The account's unique identifier
    public let id: String
    
    /// The account's description
    public let description: String
    
    /// The date in which the account was created
    public let created: Date
    
    /// Private storage of webhooks
    private var _webhooks = [Webhook]()
    
    /// Whether or not webhooks been loaded from the API
    private var webhooksLoaded = false
    
    /// List of current webhooks on the account
    public var webhooks: [Webhook] {
        if !webhooksLoaded {
            do {
                try loadWebhooks()
                webhooksLoaded = true
            } catch {}
        }
        
        return _webhooks
    }
    
    // MARK: Initialiser
    
    init(user: User, json: JSON) throws {
        self.user = user
        self.type = AccountType(rawValue: try json.value(forKey: "type"))
        self.id = try json.value(forKey: "id")
        self.description = try json.value(forKey: "description")
        self.created = try json.value(forKey: "created")
    }
    
    // MARK: Transactions
    
    public func transactions(merchantInfo: Bool = true, options: [PaginationOptions] = []) throws -> [Transaction] {
        let rawTransactions = try user.client.provider.requestArray(.transactions(self, merchantInfo, options), user: user)
        return try rawTransactions.map({ try Transaction(account: self, json: $0) })
    }
    
    // MARK: Balance
    
    /// The current available balance of the account
    public func balance() throws -> Amount {
        let rawBalance = try user.client.provider.request(.balance(self), user: user)
        return try Amount(rawBalance.value(forKey: "balance"), currency: rawBalance.value(forKey: "currency"))
    }
    
    /// The amount the account has spent today (Considered from approx. 4am onwards)
    public func spentToday() throws -> Amount {
        let rawBalance = try user.client.provider.request(.balance(self), user: user)
        return try Amount(rawBalance.value(forKey: "spend_today"), currency: rawBalance.value(forKey: "currency"))
    }
    
    // MARK: Webhook
    
    private func loadWebhooks() throws {
        let rawWebhooks = try user.client.provider.requestArray(.webhooks(self), user: user)
        _webhooks = try rawWebhooks.map({ try Webhook(account: self, json: $0) })
    }
    
    public func addWebhook(url: URL) throws {
        let rawWebhook = try user.client.provider.request(.registerWebhook(self, url), user: user)
        let webhook = try Webhook(account: self, json: rawWebhook)
        _webhooks.append(webhook)
    }
    
    public func removeWebhook(_ webhook: Webhook) throws {
        try user.client.provider.deliver(.deleteWebhook(webhook), user: user)
        guard let index = _webhooks.index(where: { $0.id == webhook.id }) else { return }
        _webhooks.remove(at: index)
    }
    
    // MARK: Feed Item
    
    public func sendFeedItem(_ feedItem: BasicFeedItem) throws {
        try feedItem.validate()
        try user.client.provider.deliver(.sendFeedItem(self, feedItem), user: user)
    }
}
