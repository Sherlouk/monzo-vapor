import S4
import Foundation

class MockResponder: Responder {
    var responseOverride: Response?
    var lastRequest: Request?
    var statusOverride: Status = .ok
    
    func respond(to request: Request) throws -> Response {
        self.lastRequest = request
        if let responseOverride = responseOverride { return responseOverride }
        
        let data = S4.Data(try getMockData(for: request))
        return Response(version: Version(major: 1, minor: 0),
                        status: statusOverride,
                        headers: Headers(),
                        cookieHeaders: [],
                        body: .buffer(data))
    }
    
    func getMockData(for request: Request) throws -> String {
        let parent = #file.components(separatedBy: "/").dropLast().joined(separator: "/")
        
        let pathRaw: String? = {
            switch request.uri.path ?? "" {
            case "accounts": return "accounts"
            default: return nil
            }
        }()
        
        guard let path = pathRaw else { throw MockError.noMockPath }
        guard let url = URL(string: "file://\(parent)/\(path).json") else { throw MockError.invalidUrl }
        guard let data = try? String(contentsOf: url, encoding: .utf8) else { throw MockError.noMockData }
        
        return data
    }
    
}

enum MockError: Error {
    case noMockPath
    case invalidUrl
    case noMockData
}
