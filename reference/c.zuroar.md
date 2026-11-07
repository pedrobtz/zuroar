# Combine bitmaps

[`c()`](https://rdrr.io/r/base/c.html) with a bitmap first is the union
of its arguments: bitmaps and whole numbers alike, as
`sort(unique(c(...)))` is for vectors.

## Usage

``` r
# S3 method for class 'zuroar'
c(...)

# S3 method for class 'zuroar64'
c(...)
```

## Arguments

- ...:

  Bitmaps and vectors of whole numbers from 0 to 2^32 - 1.

## Value

A bitmap.

## Examples

``` r
c(roar(c(1, 5)), roar(9), 2)
#> <zuroar> 4 values in [1, 9]: 1 2 5 9
```
