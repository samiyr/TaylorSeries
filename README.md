# TaylorSeries

This package implements a power series expansion for real-analytic functions. It supports user-defined series, truncated either at a fixed index or when a convergence criterion is reached. Included are also some common functions' series representations.

## Example 1: erf(1)
Calculate erf(1), where erf is the [error function](https://en.wikipedia.org/wiki/Error_function), using a known series representation:

```swift
import TaylorSeries

let errorFunctionSeries = TaylorSeries<Double>(summand: TaylorSeries.Common.Expansions.erf)
let erf = errorFunctionSeries.truncatedSeries(precision: 1e-6)
print(String(format: "%.6f", 2 / sqrt(Double.pi) * erf(1.0).value)) // 0.842701
```

The factor `2 / sqrt(Double.pi)` comes from the series representation, see the comment on `TaylorSeries.Common.erf`.

## Example 2: Derivative of Bessel function of the 1<sup>st</sup> kind
This code snippet calculates the value J_0'(2.0), where J is the [Bessel function of the 1<sup>st</sup> kind](https://en.wikipedia.org/wiki/Bessel_function#Bessel_functions_of_the_first_kind:_Jα).

```swift
import TaylorSeries

let besselSeries = TaylorSeries<Double>(summand: TaylorSeries.Common.Expansions.besselJ(0))
let bessel = besselSeries.derivative.truncatedSeries(precision: 1e-16)
print(bessel(2.0).value) // -0.5767248077568736, correct up to the penultimate digit
```

## Example 3: ζ(2)
First, define the [Riemann zeta function](https://en.wikipedia.org/wiki/Riemann_zeta_function) at 2 as a formal power series. The Riemann zeta series doesn't have any x^n terms, but since x^0 = 1, we can cheat a little and set the exponent to always be zero. Then just evaluate the series at some point, say `x = 0` (the actual point doesn't matter).

```swift
import TaylorSeries

let zetaSeries = TaylorSeries<Double>(summand: { n in (1.0 / Double.pow(Double(n + 1), 2), 0) })
let zeta = zetaSeries.truncatedSeries(order: 100000)
print(String(format: "%.4f", zeta(0).value)) // 1.6449
```
