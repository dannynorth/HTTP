import Foundation

internal class URLSessionAdapter {
    
    private let session: URLSession
    private let delegate: URLSessionAdapterDelegate
    
    init(configuration: URLSessionConfiguration) {
        let delegate = URLSessionAdapterDelegate()
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
    private var states = [Int: URLSessionTaskState]()
    
    private func execute(_ task: URLSessionDataTask, for request: HTTPRequest) async -> HTTPResult {
        return await withUnsafeContinuation { continuation in
            delegate.queue.addOperation {
                let state = URLSessionTaskState(request: request,
                                                task: task,
                                                continuation: continuation)
                
                self.states[task.taskIdentifier] = state
                
                task.resume()
            }
        }
    }
    
    // URLSession___Delegate shims
    
    func task(_ task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
        
        guard let originalRequest = states[task.taskIdentifier]?.request else {
            return nil
        }
        
        guard let handler = originalRequest.options.redirectionHandler else {
            return request
        }
        
        let httpResponse = HTTPResponse(request: originalRequest, response: response)
        let proposed = HTTPRequest(request: request)
        
        let actual = await handler.handleRedirection(for: originalRequest,
                                                     response: httpResponse,
                                                     proposedRedirection: proposed)
        
        return actual?.convertToURLRequest()
    }
    
    func task(_ task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        
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
    
    func task(needsNewBodyStream task: URLSessionTask) async -> InputStream? {
        guard let state = states[task.taskIdentifier] else { return nil }
        guard let body = state.request.body else { return nil }
        
        print("TODO: create a new input stream for this body", body)
        return nil
    }
    
    func task(_ task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
    }
    
    func task(_ task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let state = states.removeValue(forKey: task.taskIdentifier) else {
            return
        }
        
        let result: HTTPResult
        
        if let error {
            let err = HTTPError(error: error, request: state.request, response: state.response)
            result = .failure(err)
        } else if var response = state.response {
            // TODO: set the response body
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
    
    func task(_ dataTask: URLSessionDataTask, didReceive response: URLResponse) async -> URLSession.ResponseDisposition {
        
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
    
    func task(_ dataTask: URLSessionDataTask, didReceive data: Data) {
        print(#function, dataTask, data.count, "bytes")
    }
}
