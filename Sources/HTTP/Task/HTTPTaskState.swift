import Foundation

typealias Completion = () -> Void
typealias CancellationHandler = () -> Void
typealias ResultHandler = (HTTPResult) -> Void

internal protocol HTTPTaskState {
    var result: HTTPResult? { get }
    
    mutating func addCancellationHandler(_ handler: @escaping CancellationHandler) -> Completion?
    mutating func addResultHandler(_ handler: @escaping ResultHandler) -> Completion?
    
    func cancel(_ request: HTTPRequest) -> (any HTTPTaskState, [Completion])
    func complete(with result: HTTPResult) -> (any HTTPTaskState, [Completion])
}

internal struct OnGoing: HTTPTaskState {
    var result: HTTPResult? { nil }
    
    var cancellationHandlers = Array<CancellationHandler>()
    var resultHandlers = Array<ResultHandler>()
    
    mutating func addCancellationHandler(_ handler: @escaping CancellationHandler) -> Completion? {
        cancellationHandlers.append(handler)
        return nil
    }
    
    mutating func addResultHandler(_ handler: @escaping ResultHandler) -> Completion? {
        resultHandlers.append(handler)
        return nil
    }
    
    func cancel(_ request: HTTPRequest) -> (HTTPTaskState, [Completion]) {
        let error = HTTPError(code: .cancelled, request: request)
        let result = HTTPResult.failure(error)
        
        let nextState = Finished(_result: result, cancelled: true)
        
        let completions = cancellationHandlers.reversed() + resultHandlers.reversed().map { h in
            { h(result) }
        }
        return (nextState, completions)
    }
    
    func complete(with result: HTTPResult) -> (HTTPTaskState, [Completion]) {
        let nextState = Finished(_result: result, cancelled: false)
        let completions = resultHandlers.reversed().map { h in
            { h(result) }
        }
        return (nextState, completions)
    }
}

internal struct Finished: HTTPTaskState {
    fileprivate let _result: HTTPResult
    
    var result: HTTPResult? { _result }
    let cancelled: Bool
    
    func addCancellationHandler(_ handler: @escaping CancellationHandler) -> Completion? {
        return cancelled ? handler : nil
    }
    
    func addResultHandler(_ handler: @escaping ResultHandler) -> Completion? {
        return { handler(_result) }
    }
    
    func cancel(_ request: HTTPRequest) -> (HTTPTaskState, [Completion]) {
        print("Attempting to cancel a task that has already finished!")
        return (self, [])
    }
    
    func complete(with result: HTTPResult) -> (HTTPTaskState, [Completion]) {
        print("Attempting to complete a task that has already finished!")
        return (self, [])
    }
}
