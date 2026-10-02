import { test } from "node:test";
import assert from "node:assert/strict";
import { generate, candidates } from "../public/workers/mega-engine.mjs";
for (const tier of ["easy", "medium", "hard", "pro"])
  test(`${tier}: valid board and constructive uniqueness proof across seeds`, () => {
    for (let seed = 0; seed < 12; seed++) {
      const p = generate("test-" + seed, tier);
      assert.equal(p.solution.length, 625);
      const check = (a) => assert.equal(new Set(a).size, 25);
      for (let r = 0; r < 25; r++) {
        check(p.solution.slice(r * 25, r * 25 + 25));
        check(Array.from({ length: 25 }, (_, c) => p.solution[c * 25 + r]));
      }
      for (let b = 0; b < 25; b++)
        check(
          Array.from(
            { length: 25 },
            (_, i) =>
              p.solution[
                (Math.floor(b / 5) * 5 + Math.floor(i / 5)) * 25 +
                  (b % 5) * 5 +
                  (i % 5)
              ],
          ),
        );
      const b = [...p.givens];
      for (const i of [...p.proof].reverse()) {
        assert.deepEqual(candidates(b, i), [p.solution[i]]);
        b[i] = p.solution[i];
      }
      assert.deepEqual(b, p.solution);
      assert(p.proof.length >= 150);
      assert.deepEqual(generate("test-" + seed, tier), p);
    }
  });
test("different seeds produce different boards", () =>
  assert.notDeepEqual(generate("one").givens, generate("two").givens));
