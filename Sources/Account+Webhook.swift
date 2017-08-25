import Foundation

public struct Webhook {
    let id: String
    let url: URL
    internal let account: Account
    
    /// Deletes the given webhook from the account
    ///
    /// The URL will no longer receive updates
    func remove() {
        account.removeWebhook(self)
    }
}
