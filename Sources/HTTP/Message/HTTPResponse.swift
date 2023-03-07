public struct HTTPResponse: Sendable {
    
    public let request: HTTPRequest
    
    public var status: HTTPStatus
    
    public var headers = HTTPHeaders()
    
    public var body: (any HTTPBody)?
    
    public init(request: HTTPRequest,
                status: HTTPStatus,
                headers: HTTPHeaders = .init(),
                body: (any HTTPBody)? = nil) {
        
        self.request = request
        self.status = status
        self.headers = headers
        self.body = body
    }
    
    public subscript(header name: HTTPHeader) -> String? {
        get { headers.firstValue(for: name) }
        set { headers.setValue(newValue, for: name) }
    }
    
    public subscript(headers name: HTTPHeader) -> [String] {
        get { headers[name] }
        set { headers[name] = newValue }
    }
    
}

extension HTTPResponse {
    
    public static func ok(_ request: HTTPRequest) -> HTTPResponse {
        return .init(request: request, status: .ok)
    }
    
}
