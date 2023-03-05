import Foundation

extension HTTPTask {
    
    public func fail(_ error: HTTPError) async {
        await self._complete(with: .failure(error))
    }
    
    public func fail(_ code: HTTPError.Code, response: HTTPResponse? = nil, underlyingError: Error? = nil) async {
        let error = HTTPError(code: code, request: request, response: response, underlyingError: underlyingError)
        await self._complete(with: .failure(error))
    }
    
    public func succeed(_ response: HTTPResponse) async {
        await self._complete(with: .success(response))
    }
    
    public func ok() async {
        let response = HTTPResponse(request: self.request, status: .ok)
        await self._complete(with: .success(response))
    }
    
    public func ok<Body: Encodable>(json: Body) async {
        let result = HTTPResult(request: self.request) {
            let body = try JSONEncoder().encode(json)
            var headers = HTTPHeaders()
            headers[.contentType] = ["application/json; charset=utf-8"]
            return HTTPResponse(request: self.request,
                                status: .ok,
                                headers: headers,
                                body: DataBody(data: body, headers: .init()))
        }
        await self._complete(with: result)
    }
    
    public func internalServerError() async {
        let response = HTTPResponse(request: self.request, status: .internalServerError)
        await self._complete(with: .success(response))
    }
    
}

private struct DataBody: HTTPBody {
    let data: Data
    let headers: HTTPHeaders
    
    var stream: AsyncStream<UInt8> { AsyncStream(sequence: data) }
}
