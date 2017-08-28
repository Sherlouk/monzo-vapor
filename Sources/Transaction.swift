import Foundation
import JSON

public final class Transaction {
    public enum DeclineReason: CustomStringConvertible {
        case insufficientFunds
        case cardInactive
        case cardBlocked
        case other
        case unknown(String) // Future Proofing
        
        init?(rawValue: String?) {
            guard let rawValue = rawValue else { return nil }
            
            switch rawValue {
            case "INSUFFICIENT_FUNDS": self = .insufficientFunds
            case "CARD_INACTIVE": self = .cardInactive
            case "CARD_BLOCKED": self = .cardBlocked
            case "OTHER": self = .other
            default: self = .unknown(rawValue)
            }
        }
        
        public var description: String {
            switch self {
            case .insufficientFunds: return "INSUFFICIENT_FUNDS"
            case .cardInactive: return "CARD_INACTIVE"
            case .cardBlocked: return "CARD_BLOCKED"
            case .other: return "OTHER"
            case .unknown(let string): return string
            }
        }
    }
    
    public enum Category: CustomStringConvertible {
        case monzo // Topups
        case general
        case eatingOut
        case expenses
        case transport
        case cash
        case bills
        case entertainment
        case shopping
        case holidays
        case groceries
        case other(String) // Future Proofing
        
        init(rawValue: String) {
            switch rawValue {
                case "monzo", "mondo": self = .monzo
                case "general": self = .general
                case "eating_out": self = .eatingOut
                case "expenses": self = .expenses
                case "transport": self = .transport
                case "cash": self = .cash
                case "bills": self = .bills
                case "entertainment": self = .entertainment
                case "shopping": self = .shopping
                case "holidays": self = .holidays
                case "groceries": self = .groceries
                default: self = .other(rawValue)
            }
        }
        
        public var description: String {
            switch self {
            case .monzo: return "mondo"
            case .general: return "general"
            case .eatingOut: return "eating_out"
            case .expenses: return "expenses"
            case .transport: return "transport"
            case .cash: return "cash"
            case .bills: return "bills"
            case .entertainment: return "entertainment"
            case .shopping: return "shopping"
            case .holidays: return "holidays"
            case .groceries: return "groceries"
            case .other(let string): return string
            }
        }
    }
    
    let account: Account
    
    public let id: String
    public let description: String
    
    /// How much the transaction was for, this will often be a negative value for monies spent
    public let amount: Amount
    
    private let isLoad: Bool
    
    /// Whether the transaction is an account topup
    public var isTopup: Bool { return amount.amount > 0 && isLoad }
    
    /// Whether the transaction is a refund
    ///
    /// A transaction is treated as a refund, if the amount is positive and it's not a topup.
    /// This includes transactions such as refunds, reversals or chargebacks
    public var isRefund: Bool { return amount.amount > 0 && !isLoad }
    
    /// Why, if at all, the transaction was declined
    public let declineReason: DeclineReason?
    
    /// Whether or not the transaction was declined. See `declineReason`.
    public var declined: Bool { return declineReason != nil }
    
    /// When the transaction was first created
    public let created: Date
    
    /// When the transaction was settled.
    ///
    /// If nil, the transaction has been authorised but not completed
    public let settled: Date?
    
    /// User defined notes on the transaction
    public let notes: String
    
    /// Metadata is per-client and will not be shared with other clients
    private(set) public var metadata: [String: String?]
    
    /// Category for this transaction
    public let category: Category
    
    /// The ID of the merchant, fallback if merchant info isn't expanded
    public let merchantId: String?
    
    /// Information about the merchant
    ///
    /// Will only be available if opted in when requesting transactions
    public let merchant: Merchant?
    
    init(account: Account, json: JSON) throws {
        self.account = account
        self.declineReason = DeclineReason(rawValue: try? json.value(forKey: "decline_reason"))
        self.id = try json.value(forKey: "id")
        self.description = try json.value(forKey: "description")
        self.amount = try Amount(json.value(forKey: "amount"), currency: json.value(forKey: "currency"))
        self.isLoad = try json.value(forKey: "is_load")
        self.created = try json.value(forKey: "created")
        self.notes = try json.value(forKey: "notes")
        self.settled = try? json.value(forKey: "settled")
        self.category = .init(rawValue: try json.value(forKey: "category"))
        
        if let merchant = json["merchant"]?.string {
            self.merchantId = merchant
            self.merchant = nil
        } else if let merchant: Merchant = try? Merchant(json: json["merchant"]) {
            self.merchantId = merchant.id
            self.merchant = merchant
        } else {
            self.merchantId = nil
            self.merchant = nil
        }
        
        self.metadata = [String: String?]()
        json["metadata"]?.object?.forEach {
            self.metadata[$0.key] = $0.value.string
        }
    }
    
    // MARK: - Metadata
    
    /// Add an annotation on this key, if the value is nil then the key will be removed
    public func setMetadata(_ value: String?, forKey key: String) throws {
        metadata.updateValue(value, forKey: key)
        try account.user.client.provider.deliver(.updateTransaction(self), user: account.user)
        
        if value == nil {
            metadata.removeValue(forKey: key)
        }
    }

    /// Remove an annotation on this transaction
    public func removeMetadata(forKey key: String) throws {
        try setMetadata(nil, forKey: key)
    }
    
    // MARK: - Refresh
    
    func refresh() {
        // Update all values by making a new network request for the ID (the only constant)
//        let rawTransaction = try account.user.client.provider.request(.transaction(account, id))
    }
}

extension Transaction: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "Transaction(\(id))"
    }
}

extension Array where Element: Transaction {
    
    mutating func loadMore(merchantInfo: Bool = true, limit: Int? = nil) throws -> Bool {
        let transactions = sorted(by: { $0.created.timeIntervalSince1970 < $1.created.timeIntervalSince1970 })
        guard let latest = transactions.last else { return false }
        
        var options: [PaginationOptions] = [
            .since(latest.id)
        ]
        
        if let limit = limit {
            options.append(.limit(limit))
        }
        
        let newTransactions = try latest.account.transactions(merchantInfo: merchantInfo, options: options)
        guard let elements = newTransactions as? [Element], newTransactions.count > 0 else { return false }
        
        append(contentsOf: elements)
        return true
    }
    
}
