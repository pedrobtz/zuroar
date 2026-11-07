# Serialise a bitmap

`roar_serialize()` writes `x` in the portable Roaring format, the one
that the C, C++, Java, Go, Rust and Python implementations share, as a
raw vector. `roar_unserialize()` reads such bytes back into a 32-bit
bitmap and `roar64_unserialize()` into a `zuroar64`. The two formats
share no marker that tells them apart, so the caller chooses the reader;
it is never guessed from the bytes.

## Usage

``` r
roar_serialize(x, optimize = FALSE)

roar_unserialize(bytes, trailing = c("error", "ignore"))

roar64_unserialize(bytes, trailing = c("error", "ignore"))
```

## Arguments

- x:

  A bitmap.

- optimize:

  If `TRUE`, write run-length containers wherever they are smaller, from
  an optimised copy; `x` itself is not changed.

- bytes:

  A raw vector holding a portable bitmap: 32-bit for
  `roar_unserialize()`, 64-bit for `roar64_unserialize()`.

- trailing:

  What to do with bytes after the end of the bitmap: `"error"`, the
  default, or `"ignore"`.

## Value

`roar_serialize()` a raw vector, `roar_unserialize()` a `zuroar` and
`roar64_unserialize()` a `zuroar64`.

## Details

A bitmap also survives
[`saveRDS()`](https://rdrr.io/r/base/readRDS.html),
[`serialize()`](https://rdrr.io/r/base/serialize.html) and a trip to
another R process on its own, through the same format. Use
`roar_serialize()` for bytes that other programs, or other Roaring
libraries, will read.

`roar_unserialize()` treats its input as untrusted. It checks the length
the header claims, reads with CRoaring's bounded deserialiser, which
never reads past the end, and validates the result, so corrupt or
hostile bytes give a `zuroar_error_format` error rather than a crash.

## See also

[`roar_size()`](https://pedrobtz.github.io/zuroar/reference/roar_optimize.md)
for the number of bytes `roar_serialize()` writes.

## Examples

``` r
x <- roar(c(1, 5, 9, 100000))
b <- roar_serialize(x)
b
#>  [1] 3a 30 00 00 02 00 00 00 00 00 02 00 01 00 00 00 18 00 00 00 1e 00 00 00 01
#> [26] 00 05 00 09 00 a0 86
roar_unserialize(b)
#> <zuroar> 4 values in [1, 100000]: 1 5 9 100000

path <- tempfile(fileext = ".roar")
writeBin(roar_serialize(x), path)
roar_unserialize(readBin(path, "raw", file.size(path)))
#> <zuroar> 4 values in [1, 100000]: 1 5 9 100000
```
