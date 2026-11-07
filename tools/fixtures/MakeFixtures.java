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

public class MakeFixtures {
  public static void main(String[] args) throws Exception {
    Path root = Paths.get(args.length > 0 ? args[0] : ".");
    Path out = root.resolve("tests/testthat/fixtures");
    Files.createDirectories(out);
    List<String> lines = Files.readAllLines(root.resolve("tests/testthat/fixtures/sets.txt"));
    for (String line : lines) {
      if (line.isEmpty() || line.startsWith("#")) continue;
      String[] f = line.split("\t", -1);
      RoaringBitmap bm = new RoaringBitmap();
      for (String piece : f[2].split(",")) {
        if (piece.isEmpty()) continue;
        int slash = piece.indexOf('/');
        int dash = piece.indexOf('-');
        if (slash >= 0) {
          long a = Long.parseLong(piece.substring(0, dash));
          long b = Long.parseLong(piece.substring(dash + 1, slash));
          long step = Long.parseLong(piece.substring(slash + 1));
          for (long v = a; v <= b; v += step) bm.add((int) v);
        } else if (dash >= 0) {
          long a = Long.parseLong(piece.substring(0, dash));
          long b = Long.parseLong(piece.substring(dash + 1));
          bm.add(a, b + 1);
        } else {
          bm.add((int) Long.parseLong(piece));
        }
      }
      if (f[1].equals("1")) bm.runOptimize();
      try (DataOutputStream os =
          new DataOutputStream(new FileOutputStream(out.resolve(f[0] + ".java.bin").toFile()))) {
        bm.serialize(os);
      }
      System.out.println(f[0] + " " + bm.getLongCardinality() + " values");
    }
  }
}
