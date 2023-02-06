import Foundation

public enum HTTPAuthenticationChallengeResponse {
    case cancelRequest
    case performDefaultAction
    case rejectProtectionSpace
    case useCredential(URLCredential)
}

public protocol HTTPAuthenticationChallengeHandler {
    func evaluate(_ challenge: URLAuthenticationChallenge, for request: HTTPRequest) async -> HTTPAuthenticationChallengeResponse
}

extension HTTPOptions {
    
    public var authenticationChallengeHandler: (any HTTPAuthenticationChallengeHandler)? {
        get { self[HTTPAuthenticationChallengeOption.self] }
        set { self[HTTPAuthenticationChallengeOption.self] = newValue }
    }
    
}

private enum HTTPAuthenticationChallengeOption: HTTPOption {
    static let defaultValue: (any HTTPAuthenticationChallengeHandler)? = nil
}
