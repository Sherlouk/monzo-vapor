
public final class User {
    var client: MonzoClient
    
    public var userId: String
    public var accessToken: String
    public var refreshToken: String?
    
    /// Will automatically refresh the user's access token when it expires using the refresh token.
    ///
    /// You can always use `.refreshAccessToken()` to manually refresh the token!
    public var autoRefreshToken = true
    
    /// Creates a new user with access token, and an optional refresh token
    init(client: MonzoClient, userId: String, accessToken: String, refreshToken: String?) {
        self.client = client
        self.userId = userId
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.autoRefreshToken = refreshToken != nil
    }
    
    /// Requests the users accounts. By default this will return prepaid acounts
    ///
    /// - Parameter fetchCurrentAccounts: Uses an undocumented endpoint to return current accounts instead of prepaid ones
    public func accounts(fetchCurrentAccounts: Bool = false) throws -> [Account] {
        let rawAccounts = try client.provider.requestArray(.listAccounts(self, fetchCurrentAccounts), user: self)
        return try rawAccounts.map({ try Account(user: self, json: $0) })
    }
    
    /// Queries the "Who Am I?" endpoint to validate that the access token is currently valid
    ///
    /// - Returns: Whether or not the user is currently authenticated
    public func ping() throws -> Bool {
        let rawResponse = try client.provider.request(.whoami(self), user: self)
        
        let responseUserId: String = try rawResponse.value(forKey: "user_id")
        guard responseUserId == userId else { throw MonzoAuthError.genericError }
        
        return try rawResponse.value(forKey: "authenticated")
    }
    
    /// Uses the user's refresh token to create a new access token
    public func refreshAccessToken() throws {
        guard refreshToken != nil else { throw MonzoUsageError.noRefreshToken }
        
        let rawResponse = try client.provider.request(.refreshToken(self))
        accessToken = try rawResponse.value(forKey: "access_token")
        refreshToken = try rawResponse.value(forKey: "refresh_token")
    }
}
