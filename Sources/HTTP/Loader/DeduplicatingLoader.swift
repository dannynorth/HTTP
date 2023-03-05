import Foundation

public actor DeduplicatingLoader: HTTPLoader {
    
    private typealias DeduplicationHandlers = (HTTPResult) -> Void
    private var ongoingRequests = [String: [DeduplicationHandlers]]()
    
    public init() { }
    
    public func load(request: HTTPRequest, token: HTTPRequestToken) async -> HTTPResult {
        guard let dedupeIdentifier = request[option: \.deduplicationIdentifier] else {
            // no deduplicationIdentifier; task will not be deduped
            return await withNextLoader(for: request) { next in
                return await next.load(request: request, token: token)
            }
        }
        
        if ongoingRequests[dedupeIdentifier] != nil {
            let result = await result(of: dedupeIdentifier)
            return result.apply(request: request)
        } else {
            ongoingRequests[dedupeIdentifier] = []
            let result = await withNextLoader(for: request) { next in
                return await next.load(request: request, token: token)
            }
            let handlers = ongoingRequests.removeValue(forKey: dedupeIdentifier)
            for handler in (handlers ?? []) {
                handler(result)
            }
            
            return result
        }
        
    }
    
    private func result(of identifier: String) async -> HTTPResult {
        // TODO: cancelling the task should de-register this
        return await withUnsafeContinuation { continuation in
            self.ongoingRequests[identifier]?.append({ continuation.resume(returning: $0) })
        }
    }
    
}
