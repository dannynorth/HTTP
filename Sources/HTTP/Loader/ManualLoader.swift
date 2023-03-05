public actor ManualLoader: HTTPLoader {
    
    public typealias ManualHandler = (HTTPTask) async -> Void
    
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
    
    public func load(task: HTTPTask) async -> HTTPResult {
        if next.isEmpty == false {
            let handler = next.removeFirst()
            await handler(task)
            
            if let result = await task.result {
                return result
            }
        }
        
        if let defaultHandler {
            await defaultHandler(task)
            if let result = await task.result {
                return result
            }
        }
        
        return await withNextLoader(task) { task, next in
            return await next.load(task: task)
        }
    }
    
}
