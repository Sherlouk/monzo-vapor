import Foundation
import JSON

public struct Webhook {
    public let id: String
    public let url: URL
    let account: Account
    
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
