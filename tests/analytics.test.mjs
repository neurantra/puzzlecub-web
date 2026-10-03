import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { randomUUID } from "node:crypto";
import { PGlite } from "@electric-sql/pglite";
let db, migration;
before(async () => {
  db = new PGlite();
  // Simulate the previous deployment containing identifying records.
  await db.exec(
    "create schema puzzlecub_usage; create table puzzlecub_usage.usage_visits(id uuid,ip inet); insert into puzzlecub_usage.usage_visits values(gen_random_uuid(),'203.0.113.8');",
  );
  migration = await readFile(
    new URL("../database/analytics.sql", import.meta.url),
    "utf8",
  );
  await db.exec(migration);
});
after(async () => {
  await db.close();
});
async function report(days = 7, game = null) {
  return (
    await db.query("select puzzlecub_usage.aggregate_report($1,$2) as report", [
      days,
      game,
    ])
  ).rows[0].report;
}
async function record({
  id = randomUUID(),
  page = "/alphadoku/mega",
  views = 0,
  plays = 0,
  completions = 0,
  seconds = 0,
  playSeconds = 0,
  pulse = false,
} = {}) {
  await db.query(
    "select puzzlecub_usage.aggregate_record($1,$2,$3,$4,$5,$6,$7,$8)",
    [id, page, views, plays, completions, seconds, playSeconds, pulse],
  );
}
test("migration removes identifying visit storage and disables legacy writes", async () => {
  assert.equal(
    (
      await db.query(
        "select to_regclass('puzzlecub_usage.usage_visits') as name",
      )
    ).rows[0].name,
    null,
  );
  await db.query(
    "select puzzlecub_usage.usage_record($1,null,'/','secret-referrer','device',0,1,'{}','{}',true)",
    [randomUUID()],
  );
  assert.equal((await report()).views, 0);
  const keys = (
    await db.query(
      "select column_name from information_schema.columns where table_schema='puzzlecub_usage' and table_name='aggregate_receipts' order by column_name",
    )
  ).rows.map((r) => r.column_name);
  assert.deepEqual(keys, ["event_id", "expires_at"]);
});
test("counts aggregate views, game actions and duration; duplicate deliveries do not inflate counts", async () => {
  const id = randomUUID();
  await record({ id, views: 1 });
  await record({ id, views: 1 });
  assert.equal((await report()).views, 1);
  assert.equal((await report()).plays, 0);
  await record({ plays: 1 });
  await record({ completions: 1, seconds: 15, playSeconds: 12 });
  const result = await report();
  assert.equal(result.plays, 1);
  assert.equal(result.completions, 1);
  assert.equal(result.activeSeconds, 15);
  assert.equal(result.playSeconds, 12);
  assert.equal(result.gameViews, 1);
  assert.equal(result.daily.length, 7);
  assert.equal("visits" in result, false);
  assert.deepEqual(Object.keys(result.pages[0]).sort(), [
    "activeSeconds",
    "completions",
    "page",
    "playSeconds",
    "plays",
    "views",
  ]);
  // Reapplying the migration keeps anonymous counters intact.
  await db.exec(migration);
  assert.equal((await report()).views, 1);
});
test("game and UTC date filters and zero-filled trends", async () => {
  await record({ page: "/alphadoku/classic", views: 1 });
  await record({ page: "/", views: 1 });
  assert.equal((await report(7, "alphadoku-classic")).views, 1);
  assert.equal((await report(7, "alphadoku-mega")).views, 1);
  assert.equal((await report(7, "unknown")).views, 0);
  await db.exec(
    "insert into puzzlecub_usage.aggregate_daily(day,page,views) values((now() at time zone 'UTC')::date-7,'/',10)",
  );
  assert.equal((await report(7)).views, 3);
  assert.equal((await report(30)).views, 13);
  assert.equal((await report(1)).daily.length, 1);
});
test("online estimate uses anonymous complete buckets and ages out", async () => {
  await db.exec(
    "insert into puzzlecub_usage.aggregate_pulses select to_timestamp(floor(extract(epoch from now())/15)*15) - n * interval '15 seconds','alphadoku-mega',3 from generate_series(1,3) n",
  );
  assert.equal((await report()).onlineEstimate, 3);
  assert.equal((await report(7, "alphadoku-classic")).onlineEstimate, 0);
  await db.exec(
    "update puzzlecub_usage.aggregate_pulses set bucket=bucket-interval '1 minute'",
  );
  assert.equal((await report()).onlineEstimate, 0);
});
test("shared rate limits and retention protect privacy", async () => {
  const key = randomUUID();
  const attempt = async () =>
    (
      await db.query("select puzzlecub_usage.usage_rate_limit($1,1,60) as ok", [
        key,
      ])
    ).rows[0].ok;
  assert.equal(await attempt(), true);
  assert.equal(await attempt(), false);
  await db.exec(
    "update puzzlecub_usage.usage_limits set expires_at=now()-interval '1 second'; update puzzlecub_usage.aggregate_receipts set expires_at=now()-interval '1 second'; insert into puzzlecub_usage.aggregate_daily(day,page,views) values((now() at time zone 'UTC')::date-90,'/',10)",
  );
  await db.query("select puzzlecub_usage.usage_cleanup()");
  assert.equal(
    (await db.query("select * from puzzlecub_usage.aggregate_receipts")).rows
      .length,
    0,
  );
  assert.equal(
    (
      await db.query(
        "select * from puzzlecub_usage.aggregate_daily where day < (now() at time zone 'UTC')::date-89",
      )
    ).rows.length,
    0,
  );
  assert.equal(await attempt(), true);
});
test("public roles cannot read counters or call reporting functions", async () => {
  await db.exec(
    "create role analytics_untrusted; set role analytics_untrusted;",
  );
  await assert.rejects(
    db.query("select * from puzzlecub_usage.aggregate_daily"),
    /permission denied/,
  );
  await assert.rejects(
    db.query("select puzzlecub_usage.aggregate_report(7,null)"),
    /permission denied/,
  );
  await db.exec("reset role");
});

test("Chaturang counters and game filters stay separate from Alphadoku", async () => {
  await record({
    page: "/chaturang",
    views: 1,
    plays: 1,
    completions: 1,
    seconds: 22,
    playSeconds: 18,
    pulse: true,
  });
  await record({ page: "/chaturang", views: 1 });
  const data = await report(7, "chaturang");
  assert.equal(data.views, 2);
  assert.equal(data.gameViews, 2);
  assert.equal(data.plays, 1);
  assert.equal(data.completions, 1);
  assert.equal(data.playSeconds, 18);
  assert.deepEqual(
    data.pages.map((row) => row.page),
    ["/chaturang"],
  );
  assert.equal(
    (
      await db.query(
        "select game from puzzlecub_usage.aggregate_pulses where game='chaturang'",
      )
    ).rows[0].game,
    "chaturang",
  );
});

for (const game of ["mazewords", "slide-and-sort", "mapopia", "fillthejar"]) {
  test(`${game} has independent play counters and online estimates`, async () => {
    await record({
      page: `/${game}`,
      views: 1,
      plays: 1,
      completions: 1,
      seconds: 20,
      playSeconds: 15,
      pulse: true,
    });
    const data = await report(7, game);
    assert.equal(data.views, 1);
    assert.equal(data.gameViews, 1);
    assert.equal(data.plays, 1);
    assert.equal(data.completions, 1);
    assert.equal(data.playSeconds, 15);
    assert.deepEqual(
      data.pages.map((row) => row.page),
      [`/${game}`],
    );
    assert.equal(
      (
        await db.query(
          "select game from puzzlecub_usage.aggregate_pulses where game=$1",
          [game],
        )
      ).rows[0].game,
      game,
    );
  });
}
