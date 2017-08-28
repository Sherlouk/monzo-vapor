import XCTest
@testable import Monzo

class AmountTests: XCTestCase {
    
    func testInitialiser() {
        let amount = Amount(100, currency: "GBP")
        XCTAssertEqual(amount.amount, 100)
        XCTAssertEqual(amount.currency, "GBP")
    }
    
    func testDescription() {
        let amount = Amount(100, currency: "GBP")
        XCTAssertEqual(amount.debugDescription, "Amount(100 GBP)")
    }
    
    func testAccountBalanceResponse() {
        let client = MonzoClient(publicKey: "", privateKey: "", httpClient: MockResponder())
        let user = client.createUser(userId: "", accessToken: "", refreshToken: nil)
        guard let account = (try? user.accounts())?.first else { XCTFail(); return }
        guard let amount = try? account.balance() else { XCTFail(); return }
        
        XCTAssertEqual(amount.amount, 90000)
        XCTAssertEqual(amount.currency, "USD")
    }
    
    func testAccountBalanceRequest() {
        let client = MonzoClient(publicKey: "", privateKey: "", httpClient: MockResponder())
        let user = client.createUser(userId: "", accessToken: "balanceToken", refreshToken: nil)
        guard let account = (try? user.accounts())?.first else { XCTFail(); return }
        
        let request = try? client.provider.createRequest(.balance(account))
        XCTAssertEqual(request?.uri.description, "https://api.monzo.com:443/balance?account_id=account_1")
        XCTAssertEqual(request?.headers[.authorization], "Bearer balanceToken")
    }
    
    func testAccountSpentTodayResponse() {
        let client = MonzoClient(publicKey: "", privateKey: "", httpClient: MockResponder())
        let user = client.createUser(userId: "", accessToken: "", refreshToken: nil)
        guard let account = (try? user.accounts())?.first else { XCTFail(); return }
        guard let amount = try? account.spentToday() else { XCTFail(); return }
        
        XCTAssertEqual(amount.amount, -200)
        XCTAssertEqual(amount.currency, "USD")
    }
    
    static var allTests = [
        ("testInitialiser", testInitialiser),
        ("testDescription", testDescription),
        ("testAccountBalanceResponse", testAccountBalanceResponse),
        ("testAccountBalanceRequest", testAccountBalanceRequest),
        ("testAccountSpentTodayResponse", testAccountSpentTodayResponse),
    ]
}
