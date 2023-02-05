internal struct Pairs<Key: Equatable & Sendable, Value: Sendable>: Sendable {
    typealias Element = (Key, Value)
    
    private var values = [Element]()
    
    internal init() { }
    
    internal subscript(key: Key) -> [Value] {
        get { values(for: key) }
        set { setValues(newValue, for: key) }
    }
    
    internal func firstValue(for key: Key) -> Value? {
        return values.first(where: { $0.0 == key })?.1
    }
    
    internal mutating func setValue(_ value: Value?, for key: Key) {
        if let value {
            self.setValues([value], for: key)
        } else {
            self.setValues([], for: key)
        }
    }
    
    internal mutating func addValue(_ value: Value, for key: Key) {
        values.append((key, value))
    }
    
    private func values(for key: Key) -> [Value] {
        return values.compactMap { $0 == key ? $1 : nil }
    }
    
    private mutating func setValues(_ newValues: [Value], for key: Key) {
        var remaining = newValues.makeIterator()
        var new = [Element]()
        
        for (existingKey, value) in values {
            if existingKey == key {
                if let next = remaining.next() {
                    // there's a replacement value
                    new.append((existingKey, next))
                } else {
                    // there is no replacement value; do not append
                }
            } else {
                new.append((existingKey, value))
            }
        }
        
        while let next = remaining.next() {
            new.append((key, next))
        }
        
        self.values = new
    }
}

extension Pairs: Sequence {
    
    func makeIterator() -> IndexingIterator<[Element]> {
        return values.makeIterator()
    }
    
}
