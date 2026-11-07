# the data pointer is refused with a message naming as.double()

    Code
      test_dataptr(roar(1))
    Condition
      Error:
      ! This operation needs the bitmap as a plain vector, which zuroar never builds on its own. Use as.double(x) to expand it, or a bounded query such as head(x) or roar_contains().
    Code
      roar(c(2, 4))[3]
    Condition
      Error:
      ! Position 3 is outside 1 to 2, the positions of this bitmap.

