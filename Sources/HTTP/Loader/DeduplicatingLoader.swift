import Foundation

public actor DeduplicatingLoader: HTTPLoader {
    
    private typealias DeduplicationHandler = (HTTPResult) -> Void
    private var ongoingRequests = [String: Pairs<UUID, DeduplicationHandler>]()
    
    public init() { }
    
    public func load(request: HTTPRequest, token: HTTPRequestToken) async -> HTTPResult {
        guard let dedupeIdentifier = request[option: \.deduplicationIdentifier] else {
            // no deduplicationIdentifier; task will not be deduped
            return await withNextLoader(for: request) { next in
                return await next.load(request: request, token: token)
            }
        }
        
        if ongoingRequests[dedupeIdentifier] != nil {
            let result = await result(of: dedupeIdentifier, token: token)
            return result.apply(request: request)
        } else {
            ongoingRequests[dedupeIdentifier] = .init()
            let result = await withNextLoader(for: request) { next in
                return await next.load(request: request, token: token)
            }
            let handlers = ongoingRequests.removeValue(forKey: dedupeIdentifier)
            for (_, handler) in (handlers ?? []) {
                handler(result)
            }
            
            return result
        }
        
    }
    
    private func result(of identifier: String, token: HTTPRequestToken) async -> HTTPResult {
        return await withUnsafeContinuation { continuation in
            let id = UUID()
            let handler: DeduplicationHandler = { continuation.resume(returning: $0) }
            
            token.addCancellationHandler {
                self.ongoingRequests[identifier]?.setValue(nil, for: id)
            }
            
            self.ongoingRequests[identifier]?.setValue(handler, for: id)
        }
    }
    
}
