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
