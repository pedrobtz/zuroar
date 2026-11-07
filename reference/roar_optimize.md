# Storage

`roar_optimize()` returns a copy of `x` that uses run-length containers
where they are smaller and holds no spare capacity;
[`roar()`](https://pedrobtz.github.io/zuroar/reference/roar.md) does
this by default. `roar_stats()` describes how `x` is stored: for each
kind of CRoaring container, how many there are, how many values they
hold and how many bytes they use. `roar_size()` is the number of bytes
the portable serialised form of `x` takes.

## Usage

``` r
roar_optimize(x)

roar_stats(x)

roar_size(x)
```

## Arguments

- x:

  A bitmap.

## Value

`roar_optimize()` a bitmap, `roar_stats()` a data frame with columns
`kind`, `containers`, `values` and `bytes`, `roar_size()` a single
double.

## Examples

``` r
x <- roar(c(1:10, 100000:200000), optimize = FALSE)
roar_stats(x)
#>     kind containers values bytes
#> 1  array          2   3403  6806
#> 2 bitset          2  96608 16384
#> 3    run          0      0     0
roar_stats(roar_optimize(x))
#>     kind containers values bytes
#> 1  array          0      0     0
#> 2 bitset          0      0     0
#> 3    run          4 100011    24
roar_size(x)
#> [1] 23230
```
