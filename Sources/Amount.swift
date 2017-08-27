
/// Represents a specific amount of monies in a given currency
public struct Amount {
    // MARK: - Variables
    
    /// The amount in "minor units"
    ///
    /// Example: GBP has pence, USD/EUR has cents.
    /// *100* would be *100 pence / 1 pound* (GBP)
    public let amount: Int

    /// The ISO 4217 currency code
    public let currency: String

    // MARK: - Initialiser
    
    init(_ amount: Int, currency: String) {
        self.amount = amount
        self.currency = currency
    }
}

extension Amount: CustomStringConvertible {
    public var description: String {
        return "\(amount) \(currency)"
    }
}
