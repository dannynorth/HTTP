public actor ManualLoader: HTTPLoader {
    
    public typealias ManualHandler = (HTTPRequest) async -> HTTPResult
    
    private var next = [ManualHandler]()
    private var defaultHandler: ManualHandler?
    
    public init() { }
    
    public func setDefaultHandler(_ handler: @escaping ManualHandler) {
        self.defaultHandler = handler
    }
    
    @discardableResult
    public func then(_ perform: @escaping ManualHandler) -> Self {
        next.append(perform)
        return self
    }
    
    public func load(request: HTTPRequest) async -> HTTPResult {
        if next.isEmpty == false {
            let handler = next.removeFirst()
            return await handler(request)
        }
        
        if let defaultHandler {
            return await defaultHandler(request)
        }
        
        return await withNextLoader(request) { request, next in
            return await next.load(request: request)
        }
    }
    
}
