import Foundation
import Vapor

public final class MonzoClient {
    let publicKey: String
    let privateKey: String
    let httpClient: Responder
    lazy var provider: Provider = { return Provider(client: self) }()

    // Leaving this code as something that should be investigated! Getting errors with Vapor though.
//    public convenience init(publicKey: String, privateKey: String, clientFactory: ClientFactoryProtocol) {
//        let responder: Responder = {
//            // Attempt to re-use the same client (better performance)
//            if let port = URI.defaultPorts["https"],
//                let client = try? clientFactory.makeClient(hostname: "api.monzo.com", port: port, securityLayer: .none) {
//                return client
//            }
//            
//            // Default Implementation (Will create a new client for every request)
//            return clientFactory
//        }()
//        
//        self.init(publicKey: publicKey, privateKey: privateKey, httpClient: responder)
//    }
    
    public init(publicKey: String, privateKey: String, httpClient: Responder) {
        self.publicKey = publicKey
        self.privateKey = privateKey
        self.httpClient = httpClient
        
        Monzo.setup()
    }
    
    /// Creates a new user with the provided access token required for authenticating all requests
    public func createUser(userId: String, accessToken: String, refreshToken: String?) -> User {
        return User(client: self, userId: userId, accessToken: accessToken, refreshToken: refreshToken)
    }
    
    /// Pings the Monzo API and returns true if a valid response was fired back
    public func ping() -> Bool {
        let response: String? = try? provider.request(.ping).value(forKey: "ping")
        return response == "pong"
    }
    
    /// Creates a URI to Monzo's authorisation page, you should redirect users to it in order to authorise usage of their accounts
    ///
    /// - Parameters:
    ///   - redirectUrl: The URL that Monzo will redirect the user back to, where you should validate and obtain the access token
    ///   - nonce: An unguessable/random string to prevent against CSRF attacks. Optional, but **recommended**!
    /// - Returns: The URI to redirect users to
    public func authorizationURI(redirectUrl: URL, nonce: String?) -> URI {
        var parameters: [Parameters] = [
            .basic("client_id", publicKey),
            .basic("redirect_uri", redirectUrl.absoluteString),
            .basic("response_type", "code")
        ]
        
        if let nonce = nonce { parameters.append(.basic("code", nonce)) }
        let query = parameters.map({ $0.encoded(.urlQuery) }).joined(separator: "&")
        
        return URI(scheme: "https", hostname: "auth.getmondo.co.uk", query: query)
    }
    
    /// Validates the user has successfully authorised your client and is capable of making requests
    ///
    /// - Parameters:
    ///   - req: The request when the user was redirected back to your server
    ///   - nonce: The nonce used when redirecting the user to Monzo
    /// - Returns: On success, returns an authenticated user object for further requests
    public func authenticateUser(_ req: Request, nonce: String?) throws -> User {
        guard let code = req.query?["code"]?.string,
              let state = req.query?["state"]?.string else { throw MonzoAuthError.missingParameters }
        
        guard state == nonce ?? "" else { throw MonzoAuthError.conflictedNonce }
        
        var uri = req.uri
        uri.query = nil // Remove the query to just get the base URL for comparison
        
        let url = try uri.makeFoundationURL()
        let response = try provider.request(.exchangeToken(self, url, code))
        
        let userId: String = try response.value(forKey: "user_id")
        let accessToken: String = try response.value(forKey: "access_token")
        let refreshToken: String? = try? response.value(forKey: "refresh_token")
        return createUser(userId: userId, accessToken: accessToken, refreshToken: refreshToken)
    }
}

final class Monzo {
    static func setup() {
        Date.incomingDateFormatters.insert(.rfc3339, at: 0)
    }
}
