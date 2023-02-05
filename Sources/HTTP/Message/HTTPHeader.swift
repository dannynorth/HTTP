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

internal struct HTTPHeaders: Sendable {
    
    private var pairs = Array<(HTTPHeader, String)>()
    
    internal init() { }
    
    internal subscript(name: HTTPHeader) -> [String] {
        get { values(for: name) }
        set { setValues(newValue, for: name) }
    }
    
    internal func firstValue(for header: HTTPHeader) -> String? {
        return pairs.first(where: { $0.0 == header })?.1
    }
    
    internal mutating func setValue(_ value: String?, for header: HTTPHeader) {
        if let value {
            self.setValues([value], for: header)
        } else {
            self.setValues([], for: header)
        }
    }
    
    private func values(for header: HTTPHeader) -> [String] {
        return pairs.compactMap { $0 == header ? $1 : nil }
    }
    
    private mutating func setValues(_ values: [String], for header: HTTPHeader) {
        var remaining = values.makeIterator()
        var new = Array<(HTTPHeader, String)>()
        
        for (existingHeader, value) in pairs {
            if existingHeader == header {
                if let next = remaining.next() {
                    // there's a replacement value
                    new.append((existingHeader, next))
                } else {
                    // there is no replacement value; do not append
                }
            } else {
                new.append((existingHeader, value))
            }
        }
        
        while let next = remaining.next() {
            new.append((header, next))
        }
        
        self.pairs = new
    }
}
