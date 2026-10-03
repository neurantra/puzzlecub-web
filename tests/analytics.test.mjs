import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { randomUUID } from "node:crypto";
import { PGlite } from "@electric-sql/pglite";

let db;
before(async () => {
  db = new PGlite();
  await db.exec(
    await readFile(
      new URL("../database/analytics.sql", import.meta.url),
      "utf8",
    ),
  );
});
after(async () => {
  await db.close();
});
async function report(days = 7, game = null) {
  return (
    await db.query("select puzzlecub_usage.usage_report($1,$2) as report", [
      days,
      game,
    ])
  ).rows[0].report;
}
async function record(
  id,
  {
    seconds = 0,
    sequence = 1,
    games = [],
    completed = [],
    visible = true,
  } = {},
) {
  await db.query(
    "select puzzlecub_usage.usage_record($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)",
    [
      id,
      "203.0.113.8",
      "/alphadoku/mega",
      "google.com",
      "Desktop / other",
      seconds,
      sequence,
      games,
      completed,
      visible,
    ],
  );
}

test("visits require actual game actions; retries and out-of-order heartbeats do not inflate time", async () => {
  const id = randomUUID();
  await record(id);
  assert.equal((await report()).players, 0);
  await db.query(
    "update puzzlecub_usage.usage_visits set last_seen = now() - interval '16 seconds' where id=$1",
    [id],
  );
  await record(id, { seconds: 15, sequence: 2, games: ["alphadoku-mega"] });
  await record(id, { seconds: 9000, sequence: 2, games: ["alphadoku-mega"] });
  await record(id, { seconds: 9000, sequence: 1, visible: false });
  const result = await report();
  const visit = result.visits.find((v) => v.id === id);
  assert.equal(visit.activeSeconds, 15);
  assert.equal(visit.online, true);
  assert.equal(result.players, 1);
  assert.equal(visit.ip, "203.0.113.8");
  await record(id, {
    seconds: 15,
    sequence: 3,
    games: ["alphadoku-mega"],
    completed: ["alphadoku-mega"],
    visible: false,
  });
  assert.equal((await report()).visits.find((v) => v.id === id).online, false);
  assert.equal((await report()).completions, 1);
});

test("reports filter by game, return an empty result, and expire online status", async () => {
  const id = randomUUID();
  await record(id, { games: ["alphadoku-classic"] });
  assert.equal((await report(7, "alphadoku-classic")).total, 1);
  assert.equal((await report(7, "unknown")).total, 0);
  await db.query(
    "update puzzlecub_usage.usage_visits set last_seen = now() - interval '46 seconds' where id=$1",
    [id],
  );
  assert.equal((await report()).visits.find((v) => v.id === id).online, false);
});

test("shared rate limit expires and blocks excess attempts", async () => {
  const key = randomUUID();
  const attempt = async () =>
    (
      await db.query(
        "select puzzlecub_usage.usage_rate_limit($1,2,900) as ok",
        [key],
      )
    ).rows[0].ok;
  assert.equal(await attempt(), true);
  assert.equal(await attempt(), true);
  assert.equal(await attempt(), false);
  await db.query(
    "update puzzlecub_usage.usage_limits set expires_at=now()-interval '1 second' where key=$1",
    [key],
  );
  assert.equal(await attempt(), true);
});

test("retention hides expired IPs immediately and deletes old visit records", async () => {
  const recent = randomUUID(),
    old = randomUUID();
  await record(recent);
  await record(old);
  await db.query(
    "update puzzlecub_usage.usage_visits set started_at=now()-interval '8 days' where id=$1",
    [recent],
  );
  await db.query(
    "update puzzlecub_usage.usage_visits set started_at=now()-interval '91 days' where id=$1",
    [old],
  );
  assert.equal((await report(30)).visits.find((v) => v.id === recent).ip, null);
  await db.query("select puzzlecub_usage.usage_cleanup()");
  assert.equal(
    (
      await db.query(
        "select ip from puzzlecub_usage.usage_visits where id=$1",
        [recent],
      )
    ).rows[0].ip,
    null,
  );
  assert.equal(
    (
      await db.query(
        "select id from puzzlecub_usage.usage_visits where id=$1",
        [old],
      )
    ).rows.length,
    0,
  );
});

test("public roles cannot read usage or execute analytics functions", async () => {
  await db.exec(
    "create role analytics_untrusted; set role analytics_untrusted;",
  );
  await assert.rejects(
    db.query("select * from puzzlecub_usage.usage_visits"),
    /permission denied/,
  );
  await assert.rejects(
    db.query("select puzzlecub_usage.usage_report(7,null)"),
    /permission denied/,
  );
  await db.exec("reset role");
});
