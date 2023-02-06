import Foundation

internal class URLSessionAdapter {
    
    private let session: URLSession
    private let delegate: SessionDelegate
    
    init(configuration: URLSessionConfiguration) {
        let delegate = SessionDelegate()
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegate.queue)
        
        self.session = session
        self.delegate = delegate
        
        delegate.adapter = self
    }
    
    func execute(_ request: HTTPRequest) async -> HTTPResult {
        if let urlRequest = request.convertToURLRequest() {
            let task = session.dataTask(with: urlRequest)
            return await self.execute(task, for: request)
        } else {
            let err = HTTPError(code: .invalidRequest,
                                request: request,
                                message: "Could not convert request to URLRequest")
            return .failure(err)
        }
    }
    
    // this value is only accessed on the delegate's queue
    private var states = [Int: TaskState]()
    
    private func execute(_ task: URLSessionDataTask, for request: HTTPRequest) async -> HTTPResult {
        return await withUnsafeContinuation { continuation in
            delegate.queue.addOperation {
                let state = TaskState(request: request,
                                      task: task,
                                      continuation: continuation)
                
                self.states[task.taskIdentifier] = state
                
                task.resume()
            }
        }
    }
    
    // URLSession___Delegate shims
    
    fileprivate func task(_ task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
        print(#function, task, response, request)
        return request
    }
    
    fileprivate func task(_ task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        
        guard let request = states[task.taskIdentifier]?.request else {
            return (.cancelAuthenticationChallenge, nil)
        }
        
        guard let handler = request.options.authenticationChallengeHandler else {
            return (.performDefaultHandling, nil)
        }
        
        let response = await handler.evaluate(challenge, for: request)
        
        switch response {
        case .performDefaultAction: return (.performDefaultHandling, nil)
        case .cancelRequest: return (.cancelAuthenticationChallenge, nil)
        case .rejectProtectionSpace: return (.rejectProtectionSpace, nil)
        case .useCredential(let credential): return (.useCredential, credential)
        }
        
    }
    
    fileprivate func task(needsNewBodyStream task: URLSessionTask) async -> InputStream? {
        guard let state = states[task.taskIdentifier] else { return nil }
        guard let body = state.request.body else { return nil }
        
        print("TODO: create a new input stream for this body", body)
        return nil
    }
    
    fileprivate func task(_ task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
    }
    
    fileprivate func task(_ task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let state = states.removeValue(forKey: task.taskIdentifier) else {
            return
        }
        
        let result: HTTPResult
        
        if let error {
            let err = HTTPError(code: .unknown,
                                request: state.request,
                                response: state.response,
                                underlyingError: error)
            result = .failure(err)
        } else if var response = state.response {
            result = .success(response)
        } else {
            let err = HTTPError(code: .unknown,
                                request: state.request,
                                message: "Task completed, but there was no response")
            result = .failure(err)
        }
        
        state.continuation.resume(returning: result)
    }
    
    // MARK: - URLSessionDataDelegate
    
    fileprivate func task(_ dataTask: URLSessionDataTask, didReceive response: URLResponse) async -> URLSession.ResponseDisposition {
        
        guard let httpResponse = response as? HTTPURLResponse else {
            return .cancel
        }
        
        guard let request = states[dataTask.taskIdentifier]?.request else {
            return .cancel
        }
        
        let response = HTTPResponse(request: request, response: httpResponse)
        
        states[dataTask.taskIdentifier]?.response = response
        
        return .allow
        
    }
    
    fileprivate func task(_ dataTask: URLSessionDataTask, didReceive data: Data) {
        print(#function, dataTask, data.count, "bytes")
    }
}

private struct TaskState {
    let request: HTTPRequest
    let task: URLSessionDataTask
    
    var response: HTTPResponse?
    
    var continuation: UnsafeContinuation<HTTPResult, Never>
}

private class SessionDelegate: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate {
    
    let queue: OperationQueue
    weak var adapter: URLSessionAdapter?
    
    override init() {
        self.queue = OperationQueue()
        super.init()
        
        self.queue.name = "\(type(of: self))"
    }
    
    // MARK: - URLSessionTaskDelegate
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
        guard let adapter else {
            return nil
        }
        
        return await adapter.task(task, willPerformHTTPRedirection: response, newRequest: request)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        guard let adapter else {
            return (.cancelAuthenticationChallenge, nil)
        }
        
        return await adapter.task(task, didReceive: challenge)
    }
    
    func urlSession(_ session: URLSession, needNewBodyStreamForTask task: URLSessionTask) async -> InputStream? {
        guard let adapter else {
            return nil
        }
        
        return await adapter.task(needsNewBodyStream: task)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        adapter?.task(task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        adapter?.task(task, didCompleteWithError: error)
    }
    
    // MARK: - URLSessionDataDelegate
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse) async -> URLSession.ResponseDisposition {
        guard let adapter else {
            return .cancel
        }
        
        return await adapter.task(dataTask, didReceive: response)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        adapter?.task(dataTask, didReceive: data)
    }
}
