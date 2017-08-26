
/// Represents a specific amount of monies in a given currency
public struct Amount {
    // MARK: - Variables
    
    /// The amount in "minor units"
    ///
    /// Example: GBP has pence, USD/EUR has cents.
    /// *100* would be *100 pence / 1 pound* (GBP)
    public let amount: Int64

    /// The ISO 4217 currency code
    public let currency: String

    // MARK: - Initialiser
    
    init(_ amount: Int64?, currency: String?) throws {
        guard let amount = amount, let currency = currency else { throw ClientError.other(0, "Oops") }
        
        self.amount = amount
        self.currency = currency
    }
}
