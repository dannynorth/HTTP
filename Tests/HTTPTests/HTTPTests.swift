import XCTest
@testable import HTTP

final class HTTPTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(HTTP().text, "Hello, World!")
    }
}