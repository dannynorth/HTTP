public protocol HTTPLoader: Actor {
    
    func load(request: HTTPRequest) async -> HTTPResult
    
}

extension HTTPLoader {
    
    public nonisolated var nextLoader: HTTPLoader? {
        get  { LoaderChain.shared.nextLoader(for: self) }
        set { LoaderChain.shared.setNextLoader(newValue, for: self) }
    }
    
    public func withNextLoader(_ request: HTTPRequest, perform: (HTTPRequest, HTTPLoader) async -> HTTPResult) async -> HTTPResult {
        
        guard let next = nextLoader else {
            let error = HTTPError(code: .cannotConnect,
                                  request: request,
                                  message: "\(type(of: self)) does not have a nextLoader")
            return .failure(error)
        }
        
        return await perform(request, next)
    }
    
}

precedencegroup HTTPLoaderChainingPrecedence {
    higherThan: NilCoalescingPrecedence
    associativity: right
}

infix operator --> : HTTPLoaderChainingPrecedence

@discardableResult
public func --> (lhs: HTTPLoader?, rhs: HTTPLoader) async -> HTTPLoader {
    lhs?.nextLoader = rhs
    return lhs ?? rhs
}

@discardableResult
public func --> (lhs: HTTPLoader?, rhs: HTTPLoader?) async -> HTTPLoader? {
    lhs?.nextLoader = rhs
    return lhs ?? rhs
}
