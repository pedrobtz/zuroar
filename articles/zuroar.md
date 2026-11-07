# Get started with zuroar

zuroar gives R compressed sets of whole numbers from 0 to 2^32 - 1, or
to 2^64 - 1 with the 64-bit class. Dense stretches and long runs take a
fraction of the memory of a plain vector, and membership, counts and set
operations work without expanding them. Bitmaps are written in the
portable Roaring format that Python, Java, Go and Rust programs share.

``` r

library(zuroar)
```

## Build a bitmap

[`roar()`](https://pedrobtz.github.io/zuroar/reference/roar.md) takes
whole numbers in any order, with or without duplicates.
[`roar_range()`](https://pedrobtz.github.io/zuroar/reference/roar.md)
takes both ends of a range, included as in
[`seq()`](https://rdrr.io/r/base/seq.html), and
[`roar_add()`](https://pedrobtz.github.io/zuroar/reference/roar_add.md)
and
[`roar_remove()`](https://pedrobtz.github.io/zuroar/reference/roar_add.md)
return a changed copy.

``` r

x <- roar(c(1L, 5L, 9L, 100000L))
x <- roar_add(x, 7L)
x <- roar_remove(x, 5L)
y <- roar_range(1, 1e6)
y <- roar_remove(y, from = 10, to = 19)
```

## Use it like a sorted vector

A bitmap behaves like `sort(unique(v))`:
[`length()`](https://rdrr.io/r/base/length.html) counts its values,
positions start at 1, `[` returns a bitmap and `[[` a single value.
[`c()`](https://rdrr.io/r/base/c.html) is the union, and adding a number
shifts every value.

``` r

length(x)
#> [1] 4
x[[2]]
#> [1] 7
x[2:3]
head(y, 3)
c(x, roar(42L)) + 10
```

## Ask questions

[`roar_contains()`](https://pedrobtz.github.io/zuroar/reference/roar_contains.md)
is the fast membership test. Ranges are inclusive,
[`roar_rank()`](https://pedrobtz.github.io/zuroar/reference/roar_rank.md)
counts the values at or below one,
[`roar_select()`](https://pedrobtz.github.io/zuroar/reference/roar_rank.md)
finds the `k`-th smallest, and
[`roar_next()`](https://pedrobtz.github.io/zuroar/reference/roar_rank.md)
the nearest value above.

``` r

roar_contains(x, c(5L, 6L))
#> [1] FALSE FALSE
roar_count(y, from = 10, to = 20)
#> [1] 1
roar_rank(x, 9L)
#> [1] 3
roar_select(x, c(1, 2))
#> [1] 1 7
roar_next(x, 8L)
#> [1] 9
```

## Combine sets

Between bitmaps, `|` is the union, `&` the intersection and `<=` a
subset test. Counts and similarities need no intermediate bitmap.

``` r

x | y
x & y
x <= y
roar_cardinality(x, y, op = "and")
roar_jaccard(x, y)
```

## Save and share

[`roar_serialize()`](https://pedrobtz.github.io/zuroar/reference/roar_serialize.md)
writes the portable format as a raw vector, and
[`roar_unserialize()`](https://pedrobtz.github.io/zuroar/reference/roar_serialize.md)
checks bytes before reading them. A bitmap doesn’t survive
[`saveRDS()`](https://rdrr.io/r/base/readRDS.html) on its own;
[`roar_serial_config()`](https://pedrobtz.github.io/zuroar/reference/roar_serial_config.md)
lets it travel to mirai workers.

``` r

b <- roar_serialize(x)
x2 <- roar_unserialize(b)
mirai::daemons(2, serial = roar_serial_config())
```

## Next

The reference index documents every function, including the 64-bit
class, `roar64()`. An article with benchmarks against base R and the bit
package is planned.
