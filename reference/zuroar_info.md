# What zuroar was built with

Reports the bundled CRoaring version, the SIMD code paths compiled into
the package, and the instruction sets this processor offers. CRoaring
picks the fastest compiled path the processor supports when it runs, so
the same binary works on any x86-64 or arm64 machine.

## Usage

``` r
zuroar_info()
```

## Value

A list with elements:

- `croaring`: the CRoaring version, a string such as `"5.4.0"`.

- `compiled`: the SIMD paths compiled in, a subset of `"avx2"`,
  `"avx512"` and `"neon"`. Empty for a scalar build.

- `runtime`: the instruction sets CRoaring detected on this processor, a
  subset of `"avx2"`, `"avx512"`, `"sve"` and `"sve2"`.

## Examples

``` r
zuroar_info()
#> $croaring
#> [1] "5.4.0"
#> 
#> $compiled
#> [1] "avx2"   "avx512"
#> 
#> $runtime
#> [1] "avx2"   "avx512"
#> 
```
