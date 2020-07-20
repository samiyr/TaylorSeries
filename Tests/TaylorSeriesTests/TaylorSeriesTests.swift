import XCTest
@testable import TaylorSeries

final class TaylorSeriesTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(TaylorSeries().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
