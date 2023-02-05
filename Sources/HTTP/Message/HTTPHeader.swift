public struct HTTPHeader: RawRepresentable, Hashable, Sendable {
    
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
