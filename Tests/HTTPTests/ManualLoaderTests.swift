import HTTP
import XCTest

class ManualLoaderTests: XCTestCase {
    
    var loader = ManualLoader()
    
    func testNoHandlers() async {
        let result = await loader.load(request: .init())
        XCTAssertFailure(result)
    }
    
    func testDefaultHandler() async throws {
        let expectation = self.expectation(description: #function)
        
        await loader.setDefaultHandler({
            expectation.fulfill()
            await $0.ok()
        })
        
        let result = await loader.load(request: .init())
        XCTAssertSuccess(result)
        try await allExpectations()
    }
    
    func testSingleHandler() async {
        await loader.setDefaultHandler({
            XCTFail()
            await $0.fail(.cannotConnect)
        })
        
        await loader.then { await $0.ok() }
        
        let result = await loader.load(request: .init())
        if let response = XCTAssertSuccess(result) {
            XCTAssertEqual(response.status, .ok)
        }
    }
    
    func testMultipleHandlers() async {
        await loader.setDefaultHandler({
            XCTFail()
            await $0.fail(.cannotConnect)
        })
        
        await loader.then { await $0.ok() }
        await loader.then { await $0.internalServerError() }
        
        XCTAssertSuccess(await loader.load(request: .init()))
        
        if let response = XCTAssertSuccess(await loader.load(request: .init())) {
            XCTAssertEqual(response.status, .internalServerError)
        }
    }
    
    func testFallbackToDefaultHandler() async throws {
        let expectation = self.expectation(description: #function)
        
        await loader.setDefaultHandler({
            expectation.fulfill()
            await $0.internalServerError()
        })
        
        await loader.then { await $0.ok() }
        
        XCTAssertSuccess(await loader.load(request: .init()))
        
        if let response = XCTAssertSuccess(await loader.load(request: .init())) {
            XCTAssertEqual(response.status, .internalServerError)
        }
        
        try await allExpectations()
    }
    
}
