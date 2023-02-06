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
        switch urlRequest(for: request) {
        case .success(let urlRequest):
            let task = session.dataTask(with: urlRequest)
            return await self.execute(task, for: request)
                
        case .failure(let error):
            return .failure(error)
        }
    }
    
    private func urlRequest(for request: HTTPRequest) -> Result<URLRequest, HTTPError> {
        var components = URLComponents()
        components.scheme = "https"
        
        guard let host = request.host else {
            let err = HTTPError(code: .invalidRequest,
                                request: request,
                                message: "Request has no host")
            return .failure(err)
        }
        components.host = host
        components.path = request.path ?? ""
        components.fragment = request.fragment
        components.queryItems = request.query.map { name, value in
            return URLQueryItem(name: name, value: value.isEmpty ? nil : value)
        }
        
        guard let url = components.url else {
            let err = HTTPError(code: .invalidRequest,
                                request: request,
                                message: "Cannot form URL")
            return .failure(err)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        
        for (header, value) in request.headers {
            urlRequest.addValue(value, forHTTPHeaderField: header.rawValue)
        }
        
        if let body = request.body {
            for (header, value) in body.headers {
                urlRequest.addValue(value, forHTTPHeaderField: header.rawValue)
            }
            // TODO: make the body stream
        }
        
        return .success(urlRequest)
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
            return (.performDefaultHandling, nil)
        }
        
        let handler = request.options.authenticationChallengeHandler
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
        
        let status = HTTPStatus(rawValue: httpResponse.statusCode)
        var headers = HTTPHeaders()
        
        for (anyHeader, anyValue) in httpResponse.allHeaderFields {
            let header = HTTPHeader(rawValue: anyHeader.description)
            if let str = anyValue as? String {
                headers.addValue(str, for: header)
            } else if let strs = anyValue as? [String] {
                for str in strs {
                    headers.addValue(str, for: header)
                }
            } else {
                print("UNKNOWN HEADER VALUE", anyValue)
            }
        }
        
        
        states[dataTask.taskIdentifier]?.response = HTTPResponse(request: request,
                                                                 status: status,
                                                                 headers: headers,
                                                                 body: nil)
        
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
