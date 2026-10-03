import { test, expect } from "@playwright/test";
import { randomUUID } from "node:crypto";

// Run against the isolated server described in README; never a production database.
test.skip(
  process.env.PUZZLECUB_TEST_DATABASE !== "1",
  "Requires isolated analytics test server",
);
const password = "local-analytics-test-password";
test.use({ userAgent: "Mozilla/5.0 PuzzleCubIntegrationTest" });

test("admin authentication, usage ingestion, filters, logout and forgery protection", async ({
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
  await page.goto("/admin");
  await page.getByLabel("Admin password").fill("wrong-password");
  await page.getByRole("button", { name: "Sign in securely" }).click();
  await expect(page.locator(".admin-error")).toContainText(
    "Incorrect password",
  );
  const id = randomUUID();
  const payload = {
    id,
    seconds: 0,
    sequence: 1,
    path: "/alphadoku/classic",
    referrer: "google.com",
    games: ["alphadoku-classic"],
    completed: [],
    visible: true,
    consent: true,
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
        data: { ...payload, consent: false },
      })
    ).status(),
  ).toBe(400);
  expect(
    (
      await request.post("/api/usage", {
        headers,
        data: { ...payload, games: ["made-up"] },
      })
    ).status(),
  ).toBe(400);
  expect(
    (await request.post("/api/usage", { headers, data: payload })).status(),
  ).toBe(204);
  await page.getByLabel("Admin password").fill(password);
  await page.getByRole("button", { name: "Sign in securely" }).click();
  await expect(
    page.getByRole("heading", { name: "How are people playing?" }),
  ).toBeVisible();
  await expect(page.getByText(id.slice(0, 8), { exact: true })).toBeVisible();
  await expect(
    page
      .getByRole("row")
      .filter({ hasText: id.slice(0, 8) })
      .getByText("203.0.113.22", { exact: true }),
  ).toBeVisible();
  const response = await page.request.get("/api/admin/usage");
  expect(response.headers()["cache-control"]).toContain("no-store");
  expect(
    (await response.json()).visits.find((v: { id: string }) => v.id === id),
  ).toMatchObject({ games: ["alphadoku-classic"], online: true });
  await page.screenshot({
    path: "test-results/admin-dashboard.png",
    fullPage: true,
  });
  await page.getByLabel("Played game").selectOption("alphadoku-mega");
  await expect(page.getByText(id.slice(0, 8), { exact: true })).toHaveCount(0);
  await page.getByRole("button", { name: "Sign out" }).click();
  await expect(page.getByLabel("Admin password")).toBeVisible();
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

test("analytics is opt-in; game loading is not play; real moves are reported; withdrawal stops requests", async ({
  page,
}) => {
  const payloads: { games: string[]; path: string }[] = [];
  page.on("request", (request) => {
    if (request.url().endsWith("/api/usage"))
      payloads.push(request.postDataJSON());
  });
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.goto("/alphadoku/mega");
  await expect(page.getByRole("grid")).toBeVisible();
  expect(payloads).toHaveLength(0);
  await page
    .getByRole("button", { name: "Allow analytics", exact: true })
    .click();
  await expect.poll(() => payloads.length).toBeGreaterThan(0);
  expect(payloads.at(-1)?.games).toEqual([]);
  await page.getByRole("gridcell", { name: /empty/ }).first().click();
  await page.keyboard.press("a");
  await expect
    .poll(() => payloads.some((p) => p.games.includes("alphadoku-mega")))
    .toBe(true);
  await page.goto("/privacy");
  await page.getByRole("button", { name: "Stop analytics" }).click();
  const count = payloads.length;
  await page.goto("/alphadoku/mega");
  await expect(page.getByRole("grid")).toBeVisible();
  await page.getByRole("gridcell", { name: /empty/ }).first().click();
  await page.keyboard.press("b");
  expect(payloads.length).toBe(count);
});

test("Classic iframe reports a real letter entry after consent", async ({
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
  const games: string[] = [];
  page.on("request", (request) => {
    if (request.url().endsWith("/api/usage"))
      games.push(...request.postDataJSON().games);
  });
  await page.goto("/alphadoku/classic");
  await page
    .getByRole("button", { name: "Allow analytics", exact: true })
    .click();
  const frame = page.frameLocator("iframe.classic-frame");
  const play = frame.getByRole("button", { name: "Play Medium", exact: true });
  await expect(play).toBeVisible({ timeout: 45000 });
  await play.press("Enter");
  const empty = frame
    .getByRole("button", { name: /Row \d+, column \d+, empty/ })
    .first();
  await expect(empty).toBeVisible({ timeout: 45000 });
  expect(games).not.toContain("alphadoku-classic");
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
  await expect.poll(() => games.includes("alphadoku-classic")).toBe(true);
  await context.close();
});
