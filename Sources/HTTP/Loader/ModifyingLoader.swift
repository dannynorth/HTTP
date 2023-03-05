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
    
    public func load(task: HTTPTask) async -> HTTPResult {
        return await withNextLoader(task) { task, next in
            var copy = await task.request
            await requestModifier(&copy)
            await task.setRequest(copy)
            
            let result = await next.load(task: task)
            if var response = result.success {
                await responseModifier(&response)
                return .success(response)
            } else {
                return result
            }
        }
    }
    
}
