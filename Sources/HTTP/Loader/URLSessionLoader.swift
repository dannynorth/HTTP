import Foundation

public actor URLSessionLoader: HTTPLoader {
    
    private let adapter: URLSessionAdapter
    
    public init(configuration: URLSessionConfiguration) {
        self.adapter = URLSessionAdapter(configuration: configuration)
    }
    
    public func load(request: HTTPRequest) async -> HTTPResult {
        return await adapter.execute(request)
    }
    
}
