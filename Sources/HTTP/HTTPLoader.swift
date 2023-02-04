public protocol HTTPLoader: Actor {
    
    func load(request: HTTPRequest) async -> HTTPResult
    
}
