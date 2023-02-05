public actor RequestingModifyingLoader: HTTPLoader {
    
    private let modifier: (inout HTTPRequest) async -> Void
    
    public init(_ modifier: @escaping (inout HTTPRequest) async -> Void) {
        self.modifier = modifier
    }
    
    public func load(request: HTTPRequest) async -> HTTPResult {
        return await withNextLoader(request) { req, next in
            var copy = req
            await modifier(&copy)
            return await next.load(request: copy)
        }
    }
    
}
