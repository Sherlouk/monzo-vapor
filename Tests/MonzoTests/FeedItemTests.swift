import XCTest
@testable import Monzo

class FeedItemTests: XCTestCase {
    
    func testBasicInitialiser() {
        let feedItem = BasicFeedItem(title: "Title", imageUrl: URL(string: "http://monzo.com")!)
        XCTAssertEqual(feedItem.title, "Title")
        XCTAssertEqual(feedItem.body, nil)
        XCTAssertEqual(feedItem.type, "basic")
        XCTAssertEqual(feedItem.imageUrl.absoluteString, "http://monzo.com")
        XCTAssertEqual(feedItem.url, nil)
        XCTAssertEqual(feedItem.params, ["title": "Title", "image_url": "http://monzo.com"])
        XCTAssertEqual(feedItem.options.count, 0)
    }
    
    func testFullInitialiser() {
        let feedItem = BasicFeedItem(title: "Title",
                                     imageUrl: URL(string: "http://monzo.com")!,
                                     openUrl: URL(string: "mondo://transaction/1"),
                                     body: "Body",
                                     options: [.backgroundColor("#FFFFFF"), .titleColor("#FFFF00"), .bodyColor("#FF0000")])
        
        XCTAssertEqual(feedItem.title, "Title")
        XCTAssertEqual(feedItem.body, "Body")
        XCTAssertEqual(feedItem.type, "basic")
        XCTAssertEqual(feedItem.imageUrl.absoluteString, "http://monzo.com")
        XCTAssertEqual(feedItem.url?.absoluteString, "mondo://transaction/1")
        XCTAssertEqual(feedItem.params, ["title": "Title", "image_url": "http://monzo.com", "background_color": "#FFFFFF", "body": "Body", "title_color": "#FFFF00", "body_color": "#FF0000"])
        XCTAssertEqual(feedItem.options.count, 3)
    }
    
    func testSendFeedItemRequest() {
        let responder = MockResponder()
        let client = MonzoClient(publicKey: "", privateKey: "", httpClient: responder)
        let user = client.createUser(accessToken: "feedItem", refreshToken: nil)
        guard let account = (try? user.accounts())?.first else { XCTFail(); return }
        
        try? account.sendFeedItem(BasicFeedItem(title: "Title", imageUrl: URL(string: "http://monzo.com")!))
        XCTAssertEqual(responder.lastRequest?.uri.description, "https://api.monzo.com:443/feed")
        XCTAssertEqual(responder.lastRequest?.headers[.authorization], "Bearer feedItem")
        XCTAssertEqual(responder.lastRequest?.body.bytes?.makeString(), "account_id=account_1&type=basic&params[title]=Title&params[image_url]=http%3A%2F%2Fmonzo.com")
    }
    
    static var allTests = [
        ("testBasicInitialiser", testBasicInitialiser),
        ("testFullInitialiser", testFullInitialiser),
        ("testSendFeedItemRequest", testSendFeedItemRequest),
    ]
}
