# Benchmarks

This article measures zuroar against two other ways of keeping a set of
whole numbers in R: a plain integer vector with base R’s
[`union()`](https://rdrr.io/r/base/sets.html),
[`intersect()`](https://rdrr.io/r/base/sets.html) and `%in%`, and a bit
vector from the [bit](https://cran.r-project.org/package=bit) package.
Every number below is measured when the site is built, on whatever
machine builds it, so read the tables for their shape rather than their
exact values.

``` r

library(zuroar)
library(bit)
library(bench)
```

## The sets

Values are drawn from 0 to 10 million minus one. A bit vector needs that
whole universe up front; it stores value `v` at position `v + 1`. Three
kinds of set show where each representation is strong:

- **dense**: half of the universe, chosen at random;
- **sparse**: one value in a thousand, chosen at random;
- **runs**: twenty long stretches of consecutive values.

``` r

set.seed(2026)
universe <- 1e7
sets <- list(
  dense = sort(sample(universe, universe / 2) - 1L),
  sparse = sort(sample(universe, universe / 1000) - 1L),
  runs = sort(unique(unlist(lapply(
    seq(0, universe - 400000, length.out = 20),
    function(start) as.integer(start) + 0:199999
  ))))
)
lengths(sets)
#>   dense  sparse    runs 
#> 5000000   10000 4000000

as_bit <- function(v) {
  b <- bit(universe)
  b[v + 1L] <- TRUE
  b
}
```

## Memory

The size of each representation of the first set of each pair. For
zuroar,
[`roar_stats()`](https://pedrobtz.github.io/zuroar/reference/roar_optimize.md)
reports the bytes CRoaring’s containers allocate.
[`object.size()`](https://rdrr.io/r/utils/object.size.html) of a bitmap
reports what it would take expanded, eight bytes a value, because R sees
a vector of that length.

``` r

memory <- do.call(rbind, lapply(names(sets), function(name) {
  v <- sets[[name]]
  data.frame(
    set = name,
    values = length(v),
    integer_vector = as.numeric(object.size(v)),
    bit = as.numeric(object.size(as_bit(v))),
    zuroar = sum(roar_stats(roar(v))$bytes)
  )
}))
memory
#>      set  values integer_vector     bit  zuroar
#> 1  dense 5000000       20000048 1251512 1253376
#> 2 sparse   10000          40048 1251512   20000
#> 3   runs 4000000       16000048 1251512     486
```

## Operations

Each benchmark pairs a set with another of the same kind, drawn the same
way. Inputs are built before timing, so only the operation is measured:
the union and the intersection, each returning a new set, and a
membership test of 10,000 values. `mem_alloc` counts only memory R
allocates; CRoaring allocates its containers with C’s `malloc()`, which
bench does not see, so zuroar’s column understates its memory. The
memory table above is the fair comparison of sizes.

``` r

other <- list(
  dense = sort(sample(universe, universe / 2) - 1L),
  sparse = sort(sample(universe, universe / 1000) - 1L),
  runs = sets$runs + 100000L
)
probe <- sample(universe, 10000) - 1L

run <- function(name) {
  a <- sets[[name]]
  b <- other[[name]]
  ra <- roar(a)
  rb <- roar(b)
  ba <- as_bit(a)
  bb <- as_bit(b)
  marks <- bench::mark(
    `union: base` = union(a, b),
    `union: bit` = ba | bb,
    `union: zuroar` = ra | rb,
    `intersect: base` = intersect(a, b),
    `intersect: bit` = ba & bb,
    `intersect: zuroar` = ra & rb,
    `member: base` = probe %in% a,
    `member: bit` = ba[probe + 1L],
    `member: zuroar` = roar_contains(ra, probe),
    check = FALSE,
    filter_gc = FALSE,
    min_iterations = 5,
    time_unit = "ms"
  )
  data.frame(
    set = name,
    expression = as.character(marks$expression),
    median_ms = round(as.numeric(marks$median), 3),
    mem_alloc = format(marks$mem_alloc)
  )
}
```

``` r

run("dense")
#>     set        expression median_ms mem_alloc
#> 1 dense       union: base   747.778  411.34MB
#> 2 dense        union: bit     0.216    1.29MB
#> 3 dense     union: zuroar     0.444   51.13KB
#> 4 dense   intersect: base   697.803  392.28MB
#> 5 dense    intersect: bit     0.216    1.22MB
#> 6 dense intersect: zuroar     0.101        0B
#> 7 dense      member: base   184.473   83.19MB
#> 8 dense       member: bit     0.033  129.62KB
#> 9 dense    member: zuroar     0.220   78.23KB
```

``` r

run("sparse")
#>      set        expression median_ms mem_alloc
#> 1 sparse       union: base     0.296  892.43KB
#> 2 sparse        union: bit     0.208    1.19MB
#> 3 sparse     union: zuroar     0.029        0B
#> 4 sparse   intersect: base     0.266  736.13KB
#> 5 sparse    intersect: bit     0.210    1.19MB
#> 6 sparse intersect: zuroar     0.010        0B
#> 7 sparse      member: base     0.097  284.48KB
#> 8 sparse       member: bit     0.033   78.22KB
#> 9 sparse    member: zuroar     0.296   78.23KB
```

``` r

run("runs")
#>    set        expression median_ms mem_alloc
#> 1 runs       union: base   273.346  271.48MB
#> 2 runs        union: bit     0.212    1.19MB
#> 3 runs     union: zuroar     0.007        0B
#> 4 runs   intersect: base   281.089  256.22MB
#> 5 runs    intersect: bit     0.213    1.19MB
#> 6 runs intersect: zuroar     0.006        0B
#> 7 runs      member: base    63.367   47.37MB
#> 8 runs       member: bit     0.033   78.22KB
#> 9 runs    member: zuroar     0.200   78.23KB
```

## Reading the results

A bit vector is a fixed array of one bit per possible value, so its
memory and its union and intersection cost depend on the universe, not
on the set. It does well on dense sets and pays the whole universe for
sparse ones. A plain integer vector pays four bytes a value, and base
R’s set functions hash their inputs on every call. zuroar’s containers
adapt to each chunk of 65,536 values, so its size follows the set’s
structure: a few hundred bytes for millions of values in long runs,
about two bytes a value for sparse chunks, and a fixed 8 KiB for each
dense chunk of 65,536 values.

The tables, not this text, say which is faster on the machine that built
this page.
