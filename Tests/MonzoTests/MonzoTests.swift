import XCTest
import S4
@testable import Monzo

class MonzoTests: XCTestCase {
    func testExample() {
        let responder = MockResponder()
        let client = Monzo.Client(publicKey: "", privateKey: "", httpClient: responder)
        let user = client.createUser(accessToken: "", refreshToken: nil)
        
        do {
            let accounts = try user.accounts()
            XCTAssertEqual(accounts.count, 2)
            XCTAssertEqual(accounts.first?.id, "acc_00009237aqC8c5umZmrRdh")
            XCTAssertEqual(accounts.first?.type, .prepaid)
            XCTAssertEqual(accounts.first?.description, "Peter Pan's Account")
            
            XCTAssertEqual(accounts.last?.id, "acc_00009237aqC8c5umZmrRdi")
            XCTAssertEqual(accounts.last?.type, .current)
            XCTAssertEqual(accounts.last?.description, "Peter Pan's Current Account")
        } catch(let error) {
            XCTFail(error.localizedDescription)
        }
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
