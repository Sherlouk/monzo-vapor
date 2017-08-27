import XCTest
@testable import Monzo

class UserTests: XCTestCase {
    
    func testInitialiser() {
        let client = MonzoClient(publicKey: "", privateKey: "", httpClient: MockResponder())
        
        let userOne = client.createUser(accessToken: "token", refreshToken: nil)
        XCTAssertEqual(userOne.accessToken, "token")
        XCTAssertEqual(userOne.refreshToken, nil)
        XCTAssertTrue(userOne.client === client)
        
        let userTwo = client.createUser(accessToken: "tokenTwo", refreshToken: "refresh")
        XCTAssertEqual(userTwo.accessToken, "tokenTwo")
        XCTAssertEqual(userTwo.refreshToken, "refresh")
        XCTAssertTrue(userTwo.client === client)
    }
    
    static var allTests = [
        ("testInitialiser", testInitialiser),
    ]
}