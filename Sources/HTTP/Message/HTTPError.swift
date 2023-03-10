public struct HTTPError: Error {
    
    public enum Code {
        case cancelled
        case invalidRequest
        case cannotConnect
        case insecureConnection
        case cannotAuthenticate
        case timedOut
        case invalidResponse
        case cannotDecodeResponse
        case unknown
        case `internal`
    }
    
    public let code: Code
    public let request: HTTPRequest
    public let response: HTTPResponse?
    public let message: String?
    
    public let underlyingError: Error?
    
    public init(code: HTTPError.Code, request: HTTPRequest, response: HTTPResponse? = nil, message: String? = nil, underlyingError: Error? = nil) {
        self.code = code
        self.request = request
        self.response = response
        self.message = message
        self.underlyingError = underlyingError
    }
    
}
