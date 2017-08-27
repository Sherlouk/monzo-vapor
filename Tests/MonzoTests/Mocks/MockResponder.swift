import Vapor
import HTTP
import Foundation

class MockResponder: Responder {
    var responseOverride: Response?
    var lastRequest: Request?
    var statusOverride: Status = .ok
    
    func respond(to request: Request) throws -> Response {
        self.lastRequest = request
        if let responseOverride = responseOverride { return responseOverride }
        
        return try Response(status: statusOverride, json: try getMockData(for: request))
    }
    
    func getMockData(for request: Request) throws -> JSON {
        let parent = #file.components(separatedBy: "/").dropLast().joined(separator: "/")
        
        let pathRaw: String? = {
            switch request.uri.path {
            case "/accounts" where request.uri.query?.contains("uk_retail") == true: return "currentAccounts"
            case "/accounts": return "accounts"
            case "/ping": return "ping"
            case "/balance": return "balance"
            case "/webhooks" where request.method == .post: return "newWebhook"
            case "/webhooks": return "listWebhooks"
            case "/transactions" where request.uri.query?.contains("expand") == true: return "transactions"
            case "/transactions": return "transactionsNoMerchant"
            case "/feed", "/webhooks/webhook_2": return "empty"
            case "/ping/whoami": return "whoami"
            default: print("📛 " + request.uri.path); return "empty"
            }
        }()
        
        guard let path = pathRaw else { throw MockError.noMockPath }
        guard let url = URL(string: "file://\(parent)/\(path).json") else { throw MockError.invalidUrl }
        guard let data = try? String(contentsOf: url, encoding: .utf8) else { throw MockError.noMockData }
        
        return try JSON(bytes: data.makeBytes())
    }
    
}

enum MockError: Error {
    case noMockPath
    case invalidUrl
    case noMockData
}
