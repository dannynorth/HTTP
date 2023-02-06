extension Result {
    
    internal var failure: Failure? {
        switch self {
        case .success: return nil
        case .failure(let error): return error
        }
    }
    
    internal var isFailure: Bool {
        switch self {
        case .success: return false
        case .failure: return true
        }
    }
    
}
