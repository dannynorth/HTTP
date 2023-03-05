public protocol HTTPLoader: Actor {
    
    @discardableResult
    func load(task: HTTPTask) async -> HTTPResult
    
}

extension HTTPLoader {
    
    public nonisolated var nextLoader: HTTPLoader? {
        get  { LoaderChain.shared.nextLoader(for: self) }
        set { LoaderChain.shared.setNextLoader(newValue, for: self) }
    }
    
    public func withNextLoader(_ task: HTTPTask, perform: (HTTPTask, HTTPLoader) async -> HTTPResult) async -> HTTPResult {
        
        // Only attempt to load the task if it doesn't have a result
        if let result = await task.result {
            return result
        }
        
        guard let next = nextLoader else {
            let request = await task.request
            let error = HTTPError(code: .cannotConnect,
                                  request: request,
                                  message: "\(type(of: self)) does not have a nextLoader")
            return .failure(error)
        }
        
        return await perform(task, next)
    }
    
    public func load(request: HTTPRequest) async -> HTTPResult {
        let task = HTTPTask(request: request)
        return await load(task: task)
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
