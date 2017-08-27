import XCTest
@testable import Monzo

class AccountTests: XCTestCase {
    
    func testFetchPrepaidAccounts() {
        let client = MonzoClient(publicKey: "", privateKey: "", httpClient: MockResponder())
        let user = client.createUser(accessToken: "tokenPrepaid", refreshToken: nil)
        
        let assertAccounts: (([Account]) -> Void) = { accounts in
            XCTAssertEqual(accounts.count, 2)
            
            let firstAccount = accounts.first
            XCTAssertEqual(firstAccount?.user.accessToken, "tokenPrepaid")
            XCTAssertEqual(firstAccount?.id, "account_1")
            XCTAssertEqual(firstAccount?.type, .prepaid)
            XCTAssertEqual(firstAccount?.description, "Demo Account One")
            
            let secondAccount = accounts.last
            XCTAssertEqual(secondAccount?.user.accessToken, "tokenPrepaid")
            XCTAssertEqual(secondAccount?.id, "account_2")
            XCTAssertEqual(secondAccount?.type, .prepaid)
            XCTAssertEqual(secondAccount?.description, "Demo Account Two")
        }
        
        do {
            let accountsOne = try user.accounts()
            assertAccounts(accountsOne)
            
            let accountsTwo = try user.accounts(fetchCurrentAccounts: false)
            assertAccounts(accountsTwo)
        } catch {
            XCTFail()
        }
    }
    
    func testFetchCurrentAccounts() {
        let client = MonzoClient(publicKey: "", privateKey: "", httpClient: MockResponder())
        let user = client.createUser(accessToken: "tokenCurrent", refreshToken: nil)
        
        do {
            let accounts = try user.accounts(fetchCurrentAccounts: true)
            XCTAssertEqual(accounts.count, 1)
            
            let firstAccount = accounts.first
            XCTAssertEqual(firstAccount?.user.accessToken, "tokenCurrent")
            XCTAssertEqual(firstAccount?.id, "account_3")
            XCTAssertEqual(firstAccount?.type, .current)
            XCTAssertEqual(firstAccount?.description, "Demo Current Account One")
        } catch {
            XCTFail()
        }
    }
    
    func testAccountType() {
        XCTAssertEqual(Account.AccountType(rawValue: "uk_prepaid"), .prepaid)
        XCTAssertEqual(Account.AccountType(rawValue: "uk_retail"), .current)
        XCTAssertEqual(Account.AccountType(rawValue: "this is definitely not an account"), .unknown)
    }
    
    func testFetchPrepaidAccountsRequest() {
        let responder = MockResponder()
        let client = MonzoClient(publicKey: "public", privateKey: "private", httpClient: responder)
        let user = client.createUser(accessToken: "prepaidToken", refreshToken: nil)
        
        let request = try? client.provider.createRequest(.listAccounts(user, false))
        XCTAssertEqual(request?.uri.description, "https://api.monzo.com:443/accounts")
        XCTAssertEqual(request?.headers[.authorization], "Bearer prepaidToken")
    }
    
    func testFetchCurrentAccountsRequest() {
        let responder = MockResponder()
        let client = MonzoClient(publicKey: "public", privateKey: "private", httpClient: responder)
        let user = client.createUser(accessToken: "currentToken", refreshToken: nil)
        
        let request = try? client.provider.createRequest(.listAccounts(user, true))
        XCTAssertEqual(request?.uri.description, "https://api.monzo.com:443/accounts?account_type=uk_retail")
        XCTAssertEqual(request?.headers[.authorization], "Bearer currentToken")
    }
    
    static var allTests = [
        ("testFetchPrepaidAccounts", testFetchPrepaidAccounts),
        ("testFetchCurrentAccounts", testFetchCurrentAccounts),
        ("testAccountType", testAccountType),
        ("testFetchPrepaidAccountsRequest", testFetchPrepaidAccountsRequest),
        ("testFetchCurrentAccountsRequest", testFetchCurrentAccountsRequest),
    ]
}
