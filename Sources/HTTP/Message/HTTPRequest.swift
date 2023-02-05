import Foundation

public struct HTTPRequest: Sendable {
    
    public let id = UUID()
    
    public var method: HTTPMethod = .get
    
    public var host: String?
    public var path: String?
    public var fragment: String?
    public var query = HTTPQuery()
    public var headers = HTTPHeaders()
    
    public var options = HTTPOptions()
    
    public var body: (any HTTPBody)?
    
    public init() { }
    
    public subscript(header name: HTTPHeader) -> String? {
        get { headers.firstValue(for: name) }
        set { headers.setValue(newValue, for: name) }
    }
    
    public subscript(headers name: HTTPHeader) -> [String] {
        get { headers[name] }
        set { headers[name] = newValue }
    }
    
    public subscript(query name: String) -> String? {
        get { query.firstValue(for: name) }
        set { query.setValue(newValue, for: name) }
    }
    
    public subscript(queries name: String) -> [String] {
        get { query[name] }
        set { query[name] = newValue }
    }
    
    public subscript<O: HTTPOption>(option type: O.Type) -> O.Value {
        get { options[type] }
        set { options[type] = newValue }
    }
}
