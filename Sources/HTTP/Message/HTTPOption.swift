public protocol HTTPOption {
    
    associatedtype Value: Sendable
    
    static var defaultValue: Value { get }
    
}
