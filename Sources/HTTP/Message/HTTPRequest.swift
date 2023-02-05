import Foundation

public struct HTTPRequest: Sendable {
    
    public let id = UUID()
    
    public var method: HTTPMethod = .get
    
    private var components = URLComponents()
    private var headers = HTTPHeaders()
    private var options = [ObjectIdentifier: any Sendable]()
    
    public var body: (any HTTPBody)?
    
    public init() {
        scheme = "https"
    }
    
    public var scheme: String? {
        get { components.scheme }
        set { components.scheme = newValue }
    }
    
    public var host: String? {
        get { components.host }
        set { components.host = newValue }
    }
    
    public var path: String {
        get { components.path }
        set { components.path = newValue }
    }
    
    public subscript(header name: HTTPHeader) -> String? {
        get { headers.firstValue(for: name) }
        set { headers.setValue(newValue, for: name) }
    }
    
    public subscript(headers name: HTTPHeader) -> [String] {
        get { headers[name] }
        set { headers[name] = newValue }
    }
    
    public subscript<O: HTTPOption>(option type: O.Type) -> O.Value {
        get {
            let id = ObjectIdentifier(type)
            if let override = options[id] as? O.Value {
                return override
            }
            return O.defaultValue
        }
        set {
            let id = ObjectIdentifier(type)
            options[id] = newValue
        }
    }
}
