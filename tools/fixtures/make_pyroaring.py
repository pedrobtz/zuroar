# Writes the pyroaring fixtures: tests/testthat/fixtures/<name>.pyroaring.bin
# for every set in sets.txt with BitMap.serialize(), and
# <name>.pyroaring64.bin for every set in sets64.txt with BitMap64, both the
# portable format. Development only; run with tools/fixtures/make-fixtures.
#
#   uv run --no-project --with pyroaring==1.2.0 python -I tools/fixtures/make_pyroaring.py .
import pathlib
import sys

import pyroaring

root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".")
fixtures = root / "tests" / "testthat" / "fixtures"


def sets(path):
    for line in path.read_text().splitlines():
        if not line or line.startswith("#"):
            continue
        yield (line.split("\t") + [""])[:3]


def build(cls, pieces, optimize):
    bm = cls()
    for piece in filter(None, pieces.split(",")):
        if "/" in piece:
            span, step = piece.split("/")
            a, b = (int(p) for p in span.split("-"))
            # A list: update() with a stepped range does not finish.
            bm.update(list(range(a, b + 1, int(step))))
        elif "-" in piece:
            a, b = (int(p) for p in piece.split("-"))
            # The end is exclusive and 2^64 does not fit in 64 bits, so the
            # last value of the domain is added on its own.
            if b == 2**64 - 1:
                bm.add_range(a, b)
                bm.add(b)
            else:
                bm.add_range(a, b + 1)
        else:
            bm.add(int(piece))
    if optimize == "1":
        bm.run_optimize()
    return bm


for cls, spec, suffix in [
    (pyroaring.BitMap, "sets.txt", "pyroaring"),
    (pyroaring.BitMap64, "sets64.txt", "pyroaring64"),
]:
    for name, optimize, pieces in sets(fixtures / spec):
        bm = build(cls, pieces, optimize)
        (fixtures / f"{name}.{suffix}.bin").write_bytes(bm.serialize())
        print(suffix, name, len(bm), "values")
print("pyroaring", pyroaring.__version__)
