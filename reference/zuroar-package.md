# zuroar: Compressed Sets of Unsigned Integers with 'Roaring' Bitmaps

Compressed sets of unsigned integers from 0 to 2^32 - 1, and up to
2^64 - 1, built on a bundled copy of 'CRoaring', the reference C
implementation of 'Roaring' bitmaps (Lemire et al. 2018
[doi:10.1002/spe.2560](https://doi.org/10.1002/spe.2560) ). A bitmap
answers membership, cardinality, rank, select and the set operations
without materialising a vector, and serialises to the portable 'Roaring'
format shared by implementations in 'Java', 'Go', 'Rust' and 'Python'.
To R code a bitmap behaves as a sorted vector without duplicates.

## See also

Useful links:

- <https://pedrobtz.github.io/zuroar/>

- <https://github.com/pedrobtz/zuroar>

- Report bugs at <https://github.com/pedrobtz/zuroar/issues>

## Author

**Maintainer**: Pedro Baltazar <pedrobtz@gmail.com> \[copyright holder\]

Authors:

- Pedro Baltazar <pedrobtz@gmail.com> \[copyright holder\]

Other contributors:

- The CRoaring authors (the bundled CRoaring library) \[copyright
  holder\]
