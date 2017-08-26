
public extension Account {
    public func createFeedItem(title: String, body: String?, imageUrl: String, url: String?, styleOptions: [FeedItemStyleOptions]) {
        
    }
}

public enum FeedItemStyleOptions {
    /// Sets the background color of the feed item. Value should be a HEX code
    case backgroundColor(String)
    
    /// Sets the text color of the feed item's title label. Value should be a HEX code
    case titleColor(String)
    
    /// Sets the text color of the feed item's body label, if one exists. Value should be a HEX code
    case bodyColor(String)
}
