import XCTest

@discardableResult
func XCTAssertSuccess<T, E: Error>(_ result: Result<T, E>, file: StaticString = #file, line: UInt = #line) -> T? {
    
    switch result {
    case .success(let value):
        return value
    case .failure(let error):
        XCTFail("Unexpected error: \(error)", file: file, line: line)
        return nil
    }
    
}

@discardableResult
func XCTAssertFailure<T, E: Error>(_ result: Result<T, E>, file: StaticString = #file, line: UInt = #line) -> E? {
    
    switch result {
    case .success(let value):
        XCTFail("Unexpected value: \(value)", file: file, line: line)
        return nil
    case .failure(let error):
        return error
    }
    
}

extension XCTestCase {
    
    @MainActor
    func allExpectations(timeout: TimeInterval = 1.0) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.waitForExpectations(timeout: timeout, handler: { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }
    
}
