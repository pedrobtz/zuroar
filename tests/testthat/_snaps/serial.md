# format errors snapshot

    Code
      roar_unserialize(as.raw(c(1, 2, 3)))
    Condition
      Error:
      ! Cannot read the bitmap: the bytes are not a complete portable Roaring bitmap (bad cookie, truncated, or a header that claims more bytes than there are).
    Code
      roar_unserialize(c(roar_serialize(roar(1)), as.raw(0)))
    Condition
      Error:
      ! The bitmap ends after 18 of 19 bytes; pass trailing = "ignore" to read it anyway.

