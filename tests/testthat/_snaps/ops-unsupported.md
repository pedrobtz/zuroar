# unsupported operators snapshot

    Code
      !roar(1)
    Condition
      Error:
      ! Unary ! is not defined for a bitmap. Use roar_flip() over a range.
    Code
      roar(1) - roar(2)
    Condition
      Error:
      ! `-` between bitmaps is not defined. Use roar_andnot(x, y) for the difference.
    Code
      roar(1) > 5
    Condition
      Error:
      ! `>` between a bitmap and a number is not defined: it would expand the set. Use `&` with roar_range(), or roar_contains().
    Code
      roar(c(0, 4294967295)) + 1
    Condition
      Error:
      ! Shifting by 1 moves values outside 0 to 4294967295. Use roar_shift(drop = TRUE) to drop them.

