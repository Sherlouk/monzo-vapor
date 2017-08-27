import Foundation
import JSON

public struct Webhook {
    let account: Account
    
    /// The ID of the webhook
    public let id: String
    
    /// Where webhook events will be sent to
    public let url: URL
    
    init(account: Account, json: JSON) throws {
        self.account = account
        self.id = try json.value(forKey: "id")
        self.url = try json.value(forKey: "url")
    }
    
    /// Deletes the given webhook from the account
    ///
    /// The URL will no longer receive updates
    public func remove() throws {
        try account.removeWebhook(self)
    }
}

extension Webhook: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "Webhook(\(id): \(url.absoluteString))"
    }
}
