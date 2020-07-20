import XCTest
import Darwin

@testable import TaylorSeries

final class TaylorSeriesTests: XCTestCase {
    func testExp() {
        let series = TaylorSeries(summand: TaylorSeries.Common.exp)
        let exp = series.truncatedSeries(center: 0, up: 20)
        XCTAssert(abs(exp(1.0) - Darwin.M_E) < 1e-6)
    }
    func testSin() {
        let series = TaylorSeries(summand: TaylorSeries.Common.sin)
        let sin = series.truncatedSeries(center: 0, to: 1e-16)
        XCTAssert(abs(sin(1.0) - Darwin.sin(1.0)) < 1e-16)
    }

    static var allTests = [
        ("expTest", testExp),
        ("sinTest", testSin)
    ]
}
