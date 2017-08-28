import XCTest
@testable import Monzo

class WebhookTests: XCTestCase {
    
    func testListWebhooks() {
        let client = MonzoClient(publicKey: "", privateKey: "", httpClient: MockResponder())
        let user = client.createUser(userId: "", accessToken: "", refreshToken: nil)
        guard let account = (try? user.accounts())?.first else { XCTFail(); return }
        
        let webhooks = account.webhooks
        XCTAssertEqual(webhooks.count, 1)
        XCTAssertEqual(webhooks.first!.id, "webhook_1")
        XCTAssertEqual(webhooks.first!.url.absoluteString, "https://monzo.com")
        XCTAssertEqual(webhooks.first!.account.id, "account_1")
    }
    
    func testAddWebhook() {
        let client = MonzoClient(publicKey: "", privateKey: "", httpClient: MockResponder())
        let user = client.createUser(userId: "", accessToken: "", refreshToken: nil)
        guard let account = (try? user.accounts())?.first else { XCTFail(); return }
        
        XCTAssertEqual(account.webhooks.count, 1)
        try? account.addWebhook(url: URL(string: "http://example.com")!)
        XCTAssertEqual(account.webhooks.count, 2)
        XCTAssertEqual(account.webhooks.last!.id, "webhook_2")
        XCTAssertEqual(account.webhooks.last!.url.absoluteString, "http://example.com")
        XCTAssertEqual(account.webhooks.last!.account.id, "account_1")
    }
    
    func testRemoveWebhook() {
        let client = MonzoClient(publicKey: "", privateKey: "", httpClient: MockResponder())
        let user = client.createUser(userId: "", accessToken: "", refreshToken: nil)
        guard let account = (try? user.accounts())?.first else { XCTFail(); return }
        
        XCTAssertEqual(account.webhooks.count, 1)
        try? account.addWebhook(url: URL(string: "http://example.com")!)
        XCTAssertEqual(account.webhooks.count, 2)
        XCTAssertEqual(account.webhooks.first!.id, "webhook_1")
        XCTAssertEqual(account.webhooks.last!.id, "webhook_2")
        try? account.webhooks.last?.remove()
        XCTAssertEqual(account.webhooks.count, 1)
        XCTAssertEqual(account.webhooks.first!.id, "webhook_1")
    }
    
    static var allTests = [
        ("testListWebhooks", testListWebhooks),
        ("testAddWebhook", testAddWebhook),
        ("testRemoveWebhook", testRemoveWebhook),
    ]
}
