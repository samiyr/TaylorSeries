# TaylorSeries

This package implements a power series expansion for real-analytic functions. It supports user-defined series, truncated either at a fixed index or when a convergence criterion is reached. Included are also some common functions' series representations.

## Example: Bessel function of the 1<sup>st</sup> kind
This code snippet calculates the value J_0(2.0), where J is the [Bessel function of the 1<sup>st</sup> kind](https://en.wikipedia.org/wiki/Bessel_function#Bessel_functions_of_the_first_kind:_Jα).

```swift
import TaylorSeries

let besselSeries = TaylorSeries<Double>(summand: TaylorSeries.Common.besselJ(0))
let bessel = besselSeries.truncatedSeries(center: 0, to: 1e-16)
print(bessel(2.0)) // 0.22389077914123562, correct up to the penultimate digit
```
