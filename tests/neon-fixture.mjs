// Local integration-test transport. This file is never imported by the application.
// It substitutes PostgreSQL over HTTP with a real, in-memory PostgreSQL engine.
import { PGlite } from "@electric-sql/pglite";
import { readFile } from "node:fs/promises";
if (process.env.PUZZLECUB_TEST_DATABASE !== "1")
  throw new Error("Test transport requires explicit opt-in");
const originalFetch = globalThis.fetch;
let database;
globalThis.fetch = async (input, init) => {
  const url =
    typeof input === "string"
      ? input
      : input instanceof URL
        ? input.href
        : input.url;
  if (
    url !== "https://api.neon.tech/sql" ||
    !new Headers(init?.headers)
      .get("Neon-Connection-String")
      ?.includes("@puzzlecub-test.neon.tech/")
  )
    return originalFetch(input, init);
  database ??= (async () => {
    const db = new PGlite();
    await db.exec(
      await readFile(
        new URL("../database/analytics.sql", import.meta.url),
        "utf8",
      ),
    );
    return db;
  })();
  const db = await database;
  const { query, params } = JSON.parse(init.body);
  try {
    const result = await db.query(query, params);
    return Response.json({
      ...result,
      rows: result.rows.map((row) =>
        result.fields.map((field) => {
          const value = row[field.name];
          if (value == null) return null;
          return typeof value === "object"
            ? JSON.stringify(value)
            : typeof value === "boolean"
              ? value
                ? "t"
                : "f"
              : String(value);
        }),
      ),
    });
  } catch (error) {
    return Response.json(
      { message: error.message, code: error.code },
      { status: 400 },
    );
  }
};
