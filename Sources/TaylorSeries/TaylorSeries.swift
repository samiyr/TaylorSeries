import Foundation
import RealModule

/// Represents a Taylor Series expansion for some real-analytic function.
public struct TaylorSeries<Number: Real> {
    /// A closure implementing the terms to be summed.
    /// `n` is the summation index, starting at `start`.
    /// The closure return must be of type `(coefficient, power)`,
    /// where the series is then of the form
    /// `Σ coefficient(n) * (x - x_0)^power(n)`.
    /// See `Common` for examples on how it works.
    public typealias Summand = (_ n: Int) -> (Number, Int)
    /// Terms to be summed. See `Summand` for the format.
    public var summand: Summand
    /// Start index of the sum. Defaults to 0.
    public var start: Int = 0
    
    /// Returns a callable closure with the series centered at `center` and truncated at `up`.
    public func truncatedSeries(center: Number, up to: Int) -> (Number) -> (Number) {
        return { x in
            return (start...to).map {
                let term = summand($0)
                return term.0  * Number.pow(x - center, term.1)
            }.reduce(0, +)
        }
    }
    /// Returns a callable closure where the series is truncated at an appropariate point such that the difference between the last two terms is less than `epsilon`. However, the summing is capped by `max`, which defaults to 1000.
    ///
    /// Note that `epsilon` does not guarantee correct digits, see `testBesselJ()` in `TaylorSeriesTests.swift`.
    /// To guarantee correct digits, use Taylor's theorem to obtain an appropriate truncating index and use `truncatedSeries(center:, up:)` directly.
    public func truncatedSeries(center: Number, to epsilon: Number, max iterations: Int = 1000) -> (Number) -> (Number) {
        return { x in
            var value = Number(0)
            var prev = Number(0)
            var nonzeroFlag = false
            var i = start
            repeat {
                if i > iterations { break }
                prev = value
                let term = summand(i)
                let termValue = term.0 * Number.pow(x - center, term.1)
                value += termValue
                if !termValue.isZero { nonzeroFlag = true }
                i += 1
            } while abs(value - prev) >= epsilon || !nonzeroFlag
            return value
        }
    }
    
    /// Yields the derivative series of order `order` of the original series. The derivative is calculated by differentiating term-by-term, which in a power series amounts to multiplying the coefficient by some constant (determined by the `order`) and reducing the powers. `Order` defaults to 1, which is applying the derivative operator just once. `order` must be non-negative.
    ///
    /// **Warning**: the derivative series is not guaranteed to converge even if the original series did. It's up to you to check convergence.
    public func derivative(_ order: Int = 1) -> TaylorSeries {
        if order <= 0 { return self }
        let newSummand: Summand = { n in
            let oldSummand = summand(n)
            let multiplier = ((oldSummand.1 - order + 1)...oldSummand.1).reduce(1, *)
            let coefficient = oldSummand.0 * Number(multiplier)
            let power = oldSummand.1 - order
            return (coefficient, power)
        }
        return TaylorSeries(summand: newSummand, start: start)
    }
    /// Defines some common series terms for ease of use.
    public struct Common {
        /// 1 / (1 - x)
        public static var geometric: Summand {
            return { n in
                return (1, n)
            }
        }
        
        public static var exp: Summand {
            return { n in
                return (1 / factorial(n), n)
            }
        }
        public static var sin: Summand {
            return { n in
                return (paritySign(n) / factorial(2 * n + 1), 2 * n + 1)
            }
        }
        public static var sinh: Summand {
            return { n in
                return (1 / factorial(2 * n + 1), 2 * n + 1)
            }
        }
        public static var arcsin: Summand {
            return { n in
                let num = factorial(2 * n)
                let den = Number.pow(2, 2 * n) * Number.pow(factorial(n), 2) * Number(2 * n + 1)
                return (num / den, 2 * n + 1)
            }
        }
        public static var arcsinh: Summand {
            return { n in
                let num = paritySign(n) * factorial(2 * n)
                let den = Number.pow(2, 2 * n) * Number.pow(factorial(n), 2) * Number(2 * n + 1)
                return (num / den, 2 * n + 1)
            }
        }

        public static var cos: Summand {
            return { n in
                return (paritySign(n) / factorial(2 * n), 2 * n)
            }
        }
        public static var cosh: Summand {
            return { n in
                return (1 / factorial(2 * n), 2 * n)
            }
        }
        public static var arctan: Summand {
            return { n in
                // Workaround to 'compiler is unable to type-check the expression in reasonable time'
                let num = paritySign(n)
                let den = Number(2 * n + 1)
                return (num / den, 2 * n + 1)
            }
        }
        public static var logPlusOne: Summand {
            return { n in
                if n == 0 { return (0, 0) }
                return (paritySign(n + 1) / Number(n), n)
            }
        }
        /// Gives J_nu(x) / x^nu
        public static func besselJ(_ nu: Number) -> Summand {
            return { n in
                let num = paritySign(n)
                let den = factorial(n) * Number.gamma(nu + Number(n) + 1) * Number.pow(2, Number(2 * n) + nu)
                return (num / den, 2 * n)
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

