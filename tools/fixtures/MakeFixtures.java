// Writes tests/testthat/fixtures/<name>.java.bin for every set in
// tests/testthat/fixtures/sets.txt with Java's RoaringBitmap.serialize(), the
// portable format. Development only; run with tools/fixtures/make-fixtures.
import java.io.DataOutputStream;
import java.io.FileOutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import org.roaringbitmap.RoaringBitmap;
import org.roaringbitmap.longlong.Roaring64NavigableMap;

public class MakeFixtures {
  public static void main(String[] args) throws Exception {
    Path root = Paths.get(args.length > 0 ? args[0] : ".");
    Path out = root.resolve("tests/testthat/fixtures");
    for (String line : Files.readAllLines(out.resolve("sets.txt"))) {
      if (line.isEmpty() || line.startsWith("#")) continue;
      String[] f = line.split("\t", -1);
      RoaringBitmap bm = new RoaringBitmap();
      for (long[] p : pieces(f[2])) {
        if (p[2] == 0) {
          bm.add(p[0], p[1] + 1);
        } else {
          for (long v = p[0]; v <= p[1]; v += p[2]) bm.add((int) v);
        }
      }
      if (f[1].equals("1")) bm.runOptimize();
      try (DataOutputStream os =
          new DataOutputStream(new FileOutputStream(out.resolve(f[0] + ".java.bin").toFile()))) {
        bm.serialize(os);
      }
      System.out.println("java " + f[0] + " " + bm.getLongCardinality() + " values");
    }
    for (String line : Files.readAllLines(out.resolve("sets64.txt"))) {
      if (line.isEmpty() || line.startsWith("#")) continue;
      String[] f = line.split("\t", -1);
      Roaring64NavigableMap bm = new Roaring64NavigableMap();
      for (long[] p : pieces(f[2])) {
        if (p[2] == 0) {
          // Unsigned ends: addRange takes [from, to) as unsigned longs, and
          // to = 2^64 does not fit, so the last value is added separately.
          if (p[1] == -1L) {
            if (p[0] != -1L) bm.addRange(p[0], p[1]);
            bm.addLong(p[1]);
          } else {
            bm.addRange(p[0], p[1] + 1);
          }
        } else {
          // Stop before v + step wraps past 2^64 - 1.
          for (long v = p[0]; ; v += p[2]) {
            bm.addLong(v);
            if (Long.compareUnsigned(v, p[1] - p[2]) > 0 || Long.compareUnsigned(p[1], p[2]) < 0) break;
          }
        }
      }
      if (f[1].equals("1")) bm.runOptimize();
      try (DataOutputStream os =
          new DataOutputStream(new FileOutputStream(out.resolve(f[0] + ".java64.bin").toFile()))) {
        bm.serializePortable(os);
      }
      System.out.println("java64 " + f[0] + " " + bm.getLongCardinality() + " values");
    }
  }

  /** Pieces as {from, to, step}, unsigned; step 0 for a plain range. */
  static List<long[]> pieces(String spec) {
    List<long[]> out = new java.util.ArrayList<>();
    for (String piece : spec.split(",")) {
      if (piece.isEmpty()) continue;
      long step = 0;
      int slash = piece.indexOf('/');
      if (slash >= 0) {
        step = Long.parseLong(piece.substring(slash + 1));
        piece = piece.substring(0, slash);
      }
      int dash = piece.indexOf('-');
      long a = Long.parseUnsignedLong(dash >= 0 ? piece.substring(0, dash) : piece);
      long b = dash >= 0 ? Long.parseUnsignedLong(piece.substring(dash + 1)) : a;
      if (dash < 0) step = 1;
      out.add(new long[] {a, b, step});
    }
    return out;
  }
}
