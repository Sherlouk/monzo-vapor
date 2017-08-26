import Foundation
import JSON

public struct Webhook {
    public let id: String
    public let url: URL
    let account: Account
    
    init(account: Account, id: String, url: URL) {
        self.account = account
        self.id = id
        self.url = url
    }
    
    init(account: Account, json: JSON) {
        self.account = account
        self.id = json["id"]!.string!
        self.url = json["url"]!.url!
    }
    
    /// Deletes the given webhook from the account
    ///
    /// The URL will no longer receive updates
    public func remove() throws {
        try account.removeWebhook(self)
    }
}
