# conditions snapshot

    Code
      roar(c(1, -2))
    Condition
      Error:
      ! Element 2 is -2; values must be whole numbers from 0 to 4294967295.
    Code
      roar(c(1, 0.5))
    Condition
      Error:
      ! Element 2 is 0.5; values must be whole numbers from 0 to 4294967295.
    Code
      roar(c(TRUE, FALSE))
    Condition
      Error:
      ! `values` is a logical vector. Bitmaps hold whole numbers; use which(values) for the positions of TRUE values.
    Code
      as.integer(roar(2^31))
    Condition
      Error:
      ! The bitmap holds 2147483648, above .Machine$integer.max; use as.double() instead.
    Code
      sum(roar(1))
    Condition
      Error:
      ! sum() is not defined for a zuroar bitmap.

