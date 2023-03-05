public actor ModifyingLoader: HTTPLoader {
    
    private let requestModifier: (inout HTTPRequest) async -> Void
    private let resultModifier: (inout HTTPResult) async -> Void
    
    public init(requestModifier: @escaping (inout HTTPRequest) async -> Void,
                resultModifier: @escaping (inout HTTPResult) async -> Void) {
        
        self.requestModifier = requestModifier
        self.resultModifier = resultModifier
    }
    
    public func load(request: HTTPRequest, token: HTTPRequestToken) async -> HTTPResult {
        return await withNextLoader(for: request) { next in
            var copy = request
            await requestModifier(&copy)
            
            guard copy.id == request.id else {
                let error = HTTPError(code: .invalidRequest,
                                      request: copy,
                                      response: nil,
                                      message: "Request with id \(request.id) was replaced with entirely distinct request. This is not allowed.",
                                      underlyingError: nil)
                return .failure(error)
            }
            
            let result = await next.load(request: copy, token: token)
            var modifiedResult = result
            await resultModifier(&modifiedResult)
            
            guard modifiedResult.request.id == result.request.id else {
                let error = HTTPError(code: .invalidResponse,
                                      request: modifiedResult.request,
                                      response: modifiedResult.response,
                                      message: "Result for request id \(request.id) was replaced with entirely distinct result. This is not allowed.",
                                      underlyingError: nil)
                return .failure(error)
            }
            
            
            return modifiedResult
        }
    }
    
}
