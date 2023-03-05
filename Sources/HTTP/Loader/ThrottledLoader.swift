public actor ThrottledLoader: HTTPLoader {
    
    private var maximumNumberOfTasks: Int
    
    private var ongoingCount = 0
    private var pending = [UnsafeContinuation<Void, Never>]()
    
    public init(maximumNumberOfTasks: Int = Int.max) {
        self.maximumNumberOfTasks = max(maximumNumberOfTasks, 0)
    }
    
    public func setMaximumNumberOfTasks(_ count: Int) {
        self.maximumNumberOfTasks = max(count, 0)
    }
    
    public func load(task: HTTPTask) async -> HTTPResult {
        let request = await task.request
        if request.options.throttleBehavior == .unthrottled {
            return await withNextLoader(task) { await $1.load(task: $0) }
        }
        
        if maximumNumberOfTasks <= 0 {
            // everything is paused!
            print("Received request \(request.id) but \(type(of: self)) is paused (maximumNumberOfTasks = 0)")
        }
        
        await waitForCapacity()
        
        return await withNextLoader(task) { task, next in
            ongoingCount += 1
            let result = await next.load(task: task)
            ongoingCount -= 1
            signalAvailableCapacity()
            return result
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
        let availableCapacity = maximumNumberOfTasks - ongoingCount
        guard availableCapacity > 0 else {
            return
        }
        
        let numberToSignal = min(availableCapacity, pending.count)
        let continuations = pending.dropFirst(numberToSignal)
        pending.removeFirst(numberToSignal)
        
        continuations.forEach {
            $0.resume()
        }
    }
    
}
