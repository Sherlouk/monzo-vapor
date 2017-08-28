import XCTest
@testable import Monzo

class TransactionTests: XCTestCase {
    
    func testFetchTransactions() {
        let client = MonzoClient(publicKey: "", privateKey: "", httpClient: MockResponder())
        let user = client.createUser(accessToken: "", refreshToken: nil)
        guard let account = (try? user.accounts())?.first else { XCTFail(); return }
        guard let transactions = try? account.transactions() else { XCTFail(); return }
        
        XCTAssertEqual(transactions.count, 2)
        
        let firstTransaction = transactions.first!
        XCTAssertEqual(firstTransaction.id, "transaction_1")
        XCTAssertTrue(firstTransaction.declineReason == nil)
        XCTAssertEqual(firstTransaction.declined, false)
        XCTAssertEqual(firstTransaction.description, "Initial top up")
        XCTAssertEqual(firstTransaction.amount.amount, 10000)
        XCTAssertEqual(firstTransaction.amount.currency, "GBP")
        XCTAssertEqual(firstTransaction.isTopup, true)
        XCTAssertEqual(firstTransaction.isRefund, false)
        XCTAssertEqual(firstTransaction.notes, "")
        XCTAssertTrue(firstTransaction.category.description == Transaction.Category.monzo.description)
        XCTAssertTrue(firstTransaction.merchant == nil)
        XCTAssertEqual(firstTransaction.merchantId, nil)
        XCTAssertTrue(firstTransaction.metadata["is_topup"] ?? "" == "true")

        let secondTransaction = transactions.last!
        XCTAssertEqual(secondTransaction.id, "transaction_2")
        XCTAssertTrue(secondTransaction.declineReason == nil)
        XCTAssertEqual(secondTransaction.declined, false)
        XCTAssertEqual(secondTransaction.description, "MCDONALDS")
        XCTAssertEqual(secondTransaction.amount.amount, -200)
        XCTAssertEqual(secondTransaction.amount.currency, "GBP")
        XCTAssertEqual(secondTransaction.isTopup, false)
        XCTAssertEqual(secondTransaction.isRefund, false)
        XCTAssertEqual(secondTransaction.notes, "Yum Yum")
        XCTAssertTrue(secondTransaction.category.description == Transaction.Category.eatingOut.description)
        XCTAssertEqual(secondTransaction.merchant?.id, "merchant_1")
        XCTAssertEqual(secondTransaction.merchant?.name, "McDonald's")
        XCTAssertEqual(secondTransaction.merchantId, "merchant_1")
        XCTAssertTrue(secondTransaction.metadata["foo"] ?? "" == "bar")
    }
    
    func testFetchTransactionsNoMerchantInfo() {
        let client = MonzoClient(publicKey: "", privateKey: "", httpClient: MockResponder())
        let user = client.createUser(accessToken: "", refreshToken: nil)
        guard let account = (try? user.accounts())?.first else { XCTFail(); return }
        guard let transactions = try? account.transactions(merchantInfo: false) else { XCTFail(); return }
        
        let firstTransaction = transactions.first!
        XCTAssertEqual(firstTransaction.id, "transaction_2")
        XCTAssertTrue(firstTransaction.declineReason == nil)
        XCTAssertEqual(firstTransaction.declined, false)
        XCTAssertEqual(firstTransaction.description, "MCDONALDS")
        XCTAssertEqual(firstTransaction.amount.amount, -200)
        XCTAssertEqual(firstTransaction.amount.currency, "GBP")
        XCTAssertEqual(firstTransaction.isTopup, false)
        XCTAssertEqual(firstTransaction.isRefund, false)
        XCTAssertEqual(firstTransaction.notes, "Yum Yum")
        XCTAssertTrue(firstTransaction.category.description == Transaction.Category.eatingOut.description)
        XCTAssertTrue(firstTransaction.merchant == nil)
        XCTAssertEqual(firstTransaction.merchantId, "merchant_1")
        XCTAssertTrue(firstTransaction.metadata["foo"] ?? "" == "bar")
    }
    
    func testTransactionCategories() {
        XCTAssertEqual(Transaction.Category(rawValue: "monzo").description, Transaction.Category.monzo.description)
        XCTAssertEqual(Transaction.Category(rawValue: "mondo").description, Transaction.Category.monzo.description)
        XCTAssertEqual(Transaction.Category(rawValue: "general").description, Transaction.Category.general.description)
        XCTAssertEqual(Transaction.Category(rawValue: "eating_out").description, Transaction.Category.eatingOut.description)
        XCTAssertEqual(Transaction.Category(rawValue: "expenses").description, Transaction.Category.expenses.description)
        XCTAssertEqual(Transaction.Category(rawValue: "transport").description, Transaction.Category.transport.description)
        XCTAssertEqual(Transaction.Category(rawValue: "cash").description, Transaction.Category.cash.description)
        XCTAssertEqual(Transaction.Category(rawValue: "bills").description, Transaction.Category.bills.description)
        XCTAssertEqual(Transaction.Category(rawValue: "entertainment").description, Transaction.Category.entertainment.description)
        XCTAssertEqual(Transaction.Category(rawValue: "shopping").description, Transaction.Category.shopping.description)
        XCTAssertEqual(Transaction.Category(rawValue: "holidays").description, Transaction.Category.holidays.description)
        XCTAssertEqual(Transaction.Category(rawValue: "groceries").description, Transaction.Category.groceries.description)
        XCTAssertEqual(Transaction.Category(rawValue: "something else").description, "something else")
    }
    
    func testTransactionDeclineReason() {
        XCTAssertEqual(Transaction.DeclineReason(rawValue: "INSUFFICIENT_FUNDS")?.description, Transaction.DeclineReason.insufficientFunds.description)
        XCTAssertEqual(Transaction.DeclineReason(rawValue: "CARD_INACTIVE")?.description, Transaction.DeclineReason.cardInactive.description)
        XCTAssertEqual(Transaction.DeclineReason(rawValue: "CARD_BLOCKED")?.description, Transaction.DeclineReason.cardBlocked.description)
        XCTAssertEqual(Transaction.DeclineReason(rawValue: "OTHER")?.description, Transaction.DeclineReason.other.description)
        XCTAssertEqual(Transaction.DeclineReason(rawValue: "HUMAN_ERROR")?.description, "HUMAN_ERROR")
    }
    
    func testTransactionRequests() {
        let responder = MockResponder()
        let client = MonzoClient(publicKey: "", privateKey: "", httpClient: responder)
        let user = client.createUser(accessToken: "", refreshToken: nil)
        guard let account = (try? user.accounts())?.first else { XCTFail(); return }
     
        XCTAssertNoThrow(try account.transactions(merchantInfo: false))
        XCTAssertEqual(responder.lastRequest?.uri.description, "https://api.monzo.com:443/transactions?account_id=account_1")
        
        XCTAssertNoThrow(try account.transactions(merchantInfo: true))
        XCTAssertEqual(responder.lastRequest?.uri.description, "https://api.monzo.com:443/transactions?account_id=account_1&expand[]=merchant")
        
        XCTAssertNoThrow(try account.transactions(merchantInfo: false, options: [.limit(10)]))
        XCTAssertEqual(responder.lastRequest?.uri.description, "https://api.monzo.com:443/transactions?account_id=account_1&limit=10")
        
        XCTAssertNoThrow(try account.transactions(merchantInfo: false, options: [.limit(10), .limit(20)])) // Only first one counts
        XCTAssertEqual(responder.lastRequest?.uri.description, "https://api.monzo.com:443/transactions?account_id=account_1&limit=10")
        
        XCTAssertNoThrow(try account.transactions(merchantInfo: false, options: [.limit(10), .before("123456")]))
        XCTAssertEqual(responder.lastRequest?.uri.description, "https://api.monzo.com:443/transactions?account_id=account_1&limit=10&before=123456")
        
        XCTAssertNoThrow(try account.transactions(merchantInfo: true, options: [.limit(20), .before("123456"), .since("654321")]))
        XCTAssertEqual(responder.lastRequest?.uri.description, "https://api.monzo.com:443/transactions?account_id=account_1&expand[]=merchant&limit=20&before=123456&since=654321")
    }
    
    func testTransactionLoadMore() {
        let responder = MockResponder()
        let client = MonzoClient(publicKey: "", privateKey: "", httpClient: responder)
        let user = client.createUser(accessToken: "", refreshToken: nil)
        guard let account = (try? user.accounts())?.first else { XCTFail(); return }
        guard var transactions = try? account.transactions() else { XCTFail(); return }
        
        XCTAssertEqual(transactions.count, 2)
        XCTAssertNoThrow(try transactions.loadMore())
        XCTAssertEqual(transactions.count, 3)
        XCTAssertEqual(responder.lastRequest?.uri.description, "https://api.monzo.com:443/transactions?account_id=account_1&expand[]=merchant&since=transaction_2")
        XCTAssertNoThrow(try transactions.loadMore())
        XCTAssertEqual(responder.lastRequest?.uri.description, "https://api.monzo.com:443/transactions?account_id=account_1&expand[]=merchant&since=transaction_3")
    }
    
    static var allTests = [
        ("testFetchTransactions", testFetchTransactions),
        ("testFetchTransactionsNoMerchantInfo", testFetchTransactionsNoMerchantInfo),
        ("testTransactionCategories", testTransactionCategories),
        ("testTransactionDeclineReason", testTransactionDeclineReason),
        ("testTransactionRequests", testTransactionRequests),
        ("testTransactionLoadMore", testTransactionLoadMore),
    ]
}
