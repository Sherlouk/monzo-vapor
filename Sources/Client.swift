import S4
import Foundation

public final class Client {
    let publicKey: String
    let privateKey: String
    let httpClient: Responder
    lazy var provider: Provider = { return Provider(client: self) }()
    
    public init(publicKey: String, privateKey: String, httpClient: Responder) {
        self.publicKey = publicKey
        self.privateKey = privateKey
        self.httpClient = httpClient
    }
    
    public func createUser(accessToken: String, refreshToken: String?) -> User {
        return User(client: self, accessToken: accessToken, refreshToken: refreshToken)
    }
}
