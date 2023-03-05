import Foundation

public actor HTTPTask {
    
    public nonisolated let id: UUID
    public private(set) var request: HTTPRequest
    
    public private(set) var response: HTTPResponse?
    
    private var state: any HTTPTaskState
    
    public var isCancelled: Bool { (state as? Finished)?.cancelled ?? false }
    public var isFinished: Bool { state is Finished }
    public var result: HTTPResult? { state.result }
    
    public init(request: HTTPRequest) {
        self.id = request.id
        self.request = request
        self.state = OnGoing()
    }
    
    public func setRequest(_ newRequest: HTTPRequest) {
        guard newRequest.id == id else {
            fatalError("Attempting to mutate task \(id) with a completely different request.")
        }
        guard state is OnGoing else {
            print("Attempting to modify request after it has already been cancelled or finished; Ignoring modifications")
            return
        }
        request = newRequest
    }
    
    public func addCancellationHandler(_ handler: @escaping () -> Void) {
        if let work = state.addCancellationHandler(handler) {
            work()
        }
    }
    
    public func addResultHandler(_ handler: @escaping (HTTPResult) -> Void) {
        if let work = state.addResultHandler(handler) {
            work()
        }
    }
    
    public func cancel() {
        let (newState, work) = state.cancel(request)
        state = newState
        for item in work { item() }
    }
    
    public func _complete(with result: HTTPResult) {
        let (newState, work) = state.complete(with: result)
        state = newState
        for item in work { item() }
    }
    
}
