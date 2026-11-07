# index errors snapshot

    Code
      roar(1:3)[c(1, -2)]
    Condition
      Error:
      ! Positive and negative positions cannot be mixed.
    Code
      roar(1:3)[5]
    Condition
      Error:
      ! Position 5 is past the end of a bitmap of length 3.
    Code
      roar(1:3)[[0]]
    Condition
      Error:
      ! Position 0 is outside 1 to 3.
    Code
      rev(roar(1:3))
    Condition
      Error:
      ! A set has no reversed form; use rev(as.double(x)) for the values in decreasing order.

