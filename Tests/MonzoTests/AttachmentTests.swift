import XCTest
@testable import Monzo

class AttachmentTests: XCTestCase {
    
    func testRegisterAttachment() {
        let responder = MockResponder()
        let client = MonzoClient(publicKey: "", privateKey: "", httpClient: responder)
        let user = client.createUser(userId: "", accessToken: "", refreshToken: nil)
        guard let account = (try? user.accounts())?.first else { XCTFail(); return }
        guard let transactions = try? account.transactions() else { XCTFail(); return }
        guard let transaction = transactions.last else { XCTFail(); return }
        
        XCTAssertNoThrow(try transaction.registerAttachment(url: URL(string: "http://www.google.com/image.png")!))
        XCTAssertEqual(responder.lastRequest?.uri.description, "https://api.monzo.com:443/attachment/register")
        XCTAssertEqual(responder.lastRequest?.method, .post)
        XCTAssertEqual(responder.lastRequest?.body.bytes?.makeString(), "external_id=transaction_2&file_url=http%3A%2F%2Fwww.google.com%2Fimage.png&file_type=image%2Fpng")
    }

    func testDeregisterAttachment() {
        let responder = MockResponder()
        let client = MonzoClient(publicKey: "", privateKey: "", httpClient: responder)
        let user = client.createUser(userId: "", accessToken: "", refreshToken: nil)
        guard let account = (try? user.accounts())?.first else { XCTFail(); return }
        guard let transactions = try? account.transactions() else { XCTFail(); return }
        guard let transaction = transactions.last else { XCTFail(); return }
        
        let attachment = try? transaction.registerAttachment(url: URL(string: "http://www.google.com")!)
        XCTAssertNotNil(attachment)
        XCTAssertNoThrow(try attachment!.deregister())
        XCTAssertEqual(responder.lastRequest?.uri.description, "https://api.monzo.com:443/attachment/deregister")
        XCTAssertEqual(responder.lastRequest?.method, .post)
        XCTAssertEqual(responder.lastRequest?.body.bytes?.makeString(), "id=attachment_1")
    }

    static var allTests = [
        ("testRegisterAttachment", testRegisterAttachment),
        ("testDeregisterAttachment", testDeregisterAttachment),
    ]
}
