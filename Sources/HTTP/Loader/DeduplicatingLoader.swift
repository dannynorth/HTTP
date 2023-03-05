import Foundation

public actor DeduplicatingLoader: HTTPLoader {
    
    private var ongoingTasks = [String: HTTPTask]()
    
    public nonisolated init() { }
    
    public func load(task: HTTPTask) async -> HTTPResult {
        let dedupeIdentifier = await task.request.options.deduplicationIdentifier
        
        guard let dedupeIdentifier else {
            // no deduplicationIdentifier; task will not be deduped
            return await withNextLoader(task) { task, next in
                return await next.load(task: task)
            }
        }
        
        if let existingTask = ongoingTasks[dedupeIdentifier] {
            return await result(of: existingTask, for: task)
        } else {
            // there's no task with this identifier
            ongoingTasks[dedupeIdentifier] = task
            let result = await withNextLoader(task) { task, next in
                return await next.load(task: task)
            }
            ongoingTasks[dedupeIdentifier] = nil
            return result
        }
        
    }
    
    private func result(of existingTask: HTTPTask, for task: HTTPTask) async -> HTTPResult {
        return await withUnsafeContinuation { continuation in
            Task {
                await existingTask.addResultHandler { result in
                    let appliedResult = result.apply(request: await task.request)
                    await task._complete(with: appliedResult)
                    continuation.resume(returning: result)
                }
            }
        }
    }
    
}
