
public final class User {
    var client: MonzoClient
    
    // Authorisation
    let accessToken: String
    let refreshToken: String?
    
    // Initaliser
    init(client: MonzoClient, accessToken: String, refreshToken: String?) {
        self.client = client
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
    
    public func accounts(fetchCurrentAccounts: Bool = false) throws -> [Account] {
        let rawAccounts = try client.provider.requestArray(.listAccounts(self, fetchCurrentAccounts))
        return try rawAccounts.map({ try Account(user: self, json: $0) })
    }
}
