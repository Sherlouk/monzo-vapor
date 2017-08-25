
/// Represents a given amount of monies in a specific currency
public struct Amount {
    // MARK: Variables
    
    /// The amount in "minor units"
    ///
    /// Example: GBP has pence, USD/EUR has cents.
    /// *100* would be *1 pound* (GBP)
    let amount: Int64

    /// The ISO 4217 currency code
    let currency: String

    // MARK: Initialiser
    
    init(_ amount: Int64, currency: String) {
        self.amount = amount
        self.currency = currency
    }
}
