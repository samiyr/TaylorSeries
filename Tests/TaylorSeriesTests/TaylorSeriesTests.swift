import XCTest
import Darwin

@testable import TaylorSeries

final class TaylorSeriesTests: XCTestCase {
    func testExp() {
        let series = TaylorSeries<Double>(summand: TaylorSeries.Common.exp)
        let exp = series.truncatedSeries(center: 0, up: 20)
        XCTAssert(abs(exp(1.0) - Darwin.M_E) < 1e-6)
    }
    func testSin() {
        let series = TaylorSeries<Double>(summand: TaylorSeries.Common.sin)
        let sin = series.truncatedSeries(center: 0, to: 1e-16)
        XCTAssert(abs(sin(1.0) - Darwin.sin(1.0)) < 1e-16)
    }
    func testBesselJ() {
        measure {
            let series = TaylorSeries<Double>(summand: TaylorSeries.Common.besselJ(0))
            let bessel = series.truncatedSeries(center: 0, to: 1e-16)
            XCTAssert(abs(bessel(1.0) - 0.765197686557966551) < 1e-16)
            // This is an example where the required precision of `1e-16` does not translate to 16 correct digits, but only 13.
            XCTAssert(abs(bessel(10.0) - -0.245935764451348337) < 1e-13)
        }
    }

    func testFactorialPerformance() {
        measure {
            for _ in 0...10000 {
                let _ = (1...10).map(Double.init).reduce(1, *)
            }
        }
    }
    func testGammaPerformance() {
        measure {
            for _ in 0...10000 {
                let _ = Double.gamma(11)
            }
        }
    }
    func testParitySignPerformance1() {
        func parity(_ n: Int) -> Double {
            if n % 2 == 0 {
                return 1
            } else {
                return -1
            }
        }
        measure {
            for i in 0...1000000 {
                let _ = parity(i)
            }
        }
    }
    func testParitySignPerformance2() {
        measure {
            for i in 0...1000000 {
                let _ = Double.pow(-1, i)
            }
        }
    }
    func testParitySignPerformance3() {
        measure {
            for i in 0...1000000 {
                let _ = 1 - 2 * (i & 1)
            }
        }
    }

    static var allTests = [
        ("expTest", testExp),
        ("sinTest", testSin)
    ]
}
