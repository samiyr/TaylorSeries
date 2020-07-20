import Foundation
import RealModule

/// Represents a Taylor Series expansion for some real-analytic function.
public struct TaylorSeries<Number: Real> {
    /// A closure implementing the terms to be summed.
    /// `x` includes both the computation point and the center, meaning it's really `(x - x_0)`.
    /// `n` is the summation index, starting at `start`.
    /// See `Common` for examples on how it works.
    public typealias Summand = (_ x: Number, _ n: Int) -> (Number)
    /// Terms to be summed. This must include everything in one package, including the (x - x_0)^n and n! parts. The reason for this is that it allows some sums (like sin and cos) to be defined more easily.
    public var summand: Summand
    /// Start index of the sum. Defaults to 0.
    public var start: Int = 0
    
    /// Returns a callable closure with the series centered at `center` and truncated at `up`.
    public func truncatedSeries(center: Number, up to: Int) -> (Number) -> (Number) {
        return { x in
            return (start...to).map { summand(x - center, $0) }.reduce(0, +)
        }
    }
    /// Returns a callable closure where the series is truncated at an appropariate point such that the difference between the last two terms is less than `epsilon`. However, the summing is capped by `max`, which defaults to 1000.
    /// Note that `epsilon` does not guarantee correct digits, see `testBesselJ()` in `TaylorSeriesTests.swift`.
    /// To guarantee correct digits, use Taylor's theorem to obtain an appropriate truncating index and use `truncatedSeries(center:, up:)` directly.
    public func truncatedSeries(center: Number, to epsilon: Number, max iterations: Int = 1000) -> (Number) -> (Number) {
        return { x in
            var value = Number(0)
            var prev = Number(0)
            var i = start
            repeat {
                if i > iterations { break }
                prev = value
                value += summand(x - center, i)
                i += 1
            } while abs(value - prev) >= epsilon
            return value
        }
    }
    
    /// Defines some common series terms for ease of use.
    public struct Common {
        /// 1 / (1 - x)
        public static var geometric: Summand {
            return { x, n in
                return Number.pow(x, n)
            }
        }
        
        public static var exp: Summand {
            return { x, n in
                return Number.pow(x, n) / factorial(n)
            }
        }
        public static var sin: Summand {
            return { x, n in
                return paritySign(n) * Number.pow(x, 2 * n + 1) / factorial(2 * n + 1)
            }
        }
        public static var sinh: Summand {
            return { x, n in
                return Number.pow(x, 2 * n + 1) / factorial(2 * n + 1)
            }
        }
        public static var arcsin: Summand {
            return { x, n in
                let num = factorial(2 * n) * Number.pow(x, 2 * n + 1)
                let den = Number.pow(2, 2 * n) * Number.pow(factorial(n), 2) * Number(2 * n + 1)
                return num / den
            }
        }
        public static var arcsinh: Summand {
            return { x, n in
                let num = paritySign(n) * factorial(2 * n) * Number.pow(x, 2 * n + 1)
                let den = Number.pow(2, 2 * n) * Number.pow(factorial(n), 2) * Number(2 * n + 1)
                return num / den
            }
        }

        public static var cos: Summand {
            return { x, n in
                return paritySign(n) * Number.pow(x, 2 * n) / factorial(2 * n)
            }
        }
        public static var cosh: Summand {
            return { x, n in
                return Number.pow(x, 2 * n) / factorial(2 * n)
            }
        }
        public static var arctan: Summand {
            return { x, n in
                // Workaround to 'compiler is unable to type-check the expression in reasonable time'
                let num = paritySign(n) * Number.pow(x, 2 * n + 1)
                let den = Number(2 * n + 1)
                return num / den
            }
        }
        public static var logPlusOne: Summand {
            return { x, n in
                if n == 0 { return 0 }
                return paritySign(n + 1) * Number.pow(x, n) / Number(n)
            }
        }
        public static func besselJ(_ nu: Number) -> Summand {
            return { x, n in
                let num = paritySign(n) * Number.pow(x / Number(2), Number(2 * n) + nu)
                let den = factorial(n) * Number.gamma(nu + Number(n) + 1)
                return  num / den
            }
        }
    }
    
    // Helper functions, which define commonly needed functions when working with Taylor series.
    
    /// Factorial, n! = n * (n-1) * (n-2) * ... * 2 * 1.
    /// 0! = 1! = 1
    public static func factorial(_ n: Int) -> Number {
        return Number.gamma(Number(n + 1))
    }

    /// Gives (-1)^n as a `Number`.
    public static func paritySign(_ n: Int) -> Number {
        if n % 2 == 0 {
            return 1
        } else {
            return -1
        }
    }

}

