import Foundation

public struct Webhook {
    public let id: String
    public let url: URL
    let account: Account
    
    init(account: Account, id: String, url: URL) {
        self.account = account
        self.id = id
        self.url = url
    }
    
    init(account: Account, json: JSONObject) {
        self.account = account
        self.id = json["id"].stringValue
        self.url = json["url"].urlValue
    }
    
    /// Deletes the given webhook from the account
    ///
    /// The URL will no longer receive updates
    public func remove() throws {
        try account.removeWebhook(self)
    }
}
