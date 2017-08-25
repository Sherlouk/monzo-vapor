import Foundation

public struct Webhook {
    let id: String
    let url: URL
    let account: Account
    
    func remove() {
        
    }
}

public extension Account {
    func webhooks() -> [Webhook] {
        return []
    }
    
    func addWebhook() {
        
    }
}
