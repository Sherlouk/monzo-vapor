import Foundation

protocol FeedItem {
    var type: String { get }
    var params: [String: String] { get }
    var url: URL? { get }
    func validate() throws
}

public struct BasicFeedItem: FeedItem {
    var type: String {
        return "basic"
    }
    
    public var title: String
    public var imageUrl: URL
    public var url: URL?
    public var body: String?
    public var options: [BasicFeedItemStyleOptions]
    
    public init(title: String, imageUrl: URL, openUrl: URL? = nil, body: String? = nil, options: [BasicFeedItemStyleOptions] = []) {
        self.title = title
        self.imageUrl = imageUrl
        self.url = openUrl
        self.body = body
        self.options = options
    }
    
    var params: [String: String] {
        var builder = [String: String]()
        builder["title"] = title
        builder["image_url"] = imageUrl.absoluteString
        
        if let body = body {
            builder["body"] = body
        }
        
        options.forEach {
            switch $0 {
            case .backgroundColor(let color): builder["background_color"] = color
            case .titleColor(let color): builder["title_color"] = color
            case .bodyColor(let color): builder["body_color"] = color
            }
        }
        
        return builder
    }
    
    func validate() throws {
        if title.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            throw MonzoUsageError.invalidFeedItem
        }
    }
}

public enum BasicFeedItemStyleOptions {
    /// Sets the background color of the feed item. Value should be a HEX code
    case backgroundColor(String)
    
    /// Sets the text color of the feed item's title label. Value should be a HEX code
    case titleColor(String)
    
    /// Sets the text color of the feed item's body label, if one exists. Value should be a HEX code
    case bodyColor(String)
}
