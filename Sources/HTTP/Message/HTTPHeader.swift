public struct HTTPHeader: RawRepresentable, Hashable, Sendable {
    
    public static let accept = HTTPHeader(rawValue: "Accept")
    public static let acceptEncoding = HTTPHeader(rawValue: "Accept-Encoding")
    public static let authorization = HTTPHeader(rawValue: "Authorization")
    public static let cacheControl = HTTPHeader(rawValue: "Cache-Control")
    public static let connection = HTTPHeader(rawValue: "Connection")
    public static let contentEncoding = HTTPHeader(rawValue: "Content-Encoding")
    public static let contentLength = HTTPHeader(rawValue: "Content-Length")
    public static let contentType = HTTPHeader(rawValue: "Content-Type")
    public static let cookie = HTTPHeader(rawValue: "Cookie")
    public static let date = HTTPHeader(rawValue: "Date")
    public static let etag = HTTPHeader(verbatim: "ETag")
    public static let host = HTTPHeader(rawValue: "Host")
    public static let location = HTTPHeader(rawValue: "Location")
    public static let userAgent = HTTPHeader(rawValue: "User-Agent")
    
    public static func normalizeHeaderName(_ name: String) -> String {
        return name.split(separator: "-")
            .map {
                let first = $0.first?.uppercased() ?? ""
                let rest = $0.dropFirst().lowercased()
                return first + rest
            }
            .joined(separator: "-")
    }
    
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = HTTPHeader.normalizeHeaderName(rawValue)
    }
    
    public init(verbatim: String) {
        self.rawValue = verbatim
    }
    
}

public struct HTTPHeaders: Sendable, Sequence {
    
    private var pairs = Pairs<HTTPHeader, String>()
    
    public init() { }
    
    public subscript(name: HTTPHeader) -> [String] {
        get { pairs[name] }
        set { pairs[name] = newValue }
    }
    
    public func firstValue(for header: HTTPHeader) -> String? {
        pairs.firstValue(for: header)
    }
    
    public mutating func setValue(_ value: String?, for header: HTTPHeader) {
        pairs.setValue(value, for: header)
    }
    
    public mutating func addValue(_ value: String, for header: HTTPHeader) {
        pairs.addValue(value, for: header)
    }
    
    public typealias Element = (HTTPHeader, String)
    
    public func makeIterator() -> IndexingIterator<Array<Element>> {
        return pairs.makeIterator()
    }
}
