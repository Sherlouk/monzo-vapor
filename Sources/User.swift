
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
    
    func accounts() -> [Account] {
        // Current API (by default) returns prepaid accounts, should also add a way to find current accounts
        return []
    }
}
