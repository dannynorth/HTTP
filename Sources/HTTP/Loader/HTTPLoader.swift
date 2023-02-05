public protocol HTTPLoader: Actor {
    
    func load(request: HTTPRequest) async -> HTTPResult
    
}

extension HTTPLoader {
    
    public var nextLoader: HTTPLoader? {
        get async {
            return await LoaderChain.shared.nextLoader(for: self)
        }
    }
    
    public func setNextLoader(_ loader: HTTPLoader?) async {
        await LoaderChain.shared.setNextLoader(loader, for: self)
    }
    
    public func withNextLoader(_ request: HTTPRequest, perform: (HTTPRequest, HTTPLoader) async -> HTTPResult) async -> HTTPResult {
        
        guard let next = await nextLoader else {
            let error = HTTPError(code: .cannotConnect, request: request, message: "\(type(of: self)) does not have a nextLoader")
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
    await lhs?.setNextLoader(rhs)
    return lhs ?? rhs
}

@discardableResult
public func --> (lhs: HTTPLoader?, rhs: HTTPLoader?) async -> HTTPLoader? {
    await lhs?.setNextLoader(rhs)
    return lhs ?? rhs
}
