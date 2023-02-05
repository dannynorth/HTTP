public protocol HTTPBody: Sendable {
    
    associatedtype Stream: AsyncSequence where Stream.Element == UInt8
    
    var headers: HTTPHeaders { get }
    var stream: Stream { get throws }
    
}

extension HTTPBody {
    
    public var headers: [HTTPHeader: [String]] {
        return [:]
    }
    
}
