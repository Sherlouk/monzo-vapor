import Foundation
import JSON

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
    
    /// Whether the transaction is a refund
    ///
    /// A transaction is treated as a refund, if the amount is positive and it's not a topup.
    /// This includes transactions such as refunds, reversals or chargebacks
    var isRefund: Bool { return amount.amount > 0 && !isLoad }
    
    let created: Date
    let settled: Date? // No Settled means authorised but not completed
    
    let notes: String
    private(set) var metadata: [String: String?]
    
    let category: String // Consider Enum?
//    let merchant: Merchant
    
    init(account: Account, json: JSON) throws {
        self.account = account
        self.declineReason = nil
        self.id = try json.value(forKey: "id")
        self.description = try json.value(forKey: "description")
        self.amount = try Amount(json.value(forKey: "amount"), currency: json.value(forKey: "currency"))
        self.isLoad = try json.value(forKey: "is_load")
        self.created = try json.value(forKey: "created")
        self.notes = try json.value(forKey: "notes")
        self.settled = try? json.value(forKey: "settled")
        self.category = try json.value(forKey: "category")
        self.metadata = [String: String?]()
        json["metadata"]?.object?.forEach {
            self.metadata[$0.key] = $0.value.string
        }
    }
    
    // MARK: Metadata
    
    mutating func setMetadata(_ value: String?, forKey key: String) throws {
        metadata.updateValue(value, forKey: key)
        try account.user.client.provider.deliver(.updateTransaction(self))
        
        if value == nil {
            metadata.removeValue(forKey: key)
        }
    }

    mutating func removeMetadata(forKey key: String) throws {
        try setMetadata(nil, forKey: key)
    }
    
    // MARK: Refresh
    
    mutating func refresh() {
        // Update all values by making a new network request for the ID (the only constant)
    }
}
