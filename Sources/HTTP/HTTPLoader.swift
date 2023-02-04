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
