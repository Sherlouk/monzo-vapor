import Foundation
import Vapor

public final class MonzoClient {
    let publicKey: String
    let privateKey: String
    let httpClient: Responder
    lazy var provider: Provider = { return Provider(client: self) }()
    
    public init(publicKey: String, privateKey: String, httpClient: Responder) {
        self.publicKey = publicKey
        self.privateKey = privateKey
        self.httpClient = httpClient
        
        Monzo.setup()
    }
    
    /// Creates a new user with the provided access token required for authenticating all requests
    public func createUser(accessToken: String, refreshToken: String?) -> User {
        return User(client: self, accessToken: accessToken, refreshToken: refreshToken)
    }
    
    /// Pings the Monzo API and returns true if a valid response was fired back
    public func ping() -> Bool {
        let response: String? = try? provider.request(.ping).value(forKey: "ping")
        return response == "pong"
    }
}

final class Monzo {
    static func setup() {
        Date.incomingDateFormatters.insert(.monzoiso8601, at: 0)
    }
}
