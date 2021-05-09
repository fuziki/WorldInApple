import XCTest
@testable import WorldInApple

final class WorldInAppleTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let res = "Hello, World!"
        XCTAssertEqual(res, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
