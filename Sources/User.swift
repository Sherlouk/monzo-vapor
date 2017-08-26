
public final class User {
    var client: Client
    
    // Authorisation
    let accessToken: String
    let refreshToken: String?
    
    // Initaliser
    internal init(client: Client, accessToken: String, refreshToken: String?) {
        self.client = client
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
    
    func accounts() throws -> [Account] {
        // Current API (by default) returns prepaid accounts, should also add a way to find current accounts
        let rawAccounts = try client.provider.requestArray(.listAccounts(self))
        return try rawAccounts.map({ try Account(user: self, json: $0) })
    }
}
