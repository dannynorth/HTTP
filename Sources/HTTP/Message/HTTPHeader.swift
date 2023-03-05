public struct HTTPHeader: Hashable, Sendable, ExpressibleByStringLiteral {
    
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.normalized == rhs.normalized
    }
    
    private let normalized: String
    public let rawValue: String
    
    public init(rawValue: String) {
        self.normalized = rawValue.lowercased()
        self.rawValue = rawValue
    }
    
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(normalized)
    }
}

extension HTTPHeader {
    
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
    public static let etag = HTTPHeader(rawValue: "ETag")
    public static let host = HTTPHeader(rawValue: "Host")
    public static let location = HTTPHeader(rawValue: "Location")
    public static let userAgent = HTTPHeader(rawValue: "User-Agent")
    
}
