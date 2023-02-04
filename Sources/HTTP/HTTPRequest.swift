import Foundation

public struct HTTPRequest: Sendable {
    
    public var method: HTTPMethod = .get
    private var components = URLComponents()
    
    public init() {
        scheme = "https"
    }
    
    public var scheme: String? {
        get { components.scheme }
        set { components.scheme = newValue }
    }
    
}
