import Foundation

public final class Account {
    public enum `Type` {
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
    let type: Type
    
    /// The account's unique identifier
    let id: String
    
    /// The account's description
    let description: String
    
    /// The date in which the account was created
    let created: Date
    
    /// Private storage of webhooks
    private var _webhooks = [Webhook]()
    
    /// Whether or not webhooks been loaded from the API
    private var webhooksLoaded = false
    
    /// List of current webhooks on the account
    var webhooks: [Webhook] {
        if !webhooksLoaded {
            loadWebhooks()
        }
        
        return _webhooks
    }
    
    // MARK: Initialiser
    
    init(user: User, type: Type, id: String, description: String, created: Date) {
        self.user = user
        self.type = type
        self.id = id
        self.description = description
        self.created = created
    }
    
    init(user: User, json: JSONObject) throws {
        self.user = user
        self.type = Type(rawValue: json["type"].stringValue)
        self.id = json["id"].stringValue
        self.description = json["description"].stringValue
        self.created = json["created"].iso8601Value
    }
    
    // MARK: Transactions
    
    func transactions(limit: Int = 10) -> [Transaction] {
        return []
    }
    
    // MARK: Balance
    
    /// The current available balance of the account
    func balance() -> Amount {
        return Amount(0, currency: "GBP")
    }
    
    /// The amount the account has spent today (Considered from approx. 4am onwards)
    func spentToday() -> Amount {
        return Amount(0, currency: "GBP")
    }
    
    // MARK: Refresh
    
    func refresh() {
        // Reload cached values from Monzo API
        // TBD?
    }
    
    // MARK: Webhook
    
    func loadWebhooks() {
        // Fetch from Monzo
        // Update webhooks array
    }
    
    func addWebhook(url: URL) {
        // Update with Monzo
        // Update webhook array
    }
    
    func removeWebhook(_ webhook: Webhook) {
        // Remove with Monzo
        // Update webhook array
    }
}
