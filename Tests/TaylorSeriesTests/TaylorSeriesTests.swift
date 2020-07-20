import XCTest
import Darwin

@testable import TaylorSeries

final class TaylorSeriesTests: XCTestCase {
    func testDivergent() {
        let series = TaylorSeries<Double>(summand: TaylorSeries.Common.geometric)
        let geometric = series.truncatedSeries(center: 0, to: 1e-3)
        print(geometric(2.0))
    }
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
            XCTAssert(abs(pow(1.0, 0) * bessel(1.0) - 0.765197686557966551) < 1e-16)
            // This is an example where the required precision of `1e-16` does not translate to 16 correct digits, but only 13. Unfortunately, this can't be improved by truncating the series manually, since we're fast approaching the limit of machine precision. This will be remedied once swift-numerics starts supporting higher-precision arithmetic.
            XCTAssert(abs(pow(1.0, 0) * bessel(10.0) - -0.245935764451348337) < 1e-13)
        }
    }

    func testDerivative() {
        let cosSeries = TaylorSeries<Double>(summand: TaylorSeries.Common.cos)
        let mSinSeries = cosSeries.derivative() // cos'(x) = -sin(x)
        let cosSeriesD = cosSeries.derivative(4) // cos''''(x) = cos(x)
        XCTAssert(abs(mSinSeries.truncatedSeries(center: 0, to: 1e-12)(1.0) - -Darwin.sin(1.0)) < 1e-12)
        XCTAssert(abs(cosSeries.truncatedSeries(center: 0, up: 200)(2.0) - cosSeriesD.truncatedSeries(center: 0, up: 200)(2.0)) < 1e-12)
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
