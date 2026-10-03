import { readdirSync, readFileSync, writeFileSync, existsSync } from "node:fs";
import { createHash } from "node:crypto";
import { join } from "node:path";
function files(path) {
  return readdirSync(path, { withFileTypes: true })
    .filter((e) => e.name !== ".DS_Store")
    .flatMap((e) =>
      e.isDirectory() ? files(join(path, e.name)) : [join(path, e.name)],
    )
    .sort();
}
for (const game of ["mazewords", "slide-and-sort", "mapopia", "fillthejar"]) {
  const root = `${game}-game`,
    hash = createHash("sha256");
  const inputs = [
    ...files(`${root}/lib`),
    ...files(`${root}/web`),
    ...files(`${root}/assets`),
    `${root}/pubspec.yaml`,
    `${root}/pubspec.lock`,
  ];
  if (game === "mazewords") inputs.push(...files(`${root}/pack_hosting`));
  for (const path of inputs.sort()) {
    hash.update(path);
    hash.update(readFileSync(path));
  }
  const digest = hash.digest("hex"),
    output = `public/${root}/source-sha256.txt`;
  if (process.argv.includes("--write")) writeFileSync(output, digest + "\n");
  else if (
    !existsSync(output) ||
    readFileSync(output, "utf8").trim() !== digest
  ) {
    console.error(
      `${game} build is missing or stale. Run npm run build:collection.`,
    );
    process.exit(1);
  } else console.log(`${game} source matches its bundled web build.`);
}
