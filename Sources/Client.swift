
public final class Client {
    let publicKey: String
    let privateKey: String
    
    init(publicKey: String, privateKey: String) {
        self.publicKey = publicKey
        self.privateKey = privateKey
    }
    
    func createUser(accessToken: String, refreshToken: String?) -> User {
        return User(client: self, accessToken: accessToken, refreshToken: refreshToken)
    }
}
