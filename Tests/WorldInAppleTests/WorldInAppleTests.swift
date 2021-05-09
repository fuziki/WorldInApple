import XCTest
@testable import WorldInApple

final class WorldInAppleTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(WorldInApple().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
