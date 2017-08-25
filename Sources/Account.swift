import Foundation

public final class Account {
    public enum `Type` {
        /// Monzo Prepaid Account
        case prepaid
        
        /// Monzo Current Account
        case current
        
        /// Unknown Account
        case unknown
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
    
    // MARK: Initialiser
    
    internal init(user: User, type: Type, id: String, description: String, created: Date) {
        self.user = user
        self.type = type
        self.id = id
        self.description = description
        self.created = created
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
    }
}
