import XCTest
import Darwin

@testable import TaylorSeries

final class TaylorSeriesTests: XCTestCase {
    func testDivergent() {
        let series = TaylorSeries<Double>(summand: TaylorSeries.Common.geometric)
        let geometric = series.truncatedSeries(precision: 1e-3)
        let value = geometric(2.0) // this is outside the radius of convergence (-1, 1).
        XCTAssert(value.info.contains(.divergenceSuspected))
    }
    func testInfinity() {
        let series = TaylorSeries<Double>(summand: { n in (1.0 / Double(n), n) }) // first term is 1 / 0
        let harmonic = series.truncatedSeries(precision: 1e-3)
        let value = harmonic(1.0)
        XCTAssert(value.info.contains(.infinity))
    }
    func testNaN() {
        let series = TaylorSeries<Double>(summand: { n in (Double.nan / Double(n), n) })
        let function = series.truncatedSeries(precision: 1e-3)
        let value = function(1.0)
        XCTAssert(value.info.contains(.nan))
    }
    func testHarmonicDivergenceFailure() {
        // this isn't really a test, but a demonstration that a series can look like it's convergent, when in reality it's not
        let series = TaylorSeries<Double>(summand: { n in (1.0 / Double(n), n) }) // the harmonic series is the quintessential example of a series which approaches zero but doesn't converge.
        let harmonic = series.truncatedSeries(precision: 1e-3)
        let value = harmonic(1.0)
        XCTAssertFalse(value.info.contains(.divergenceSuspected))
    }
    func testExp() {
        let series = TaylorSeries<Double>(summand: TaylorSeries.Common.exp)
        let exp = series.truncatedSeries(order: 20)
        XCTAssert(abs(exp(1.0).value - Darwin.M_E) < 1e-6)
    }
    func testSin() {
        let series = TaylorSeries<Double>(summand: TaylorSeries.Common.sin)
        let sin = series.truncatedSeries(precision: 1e-16)
        XCTAssert(abs(sin(1.0).value - Darwin.sin(1.0)) < 1e-16)
    }
    func testBesselJ() {
        measure {
            let series = TaylorSeries<Double>(summand: TaylorSeries.Common.besselJ(0))
            let bessel = series.truncatedSeries(precision: 1e-16)
            XCTAssert(abs(pow(1.0, 0) * bessel(1.0).value - 0.765197686557966551) < 1e-16)
            // This is an example where the required precision of `1e-16` does not translate to 16 correct digits, but only 13. Unfortunately, this can't be improved by truncating the series manually, since we're fast approaching the limit of machine precision. This will be remedied once swift-numerics starts supporting higher-precision arithmetic.
            XCTAssert(abs(pow(1.0, 0) * bessel(10.0).value - -0.245935764451348337) < 1e-13)
        }
    }

    func testDerivative() {
        let cosSeries = TaylorSeries<Double>(summand: TaylorSeries.Common.cos)
        let mSinSeries = cosSeries.derivative() // cos'(x) = -sin(x)
        let cosSeriesD = cosSeries.derivative(4) // cos''''(x) = cos(x)
        XCTAssert(abs(mSinSeries.truncatedSeries(precision: 1e-12)(1.0).value - -Darwin.sin(1.0)) < 1e-12)
        XCTAssert(abs(cosSeries.truncatedSeries(order: 200)(2.0).value - cosSeriesD.truncatedSeries(order: 200)(2.0).value) < 1e-12)
    }
    func testDerivative2() {
        let expSeries = TaylorSeries<Double>(summand: TaylorSeries.Common.exp)
        let integrated = expSeries.derivative(10)
        XCTAssert(abs(integrated.truncatedSeries(precision: 1e-12)(2.0).value - Darwin.M_E * Darwin.M_E) < 1e-12)
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
        ("testDivergent", testDivergent),
        ("testInfinity", testInfinity),
        ("testNaN", testNaN),
        ("testHarmonicDivergenceFailure", testHarmonicDivergenceFailure),
        ("testExp", testExp),
        ("testSin", testSin),
        ("testBesselJ", testBesselJ),
        ("testDerivative", testDerivative),
        ("testDerivative2", testDerivative2),
        ("testFactorialPerformance", testFactorialPerformance),
        ("testGammaPerformance", testGammaPerformance),
        ("testParitySignPerformance1", testParitySignPerformance1),
        ("testParitySignPerformance2", testParitySignPerformance2),
        ("testParitySignPerformance3", testParitySignPerformance3)
    ]
}
