# Writes tests/testthat/fixtures/<name>.pyroaring.bin for every set in
# tests/testthat/fixtures/sets.txt with pyroaring's BitMap.serialize(), the portable
# format. Development only; run with tools/fixtures/make-fixtures.
#
#   uv run --no-project --with pyroaring==1.2.0 python -I tools/fixtures/make_pyroaring.py
import pathlib
import sys

import pyroaring

root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".")
out = root / "tests" / "testthat" / "fixtures"
out.mkdir(parents=True, exist_ok=True)

for line in (root / "tests" / "testthat" / "fixtures" / "sets.txt").read_text().splitlines():
    if not line or line.startswith("#"):
        continue
    name, optimize, pieces = (line.split("\t") + [""])[:3]
    bm = pyroaring.BitMap()
    for piece in filter(None, pieces.split(",")):
        if "/" in piece:
            span, step = piece.split("/")
            a, b = (int(p) for p in span.split("-"))
            bm.update(list(range(a, b + 1, int(step))))
        elif "-" in piece:
            a, b = (int(p) for p in piece.split("-"))
            bm.add_range(a, b + 1)
        else:
            bm.add(int(piece))
    if optimize == "1":
        bm.run_optimize()
    (out / f"{name}.pyroaring.bin").write_bytes(bm.serialize())
    print(name, len(bm), "values")
print("pyroaring", pyroaring.__version__)
