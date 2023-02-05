public struct HTTPQuery: Sendable, Sequence {
    
    private var pairs = Pairs<String, String>()
    
    public init() { }
    
    public subscript(name: String) -> [String] {
        get { pairs[name] }
        set { pairs[name] = newValue }
    }
    
    public func firstValue(for name: String) -> String? {
        pairs.firstValue(for: name)
    }
    
    public mutating func setValue(_ value: String?, for name: String) {
        pairs.setValue(value, for: name)
    }
    
    public mutating func addValue(_ value: String, for name: String) {
        pairs.addValue(value, for: name)
    }
    
    public typealias Element = (String, String)
    
    public func makeIterator() -> IndexingIterator<Array<Element>> {
        return pairs.makeIterator()
    }
    
}
