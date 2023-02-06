public actor Throttle: HTTPLoader {
    
    public var maximumNumberOfTasks: Int
    
    private var ongoingCount = 0
    private var pending = [UnsafeContinuation<Void, Never>]()
    
    public init(maximumNumberOfTasks: Int = Int.max) {
        self.maximumNumberOfTasks = maximumNumberOfTasks
    }
    
    public func load(request: HTTPRequest) async -> HTTPResult {
        if request.options.throttleBehavior == .unthrottled {
            return await withNextLoader(request) { request, next in
                return await next.load(request: request)
            }
        } else {
            if maximumNumberOfTasks <= 0 {
                // everything is paused!
                print("Received request \(request.id) but \(type(of: self)) is paused (maximumNumberOfTasks = 0)")
            }
            await waitForCapacity()
            
            return await withNextLoader(request) { request, next in
                ongoingCount += 1
                let result = await next.load(request: request)
                ongoingCount -= 1
                
                signalAvailableCapacity()
                
                return result
            }
        }
    }
    
    private func waitForCapacity() async {
        if ongoingCount < maximumNumberOfTasks {
            return
        }
        
        return await withUnsafeContinuation { continuation in
            pending.append(continuation)
        }
    }
    
    private func signalAvailableCapacity() {
        let maxCapacity = max(maximumNumberOfTasks, 0)
        let availableCapacity = maxCapacity - ongoingCount
        
        if maximumNumberOfTasks <= 0 {
            let continuations = pending
            pending = []
            
            continuations.forEach {
                $0.resume()
            }
        } else if availableCapacity > 0 {
            let numberToSignal = min(availableCapacity, pending.count)
            let continuations = pending.dropFirst(numberToSignal)
            pending.removeFirst(numberToSignal)
            
            continuations.forEach {
                $0.resume()
            }
        }
    }
    
}
