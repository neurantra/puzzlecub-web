import { test, expect } from "@playwright/test";
import { randomUUID } from "node:crypto";
test.skip(
  process.env.PUZZLECUB_TEST_DATABASE !== "1",
  "Requires isolated analytics test server",
);
const password = "local-analytics-test-password";
test.use({ userAgent: "Mozilla/5.0 PuzzleCubIntegrationTest" });

test("private dashboard shows aggregate counters only; ingestion rejects identifying fields", async ({
  page,
  request,
  baseURL,
}) => {
  expect((await request.get("/api/admin/usage")).status()).toBe(401);
  expect(
    (
      await request.post("/api/admin/login", {
        headers: { origin: "https://evil.example" },
        form: { password },
      })
    ).status(),
  ).toBe(403);
  expect((await request.get("/api/cron/usage-retention")).status()).toBe(401);
  const data = {
    version: 2,
    eventId: randomUUID(),
    page: "/alphadoku/classic",
    views: 1,
    plays: 1,
    completions: 0,
    seconds: 15,
    playSeconds: 10,
    pulse: true,
  };
  const headers = {
    origin: baseURL!,
    "user-agent": "Mozilla/5.0",
    "x-test-ip": "203.0.113.22",
  };
  expect(
    (
      await request.post("/api/usage", {
        headers,
        data: { ...data, ip: "203.0.113.22" },
      })
    ).status(),
  ).toBe(400);
  expect(
    (
      await request.post("/api/usage", {
        headers,
        data: { ...data, page: "/private-person-name" },
      })
    ).status(),
  ).toBe(400);
  expect((await request.post("/api/usage", { headers, data })).status()).toBe(
    204,
  );
  expect((await request.post("/api/usage", { headers, data })).status()).toBe(
    204,
  );
  await page.goto("/admin");
  await page.getByLabel("Admin password").fill("wrong-password");
  await page.getByRole("button", { name: "Sign in securely" }).click();
  await expect(page.locator(".admin-error")).toContainText(
    "Incorrect password",
  );
  await page.getByLabel("Admin password").fill(password);
  await page.getByRole("button", { name: "Sign in securely" }).click();
  await expect(
    page.getByRole("heading", { name: "Daily usage" }),
  ).toBeVisible();
  const response = await page.request.get("/api/admin/usage");
  expect(response.headers()["cache-control"]).toContain("no-store");
  const report = await response.json();
  expect(
    report.pages.find((p: { page: string }) => p.page === "/alphadoku/classic"),
  ).toMatchObject({ views: 1, plays: 1, activeSeconds: 15, playSeconds: 10 });
  expect(report).not.toHaveProperty("visits");
  expect(JSON.stringify(report)).not.toContain(data.eventId);
  expect(JSON.stringify(report)).not.toContain("203.0.113.22");
  await page.screenshot({
    path: "test-results/admin-anonymous-dashboard.png",
    fullPage: true,
  });
  await page.getByLabel("Game").selectOption("alphadoku-mega");
  await expect(
    page.getByRole("heading", { name: "Game engagement" }),
  ).toBeVisible();
  await expect(
    page.getByRole("row").filter({ hasText: "Classic Alphadoku" }),
  ).toHaveCount(0);
  await page.getByRole("button", { name: "Sign out" }).click();
  expect((await page.request.get("/api/admin/usage")).status()).toBe(401);
  await page.context().addCookies([
    {
      name: "puzzlecub_admin",
      value: "9999999999999." + "a".repeat(48) + ".forged",
      url: baseURL!,
    },
  ]);
  expect((await page.request.get("/api/admin/usage")).status()).toBe(401);
});

test("automatic counting distinguishes page views from play, uses no visitor storage, and supports opt-out", async ({
  page,
}) => {
  const payloads: Record<string, unknown>[] = [];
  page.on("request", (r) => {
    if (r.url().endsWith("/api/usage")) payloads.push(r.postDataJSON());
  });
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.goto("/alphadoku/mega?private=query-value");
  await expect(page.getByRole("grid")).toBeVisible();
  await expect.poll(() => payloads.some((p) => p.views === 1)).toBe(true);
  expect(payloads.filter((p) => p.views === 1)).toHaveLength(1);
  expect(payloads.some((p) => p.plays === 1)).toBe(false);
  await expect(
    page.getByRole("button", { name: "Allow analytics", exact: true }),
  ).toHaveCount(0);
  await page.getByRole("gridcell", { name: /empty/ }).first().click();
  await page.keyboard.press("a");
  await expect.poll(() => payloads.some((p) => p.plays === 1)).toBe(true);
  expect(payloads.every((p) => p.page === "/alphadoku/mega")).toBe(true);
  expect(
    payloads.every(
      (p) =>
        Object.keys(p).sort().join(",") ===
        "completions,eventId,page,playSeconds,plays,pulse,seconds,version,views",
    ),
  ).toBe(true);
  expect(new Set(payloads.map((p) => p.eventId)).size).toBe(payloads.length);
  expect(
    await page.evaluate(() => sessionStorage.getItem("puzzlecub-usage-visit")),
  ).toBeNull();
  expect(
    await page.evaluate(() =>
      localStorage.getItem("puzzlecub-analytics-choice"),
    ),
  ).toBeNull();
  await page.goto("/privacy");
  await page.getByRole("button", { name: "Stop anonymous analytics" }).click();
  const count = payloads.length;
  await page.goto("/alphadoku/mega");
  await expect(page.getByRole("grid")).toBeVisible();
  await page.getByRole("gridcell", { name: /empty/ }).first().click();
  await page.keyboard.press("b");
  expect(payloads).toHaveLength(count);
});

test("previous declines and browser privacy signals remain respected", async ({
  page,
  context,
}) => {
  await context.addInitScript(() => {
    localStorage.setItem("puzzlecub-analytics-choice", "deny");
    sessionStorage.setItem("puzzlecub-usage-visit", "legacy-id");
  });
  const calls: string[] = [];
  page.on("request", (r) => {
    if (r.url().endsWith("/api/usage")) calls.push(r.url());
  });
  await page.goto("/privacy");
  await expect(
    page.getByRole("button", { name: "Enable anonymous analytics" }),
  ).toBeVisible();
  expect(calls).toHaveLength(0);
  expect(
    await page.evaluate(() => sessionStorage.getItem("puzzlecub-usage-visit")),
  ).toBeNull();
  await context.addInitScript(() => {
    localStorage.removeItem("puzzlecub-analytics-choice");
    Object.defineProperty(navigator, "globalPrivacyControl", { value: true });
  });
  await page.reload();
  await expect(
    page.getByText("Your browser’s privacy signal is respected."),
  ).toBeVisible();
  expect(calls).toHaveLength(0);
});
test("Classic reports actual play automatically without an analytics prompt", async ({
  browser,
  baseURL,
}) => {
  const context = await browser.newContext({
    baseURL,
    viewport: { width: 393, height: 851 },
    isMobile: true,
    hasTouch: true,
    userAgent:
      "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 Chrome/125.0.0.0 Mobile Safari/537.36",
  });
  const page = await context.newPage();
  const plays: number[] = [];
  page.on("request", (request) => {
    if (request.url().endsWith("/api/usage"))
      plays.push(request.postDataJSON().plays);
  });
  await page.goto("/alphadoku/classic");
  const frame = page.frameLocator("iframe.classic-frame");
  const play = frame.getByRole("button", { name: "Play Medium", exact: true });
  await expect(play).toBeVisible({ timeout: 45000 });
  await play.press("Enter");
  const empty = frame
    .getByRole("button", { name: /Row \d+, column \d+, empty/ })
    .first();
  await expect(empty).toBeVisible({ timeout: 45000 });
  expect(plays.filter(Boolean)).toHaveLength(0);
  const coordinates = (await empty.textContent())!.match(
    /Row (\d+), column (\d+), empty/,
  )!;
  await frame
    .getByRole("button", { name: /Choose a cell.*Tap to choose/ })
    .tap();
  await frame
    .getByRole("group", { name: `Row ${coordinates[1]}`, exact: true })
    .getByRole("button")
    .tap();
  await frame
    .getByRole("group", { name: `Column ${coordinates[2]}`, exact: true })
    .getByRole("button")
    .tap();
  await frame.getByRole("button", { name: "Done", exact: true }).tap();
  await frame
    .getByRole("button", { name: /^[A-Z] \d+ left$/ })
    .first()
    .press("Enter");
  await expect.poll(() => plays.includes(1)).toBe(true);
  await context.close();
});
