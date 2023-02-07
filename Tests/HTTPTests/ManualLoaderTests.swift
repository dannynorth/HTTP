import HTTP
import XCTest

class ManualLoaderTests: XCTestCase {
    
    var loader = ManualLoader()
    
    func testNoHandlers() async {
        let result = await loader.load(request: .init())
        XCTAssertFailure(result)
    }
    
    func testDefaultHandler() async {
        let expectation = self.expectation(description: #function)
        
        await loader.setDefaultHandler({
            expectation.fulfill()
            return .ok($0)
        })
        
        let result = await loader.load(request: .init())
        XCTAssertSuccess(result)
        wait(for: [expectation], timeout: 0)
    }
    
    func testSingleHandler() async {
        await loader.setDefaultHandler({
            XCTFail()
            return .failure(HTTPError(code: .cannotConnect, request: $0))
        })
        
        await loader.then { .ok($0) }
        
        let result = await loader.load(request: .init())
        if let response = XCTAssertSuccess(result) {
            XCTAssertEqual(response.status, .ok)
        }
    }
    
    func testMultipleHandlers() async {
        await loader.setDefaultHandler({
            XCTFail()
            return .failure(HTTPError(code: .cannotConnect, request: $0))
        })
        
        await loader.then { .ok($0) }
        await loader.then { .internalServerError($0) }
        
        XCTAssertSuccess(await loader.load(request: .init()))
        
        if let response = XCTAssertSuccess(await loader.load(request: .init())) {
            XCTAssertEqual(response.status, .internalServerError)
        }
    }
    
    func testFallbackToDefaultHandler() async {
        let expectation = self.expectation(description: #function)
        
        await loader.setDefaultHandler({
            expectation.fulfill()
            return .internalServerError($0)
        })
        
        await loader.then { .ok($0) }
        
        XCTAssertSuccess(await loader.load(request: .init()))
        
        if let response = XCTAssertSuccess(await loader.load(request: .init())) {
            XCTAssertEqual(response.status, .internalServerError)
        }
        wait(for: [expectation], timeout: 0)
    }
    
}
