import XCTest
@testable import Monzo

class MerchantTests: XCTestCase {
    
    func testExample() {
        // Merchants are incomplete
    }
    
    func testNilInitialiser() {
        XCTAssertThrowsError(try Merchant(json: nil))
    }
    
    static var allTests = [
        ("testNilInitialiser", testNilInitialiser),
    ]
}
