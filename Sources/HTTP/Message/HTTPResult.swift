public typealias HTTPResult = Result<HTTPResponse, HTTPError>

extension HTTPResult {
    
    public static func ok(_ request: HTTPRequest) -> HTTPResult {
        return .success(.ok(request))
    }
    
    public static func internalServerError(_ request: HTTPRequest) -> HTTPResult {
        return .success(HTTPResponse(request: request, status: .internalServerError))
    }
    
    public var request: HTTPRequest {
        switch self {
        case .success(let response): return response.request
        case .failure(let error): return error.request
        }
    }
    
    public var response: HTTPResponse? {
        switch self {
        case .success(let response): return response
        case .failure(let error): return error.response
        }
    }
    
}
