import Foundation

public actor RetryLoader: HTTPLoader {
    
    public init() { }
    
    public func load(request: HTTPRequest, token: HTTPRequestToken) async -> HTTPResult {
        return await withNextLoader(for: request) { next in
            
            var strategy: any HTTPRetryStrategy = request[option: \.retryStrategy] ?? NoRetry()
            var latestResult: HTTPResult?
            
            while true {
                if token.isCancelled {
                    return latestResult ?? .failure(HTTPError(code: .cancelled, request: request))
                }
                
                let attemptResult = await next.load(request: request, token: token)
                
                if attemptResult.failure?.code == .cancelled {
                    return attemptResult
                } else if let delay = strategy.nextDelay(after: attemptResult) {
                    do {
                        latestResult = attemptResult
                        try await Task.sleep(for: Duration(delay))
                        // this will loop around and attempt the request again
                        // as long as the request hasn't been cancelled
                    } catch {
                        let error = HTTPError(code: .cancelled,
                                              request: request,
                                              response: attemptResult.response,
                                              message: "Async task was cancelled",
                                              underlyingError: error)
                        return HTTPResult.failure(error)
                    }
                } else {
                    // no retry delay;
                    return attemptResult
                }
            }
            
        }
    }
    
}

private struct NoRetry: HTTPRetryStrategy {
    mutating func nextDelay(after result: HTTPResult) -> TimeInterval? { return nil }
}
