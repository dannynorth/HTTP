import Foundation

public actor RetryLoader: HTTPLoader {
    
    public init() { }
    
    public func load(task: HTTPTask) async -> HTTPResult {
        return await withNextLoader(task) { task, next in
            let request = await task.request
            
            var strategy: any HTTPRetryStrategy = request.options.retryStrategy ?? NoRetry()
            
            while true {
                // first, check to see if the original task was cancelled or finished
                // while these attempts are ongoing
                if let originalResult = await task.result {
                    return originalResult
                }
                
                let nextAttempt = HTTPTask(request: request)
                let attemptResult = await next.load(task: nextAttempt)
                
                if let error = attemptResult.failure, error.code == .cancelled {
                    // this attempt was cancelled
                    return attemptResult
                } else if let delay = strategy.nextDelay(after: attemptResult) {
                    // we're going to wait and then try again
                    do {
                        try await Task.sleep(for: Duration(delay))
                    } catch {
                        let error = HTTPError(code: .cancelled,
                                              request: request,
                                              response: attemptResult.response,
                                              message: "Async task was cancelled",
                                              underlyingError: error)
                        let result = HTTPResult.failure(error)
                        await task._complete(with: result)
                        return result
                    }
                } else {
                    // there's no delay for the next attempt, so we're not going to retry
                    await task._complete(with: attemptResult)
                    return attemptResult
                }
                
            }
        }
    }
    
}

private struct NoRetry: HTTPRetryStrategy {
    mutating func nextDelay(after result: HTTPResult) -> TimeInterval? { return nil }
}
