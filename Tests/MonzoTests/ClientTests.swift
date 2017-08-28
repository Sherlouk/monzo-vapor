import XCTest
@testable import Monzo

class ClientTests: XCTestCase {
    
    func testInitialiser() {
        let client = MonzoClient(publicKey: "public", privateKey: "private", httpClient: MockResponder())
        XCTAssertEqual(client.publicKey, "public")
        XCTAssertEqual(client.privateKey, "private")
        XCTAssertTrue(client.httpClient is MockResponder)
        XCTAssertNotNil(client.provider)
    }
    
    func testMonzoSetup() {
        let _ = MonzoClient(publicKey: "...", privateKey: "...", httpClient: MockResponder())
        XCTAssertTrue(Date.incomingDateFormatters.contains(.rfc3339))
    }
    
    func testMonzoPing() {
        let responder = MockResponder()
        let client = MonzoClient(publicKey: "public", privateKey: "private", httpClient: responder)
        
        XCTAssertTrue(client.ping())
        
        responder.statusOverride = .tooManyRequests
        
        XCTAssertFalse(client.ping())
    }
    
    func testMonzoPingRequest() {
        let responder = MockResponder()
        let client = MonzoClient(publicKey: "public", privateKey: "private", httpClient: responder)
        
        let request = try? client.provider.createRequest(.ping)
        XCTAssertEqual(request?.uri.description, "https://api.monzo.com:443/ping")
    }
    
    static var allTests = [
        ("testInitialiser", testInitialiser),
        ("testMonzoSetup", testMonzoSetup),
        ("testMonzoPing", testMonzoPing),
        ("testMonzoPingRequest", testMonzoPingRequest),
    ]
}
