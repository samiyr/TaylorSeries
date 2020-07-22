import Foundation
import RealModule

/// Represents a Taylor Series expansion for a real-analytic function
/// around some expansion point.
public struct TaylorSeries<Number: Real> {
    /// A wrapper which includes the actual result of the computation as well as diagnostic information.
    public struct ExpansionResult {
        /// The actual computation result.
        public let value: Number
        /// Diagnostic information regarding the computation.
        public let info: Set<Info>
        
        /// Possible diagnostic/warning messages.
        public enum Info: Hashable {
            /// The set `maxIterations` was reached. Includes the achieved precision before the computation was stopped, if available.
            case maxIterationsReached(reachedPrecision: Number?)
            /// Divergent series detected.
            case divergenceSuspected
            /// One of the computation steps resulted in `NaN` (not a number). Returning the previous result.
            case nan
            /// One of the computation steps resulted in `inf` (infinity). Returning the previous result.
            case infinity
        }
    }
    /// Represents the Taylor remainder term.
    public struct RemainderEstimate {
        /// A closure which gives a uniform bound `|f^(n + 1)(x)| <= M` on the interval `(center - x, center + x)`.
        public let bound: (_ n: Int, _ x: Number, _ center: Number) -> (Number)
        /// Calculates the actual remainder size estimate based on the given `bound`.
        public func size(_ k: Int, _ x: Number, _ center: Number) -> Number {
            let r = abs(x - center)
            return bound(k + 1, x, center) * Number.pow(r, k + 1) / TaylorSeries.factorial(k + 1)
        }
    }
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
    /// The expansion point. Defaults to 0 (in which case the series are known as Maclaurin series).
    public var center: Number = 0
    
    /// Returns a truncated series with terms from `start` up to `order`.
    /// - Parameter order: The order of the expansion, higher orders yield more accurate results at the cost of increased resource usage.
    /// - Returns: A callable closure which acts like a function. Calculates the approximate value of a function at the given input point.
    /// - Note: This function provides "direct access" and doesn't perform any checks that `truncatedSeries(precision: maxIterations:)` does.
    public func truncatedSeries(order: Int) -> (Number) -> (ExpansionResult) {
        return { x in
            return ExpansionResult(value: (start...order).map {
                let term = summand($0)
                return term.0  * Number.pow(x - center, term.1)
            }.reduce(0, +), info: [])
        }
    }
    
    /// Returns a truncated series, where the series is truncated at an appropariate point such that the difference between the last two terms is less than `precision`. However, the number of iterations is capped at `maxIterations`, which defaults to 1000.
    ///
    /// - Warning: Note that `precision` does not guarantee correct digits, see `testBesselJ()` in `TaylorSeriesTests.swift`. To guarantee correct digits, use Taylor's theorem to obtain an appropriate truncating index and use `truncatedSeries(order:)` directly.
    /// - Parameter precision: The convergence criterion. The series is truncated once the last two terms are at most `precision` apart from each other (unless `maxIterations` is reached).
    /// - Parameter maxIterations: Sets a hard cap on the number of iterations, stopping even if the convergence criterion hasn't been reached.
    /// - Returns: A callable closure which acts like a function. Calculates the approximate value of a function at the given input point.
    public func truncatedSeries(precision: Number, maxIterations: Int = 1000) -> (Number) -> (ExpansionResult) {
        func divergenceCheck(_ deltas: [Number]) -> Bool {
            if let first = deltas.first, let last = deltas.last, first < last {
                return true
            }
            return false
        }
        return { x in
            var value = Number(0)
            var prev = Number(0)
            var nonzeroFlag = false
            var i = start
            var deltas = [Number]()
            repeat {
                if i > maxIterations {
                    let max = ExpansionResult.Info.maxIterationsReached(reachedPrecision: abs(value - prev))
                    var info: Set<ExpansionResult.Info> = [max]
                    if divergenceCheck(deltas) {
                        info.insert(.divergenceSuspected)
                    }
                    return ExpansionResult(value: value, info: info)
                }
                prev = value
                let term = summand(i)
                let termValue = term.0 * Number.pow(x - center, term.1)
                guard !termValue.isInfinite else {
                    let inf = ExpansionResult.Info.infinity
                    var info: Set<ExpansionResult.Info> = [inf]
                    if divergenceCheck(deltas) {
                        info.insert(.divergenceSuspected)
                    }
                    return ExpansionResult(value: prev, info: info)
                }
                guard !termValue.isNaN && !termValue.isSignalingNaN else {
                    let nan = ExpansionResult.Info.nan
                    var info: Set<ExpansionResult.Info> = [nan]
                    if divergenceCheck(deltas) {
                        info.insert(.divergenceSuspected)
                    }
                    return ExpansionResult(value: prev, info: info)
                }
                value += termValue
                if !termValue.isZero { nonzeroFlag = true }
                deltas.append(abs(value - prev))
                i += 1
            } while abs(value - prev) >= precision || !nonzeroFlag
            let info: Set<ExpansionResult.Info> = divergenceCheck(deltas) ? [ExpansionResult.Info.divergenceSuspected] : []
            return ExpansionResult(value: value, info: info)
        }
    }
    
    /// Returns a truncated series, where the series is truncated at an appropariate point such that the result is guaranteed to have at least the requested precision. This requires knowledge of the function, see the parameter `remainder`. However, the number of iterations is capped at `maxIterations` if it's set.
    ///
    /// - Parameter precision: The precision requested. This means that the difference between the approximate value returned by this function and the true value of the function is at most `precision`, per Taylor's theorem.
    /// - Parameter remainder: A `RemainderEstimate` object, which encapsulates the required knowledge of the function's behaviour to apply Taylor's theorem and guarantee correctness.
    /// - Parameter maxIterations: Sets a hard cap on the number of iterations, stopping even if the precision cannot be guaranteed. Defaults to `nil`, which means no limit.
    /// - Returns: A callable closure which acts like a function. Calculates the approximate value of a function at the given input point.
    public func truncatedSeries(precision: Number, remainder: RemainderEstimate, maxIterations: Int? = nil) -> (Number) -> (ExpansionResult) {
        return { x in
            // Rough search
            var n = 1
            repeat {
                n *= 2
            } while remainder.size(n, x, center) > precision
            
            // Binary search
            var upper = n
            var lower = n / 2
            repeat {
                let middle = (upper + lower + 1) / 2 // + 1 guarantees that the result is rounded up without having to convert to Number
                if remainder.size(middle, x, center) > precision {
                    lower = middle
                } else {
                    upper = middle
                }
            } while upper - lower > 1
            
            let order: Int
            if let maxIter = maxIterations {
                order = max(upper, maxIter)
            } else {
                order = upper
            }
            
            var result = truncatedSeries(order: order)(x)
            
            guard !result.value.isNaN && !result.value.isSignalingNaN else {
                return ExpansionResult(value: .nan, info: [.nan])
            }
            guard !result.value.isInfinite else {
                return ExpansionResult(value: .infinity, info: [.infinity])
            }
            
            if let maxIter = maxIterations, upper > maxIter {
                var info = result.info
                info.insert(.maxIterationsReached(reachedPrecision: nil))
                result = ExpansionResult(value: result.value, info: info)
            }
            return result
        }
    }
    
    /// Yields the first-order derivative of the series.
    /// - SeeAlso: derivative()
    public var derivative: TaylorSeries {
        return derivative()
    }
    
    /// Yields the derivative series of order `order` of the original series. The derivative is calculated by differentiating term-by-term, which in a power series amounts to multiplying the coefficient by some constant (determined by the `order`) and reducing the powers.
    /// - Parameter order: The number of times the derivative operator is applied. Defaults to 1 and must be non-negative. If `order <= 0`, the original series is returned.
    /// - Returns: A new series where the `summand` corresponds to the `order`:th derivative series.
    /// - Warning: The derivative series is not guaranteed to converge even if the original series did. It's up to you to check convergence.
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
    /// Defines some common series terms for ease of use. All of these are Maclaurin series, i.e. `center = 0`.
    public struct Common {
        public struct Expansions {
            /// `1 / (1 - x)`, converges on the interval `(-1, 1)`.
            public static var geometric: Summand {
                return { n in
                    return (1, n)
                }
            }
            /// `exp(x)`, converges on the entire real axis.
            public static var exp: Summand {
                return { n in
                    return (1 / factorial(n), n)
                }
            }
            /// `sin(x)`, converges on the entire real axis.
            public static var sin: Summand {
                return { n in
                    return (paritySign(n) / factorial(2 * n + 1), 2 * n + 1)
                }
            }
            /// `sinh(x)`, converges on the entire real axis.
            public static var sinh: Summand {
                return { n in
                    return (1 / factorial(2 * n + 1), 2 * n + 1)
                }
            }
            /// `arcsin(x)`, converges on the interval `(-1 , 1)`.
            public static var arcsin: Summand {
                return { n in
                    let num = factorial(2 * n)
                    let den = Number.pow(2, 2 * n) * Number.pow(factorial(n), 2) * Number(2 * n + 1)
                    return (num / den, 2 * n + 1)
                }
            }
            /// `arcsinh(x)`, converges on the interval `(-1, 1)`.
            public static var arcsinh: Summand {
                return { n in
                    let num = paritySign(n) * factorial(2 * n)
                    let den = Number.pow(2, 2 * n) * Number.pow(factorial(n), 2) * Number(2 * n + 1)
                    return (num / den, 2 * n + 1)
                }
            }
            /// `cos(x)`, converges on the entire real axis.
            public static var cos: Summand {
                return { n in
                    return (paritySign(n) / factorial(2 * n), 2 * n)
                }
            }
            /// `cosh(x)`, converges on the entire real axis.
            public static var cosh: Summand {
                return { n in
                    return (1 / factorial(2 * n), 2 * n)
                }
            }
            /// `arctan(x)`, converges on the interval `[-1, 1]`.
            public static var arctan: Summand {
                return { n in
                    // Workaround to 'compiler is unable to type-check the expression in reasonable time'
                    let num = paritySign(n)
                    let den = Number(2 * n + 1)
                    return (num / den, 2 * n + 1)
                }
            }
            /// `arctanh(x)`, converges on the interval `(-1, 1)`.
            public static var arctanh: Summand {
                return { n in
                    return (1 / Number(2 * n + 1), 2 * n + 1)
                }
            }
            /// `log(1 + x)`, converges on the interval `(-1, 1]`.
            public static var logPlusOne: Summand {
                return { n in
                    if n == 0 { return (0, 0) }
                    return (paritySign(n + 1) / Number(n), n)
                }
            }
            /// `J_nu(x) / x^nu`(where `J_nu` is the Bessel function of the 1st kind)
            public static func besselJ(_ nu: Number) -> Summand {
                return { n in
                    let num = paritySign(n)
                    let den = factorial(n) * Number.gamma(nu + Number(n) + 1) * Number.pow(2, Number(2 * n) + nu)
                    return (num / den, 2 * n)
                }
            }
            /// `erf(x) * sqrt(pi) / 2`(where `erf(x)` is the error function)
            public static var erf: Summand {
                return { n in
                    let num = paritySign(n)
                    let den = factorial(n) * Number(2 * n + 1)
                    return (num / den, 2 * n + 1)
                }
            }
        }
        public struct Remainders {
            /// `sin(x)`, converges on the entire real axis.
            public static var sin: RemainderEstimate {
                return RemainderEstimate { (n, x, c) -> (Number) in
                    return 1
                }
            }
            /// `cos(x)`, converges on the entire real axis.
            public static var cos: RemainderEstimate {
                return RemainderEstimate { (n, x, c) -> (Number) in
                    return 1
                }
            }
        }
    }
    
    // Helper functions, which define commonly needed functions when working with Taylor series.
    
    /// Factorial, n! = n * (n-1) * (n-2) * ... * 2 * 1.
    /// 0! = 1! = 1
    public static func factorial(_ n: Int) -> Number {
        return Number.gamma(Number(n + 1))
    }

    /// Gives `(-1)^n` as a `Number`.
    public static func paritySign(_ n: Int) -> Number {
        if n % 2 == 0 {
            return 1
        } else {
            return -1
        }
    }

}

