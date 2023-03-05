import Foundation

internal struct URLSessionTaskState {
    let httpRequest: HTTPRequest
    let token: HTTPRequestToken
    
    let dataTask: URLSessionDataTask
    
    var response: HTTPResponse?
    
    var continuation: UnsafeContinuation<HTTPResult, Never>
}
