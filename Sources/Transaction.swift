import Foundation

public struct Transaction {
    enum DeclineReason {
        case insufficientFunds
        case cardInactive
        case cardBlocked
        case other
        case unknown(String)
    }
    
    let account: Account
    
    let declineReason: DeclineReason?
    var declined: Bool { return declineReason == nil }
    
    let id: String
    let description: String
    
    let amount: Amount
    private let isLoad: Bool
    
    /// Whether the transaction is an account topup
    var isTopup: Bool { return amount.amount > 0 && isLoad }
    
    // TODO: Update Docs
    /// Whether the transaction is a refund, or some other return
    var isRefund: Bool { return amount.amount > 0 && !isLoad }
    
    let created: Date
    let settled: Date? // No Settled means authorised but not completed
    
    let notes: String
    private(set) var metadata: [String: String]
    
    let category: String // Consider Enum?
    let merchant: String // TBD
    
    // MARK: Metadata
    
    mutating func setMetadata(_ value: String, forKey key: String) {
        metadata.updateValue(value, forKey: key)
        // Send to Monzo
    }

    mutating func removeMetadata(forKey key: String) {
        metadata.removeValue(forKey: key)
        // Send to Monzo
    }
    
    // MARK: Refresh
    
    mutating func refresh() {
        // Update all values by making a new network request for the ID (the only constant)
    }
}
