
public extension Account {
    func createFeedItem(title: String, body: String?, imageUrl: String, url: String?, styleOptions: [FeedItemStyleOptions]) {

    }
}

public enum FeedItemStyleOptions {
    case backgroundColor(String)
    case titleColor(String)
    case bodyColor(String)
}
