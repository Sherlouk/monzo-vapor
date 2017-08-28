import XCTest
@testable import Monzo

class UserTests: XCTestCase {
    
    func testInitialiser() {
        let client = MonzoClient(publicKey: "", privateKey: "", httpClient: MockResponder())
        
        let userOne = client.createUser(userId: "", accessToken: "token", refreshToken: nil)
        XCTAssertEqual(userOne.accessToken, "token")
        XCTAssertEqual(userOne.refreshToken, nil)
        XCTAssertTrue(userOne.client === client)
        
        let userTwo = client.createUser(userId: "", accessToken: "tokenTwo", refreshToken: "refresh")
        XCTAssertEqual(userTwo.accessToken, "tokenTwo")
        XCTAssertEqual(userTwo.refreshToken, "refresh")
        XCTAssertTrue(userTwo.client === client)
    }
    
    func testWhoAmI() {
        let responder = MockResponder()
        let client = MonzoClient(publicKey: "", privateKey: "", httpClient: responder)
        let userOne = client.createUser(userId: "user_id", accessToken: "token", refreshToken: nil)
        
        XCTAssertNoThrow(try userOne.ping())
        XCTAssertEqual(responder.lastRequest?.uri.description, "https://api.monzo.com:443/ping/whoami")
        XCTAssertEqual(responder.lastRequest?.headers[.authorization], "Bearer token")
    }
    
    static var allTests = [
        ("testInitialiser", testInitialiser),
        ("testWhoAmI", testWhoAmI),
    ]
}
