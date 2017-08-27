import Foundation
import JSON

public struct Merchant {
    public let id: String
    public let name: String
    public let logo: URL
    public let emoji: String
    public let groupId: String
    public let category: Transaction.Category
    
    // Consider using CoreLocation CLPlacemark to store location/address/etc?
    
    init(json: JSON?) throws {
        guard let json = json else { throw ClientError.other(0, "") }
        self.id = try json.value(forKey: "id")
        self.name = try json.value(forKey: "name")
        self.emoji = try json.value(forKey: "emoji")
        self.logo = try json.value(forKey: "logo")
        self.groupId = try json.value(forKey: "group_id")
        self.category = .init(rawValue: try json.value(forKey: "category"))
    }
}
