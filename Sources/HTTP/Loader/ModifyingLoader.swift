public actor ModifyingLoader: HTTPLoader {
    
    private let requestModifier: (inout HTTPRequest) async -> Void
    private let responseModifier: (inout HTTPResponse) async -> Void
    
    public init(requestModifier: @escaping (inout HTTPRequest) async -> Void) {
        self.init(requestModifier: requestModifier, responseModifier: { _ in })
    }
    
    public init(responseModifier: @escaping (inout HTTPResponse) async -> Void) {
        self.init(requestModifier: { _ in }, responseModifier: responseModifier)
    }
    
    public init(requestModifier: @escaping (inout HTTPRequest) async -> Void,
                responseModifier: @escaping (inout HTTPResponse) async -> Void) {
        
        self.requestModifier = requestModifier
        self.responseModifier = responseModifier
    }
    
    public func load(request: HTTPRequest) async -> HTTPResult {
        return await withNextLoader(request) { req, next in
            var copy = req
            await requestModifier(&copy)
            let result = await next.load(request: copy)
            if var response = result.success {
                await responseModifier(&response)
                return .success(response)
            } else {
                return result
            }
        }
    }
    
}
