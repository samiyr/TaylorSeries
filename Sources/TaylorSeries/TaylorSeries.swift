import Foundation

/// Represents a Taylor Series expansion for some real-analytic function.
public struct TaylorSeries {
    public typealias Summand = (Double, Int) -> (Double)
    /// Terms to be summed. This must include everything in one package, including the (x - x_0)^n and n! parts. The reason for this is that it allows some sums (like sin and cos) to be defined more easily.
    public var summand: Summand
    /// Start index of the sum. Defaults to 0.
    public var start: Int = 0
    
    /// Returns a callable closure with the series centered at `center` and truncated at `up`.
    public func truncatedSeries(center: Double, up to: Int) -> (Double) -> (Double) {
        return { x in
            return (start...to).map { summand(x - center, $0) }.reduce(0, +)
        }
    }
    /// Returns a callable closure where the series is truncated at an appropariate point such that the difference between the last two terms is less than `epsilon`. However, the summing is capped by `max`, which defaults to 1000.
    public func truncatedSeries(center: Double, to epsilon: Double, max iterations: Int = 1000) -> (Double) -> (Double) {
        return { x in
            var value = 0.0
            var prev = 0.0
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
        public static let geometric: Summand = { x, n in
            return pow(x, Double(n))
        }
        public static let exp: Summand = { x, n in
            return pow(x, Double(n)) / factorial(n)
        }
        public static let sin: Summand = { x, n in
            return paritySign(n) * pow(x, Double(2 * n + 1)) / factorial(2 * n + 1)
        }
        public static let sinh: Summand = { x, n in
            return pow(x, Double(2 * n + 1)) / factorial(2 * n + 1)
        }
        public static let arcsin: Summand = { x, n in
            let num = factorial(2 * n) * pow(x, Double(2 * n + 1))
            let den = pow(2, Double(2 * n)) * pow(factorial(n), 2) * Double(2 * n + 1)
            return num / den
        }
        public static let cos: Summand = { x, n in
            return paritySign(n) * pow(x, Double(2 * n)) / factorial(2 * n)
        }
        public static let cosh: Summand = { x, n in
            return pow(x, Double(2 * n)) / factorial(2 * n)
        }
        public static let arctan: Summand = { x, n in
            // Workaround to 'compiler is unable to type-check the expression in reasonable time'
            let num = paritySign(n) * pow(x, Double(2 * n + 1))
            let den = Double(2 * n + 1)
            return num / den
        }
        public static let logPlusOne: Summand = { x, n in
            if n == 0 { return 0 }
            return paritySign(n + 1) * pow(x, Double(n)) / Double(n)
        }
    }
    
    // Helper functions, which define commonly needed functions when working with Taylor series.
    
    /// Factorial, n! = n * (n-1) * (n-2) * ... * 2 * 1.
    /// 0! = 1! = 1
    public static func factorial(_ n: Int) -> Double {
        if n == 0 || n == 1 { return 1 }
        return (1...n).map(Double.init).reduce(1.0, *)
    }

    /// Gives (-1)^n as a `Double`.
    public static func paritySign(_ n: Int) -> Double {
        if n % 2 == 0 {
            return 1
        } else {
            return -1
        }
    }

}

