public actor RetryLoader: HTTPLoader {
    
    public init() { }
    
    public func load(request: HTTPRequest) async -> HTTPResult {
        return await withNextLoader(request) { request, next in
            var result = await next.load(request: request)
            
            guard var strategy = request.options.retryStrategy else {
                return result
            }
            
            do {
                var keepRetrying = true
                while keepRetrying {
                    if let error = result.failure, error.code == .cancelled {
                        keepRetrying = false
                    } else if let delay = strategy.nextDelay(after: result) {
                        try await Task.sleep(for: Duration(delay))
                        result = await next.load(request: request)
                    } else {
                        keepRetrying = false
                    }
                }
            } catch {
                let error = HTTPError(code: .cancelled,
                                      request: request,
                                      response: result.response,
                                      message: "Task was cancelled",
                                      underlyingError: result.failure)
                
                result = .failure(error)
            }
            
            return result
        }
    }
    
}
