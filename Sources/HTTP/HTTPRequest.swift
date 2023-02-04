import Foundation

public struct HTTPRequest: Sendable {
    
    public let id = UUID()
    
    public var method: HTTPMethod = .get
    
    private var components = URLComponents()
    private var headers = [HTTPHeader: [String]]()
    
    public var body: (any HTTPBody)?
    
    public init() {
        scheme = "https"
    }
    
    public var scheme: String? {
        get { components.scheme }
        set { components.scheme = newValue }
    }
    
    public var path: String {
        get { components.path }
        set { components.path = newValue }
    }
    
    public subscript(header name: HTTPHeader) -> String? {
        get {
            return headers[name]?.first
        }
        set {
            if let newValue {
                headers[name] = [newValue]
            } else {
                headers.removeValue(forKey: name)
            }
        }
    }
    
    public subscript(headers name: HTTPHeader) -> [String] {
        get {
            return headers[name] ?? []
        }
        set {
            if newValue.isEmpty {
                headers.removeValue(forKey: name)
            } else {
                headers[name] = newValue
            }
        }
    }
}
