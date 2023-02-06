import Foundation

public enum AuthenticationChallengeResponse {
    case cancelRequest
    case performDefaultAction
    case rejectProtectionSpace
    case useCredential(URLCredential)
}

public protocol AuthenticationChallengeHandler {
    func evaluate(_ challenge: URLAuthenticationChallenge, for request: HTTPRequest) async -> AuthenticationChallengeResponse
}

extension HTTPOptions {
    
    public var authenticationChallengeHandler: any AuthenticationChallengeHandler {
        get { self[AuthenticationChallengeOption.self] }
        set { self[AuthenticationChallengeOption.self] = newValue }
    }
    
}

private struct AuthenticationChallengeOption: HTTPOption, AuthenticationChallengeHandler  {
    static let defaultValue: any AuthenticationChallengeHandler = AuthenticationChallengeOption()
    
    func evaluate(_ challenge: URLAuthenticationChallenge, for request: HTTPRequest) async -> AuthenticationChallengeResponse {
        return .performDefaultAction
    }
}
