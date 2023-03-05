import Foundation

internal struct URLSessionTaskState {
    let httpRequest: HTTPRequest
    let httpTask: HTTPTask
    
    let dataTask: URLSessionDataTask
    
    var response: HTTPResponse?
    
    var continuation: UnsafeContinuation<HTTPResult, Never>
}
