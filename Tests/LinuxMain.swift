import XCTest
@testable import MonzoTests

XCTMain([
    testCase(ClientTests.allTests),
    testCase(AmountTests.allTests),
    testCase(AccountTests.allTests),
    testCase(FeedItemTests.allTests),
    testCase(MerchantTests.allTests),
    testCase(TransactionTests.allTests),
    testCase(UserTests.allTests),
    testCase(WebhookTests.allTests),
    testCase(JSONTests.allTests),
])
