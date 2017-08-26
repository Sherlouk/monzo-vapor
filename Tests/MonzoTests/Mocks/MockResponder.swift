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
            case "/accounts": return "accounts"
            default: return nil
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
