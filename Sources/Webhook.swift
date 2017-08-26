import Foundation

public struct Webhook {
    let id: String
    let url: URL
    internal let account: Account
    
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
    func remove() throws {
        try account.removeWebhook(self)
    }
}
