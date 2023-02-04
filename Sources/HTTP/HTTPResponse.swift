public struct HTTPResponse {
    
    public let request: HTTPRequest
    
    public var status: HTTPStatus
    
    public var headers = [HTTPHeader: [String]]()
    
    public var body: (any HTTPBody)?
    
    public init(request: HTTPRequest,
                status: HTTPStatus,
                headers: [HTTPHeader : [String]] = [:],
                body: (any HTTPBody)? = nil) {
        
        self.request = request
        self.status = status
        self.headers = headers
        self.body = body
    }
    
}
