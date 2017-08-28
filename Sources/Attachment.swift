import Foundation
import JSON

public struct Attachment {
    
    let transaction: Transaction
    public let id: String
    public let url: URL
    public let created: Date
    
    init(transaction: Transaction, json: JSON) throws {
        self.transaction = transaction
        self.id = try json.value(forKey: "id")
        self.url = try json.value(forKey: "file_url")
        self.created = try json.value(forKey: "created")
    }
    
    public func deregister() throws {
        try transaction.deregisterAttachment(self)
    }
    
}
