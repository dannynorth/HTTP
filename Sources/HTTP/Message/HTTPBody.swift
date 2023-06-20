public protocol HTTPBody: Sendable {
    
    var headers: HTTPHeaders { get }
    var stream: AsyncStream<UInt8> { get throws }
    
}

extension HTTPBody {
    
    public var headers: HTTPHeaders {
        return .init()
    }
    
}
