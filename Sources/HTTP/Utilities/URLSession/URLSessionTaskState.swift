import Foundation

internal struct URLSessionTaskState {
    let queue = AsyncQueue()
    
    let request: HTTPRequest
    let task: URLSessionDataTask
    
    var response: HTTPResponse?
    var responseBody: HTTPWriteStream?
    
    var continuation: UnsafeContinuation<HTTPResult, Never>
}
