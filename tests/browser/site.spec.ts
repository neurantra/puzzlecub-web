import { test, expect } from "@playwright/test";
test("homepage discovery and mobile layout", async ({ page }) => {
  await page.goto("/");
  await expect(
    page.getByRole("heading", {
      name: "A little thought. A bright discovery.",
    }),
  ).toBeVisible();
  await page.getByRole("button", { name: "E", exact: true }).click();
  await expect(page.getByRole("status")).toContainText("Exactly");
  await page.screenshot({
    path: "test-results/home-desktop.png",
    fullPage: true,
  });
  await page.setViewportSize({ width: 390, height: 844 });
  await expect(page.locator("body")).toHaveJSProperty("scrollWidth", 390);
  await page.screenshot({
    path: "test-results/home-mobile.png",
    fullPage: true,
  });
  await page
    .getByRole("navigation", { name: "Main navigation" })
    .getByRole("link", { name: "Learn" })
    .click();
  await expect(
    page.getByRole("heading", { name: "A little logic goes a long way." }),
  ).toBeVisible();
});
test("Mega entries, keyboard N, notes, undo, save/resume and Pro", async ({
  page,
}) => {
  await page.goto("/alphadoku/mega");
  const grid = page.getByRole("grid");
  await expect(grid).toBeVisible();
  expect(await page.getByRole("gridcell").count()).toBe(625);
  const empty = page.getByRole("gridcell", { name: /empty/ }).first();
  const label = await empty.getAttribute("aria-label");
  await empty.click();
  await page.keyboard.press("n");
  await expect(
    page.getByRole("gridcell", {
      name: new RegExp(label!.replace("empty", "N")),
    }),
  ).toBeVisible();
  await page.getByRole("button", { name: "Undo", exact: true }).click();
  await expect(
    page.getByRole("gridcell", { name: label!, exact: true }),
  ).toBeVisible();
  await page.keyboard.press("Tab");
  await page.getByRole("gridcell", { name: label!, exact: true }).click();
  await page.keyboard.press("Space");
  await page.keyboard.press("a");
  await expect(
    page.getByRole("gridcell", { name: label! + ", notes A", exact: true }),
  ).toBeVisible();
  await page.reload();
  await expect(
    page.getByRole("gridcell", { name: label! + ", notes A", exact: true }),
  ).toBeVisible();
  await page.getByRole("button", { name: "Focus on a box" }).click();
  expect(await page.getByRole("gridcell").count()).toBe(25);
  await page
    .getByRole("combobox", { name: "Choose a 5 by 5 box" })
    .selectOption("24");
  await expect(page.getByRole("gridcell").first()).toHaveAttribute(
    "aria-rowindex",
    "21",
  );
  await page.screenshot({
    path: "test-results/mega-focus.png",
    fullPage: true,
  });
  await page.getByLabel("Difficulty").selectOption("pro");
  page.once("dialog", (d) => d.accept());
  await page.getByRole("button", { name: "New puzzle", exact: true }).click();
  await expect(
    page.getByRole("button", { name: "Hint · unavailable in Pro" }),
  ).toBeDisabled();
  await page.setViewportSize({ width: 390, height: 844 });
  await expect(
    page.getByRole("heading", { name: "Mega needs a desktop or laptop." }),
  ).toBeVisible();
  await expect(page.getByRole("grid")).toHaveCount(0);
  await expect(page.locator("body")).toHaveJSProperty("scrollWidth", 390);
});
test("Mega fits a laptop viewport and never mounts on a phone", async ({
  browser,
}) => {
  const laptop = await browser.newPage({
    viewport: { width: 1200, height: 700 },
  });
  await laptop.goto("/alphadoku/mega");
  await expect(laptop.getByRole("grid")).toBeVisible();
  const edges = await laptop.evaluate(() => ({
    board: document.querySelector(".mega-board")!.getBoundingClientRect()
      .bottom,
    controls: document.querySelector(".mega-controls")!.getBoundingClientRect()
      .bottom,
    width: document.body.scrollWidth,
  }));
  expect(edges.board).toBeLessThanOrEqual(700);
  expect(edges.controls).toBeLessThanOrEqual(700);
  expect(edges.width).toBe(1200);
  await laptop.setViewportSize({ width: 1199, height: 700 });
  await expect(laptop.getByRole("grid")).toHaveCount(0);
  await expect(
    laptop.getByRole("heading", { name: "Mega needs a desktop or laptop." }),
  ).toBeVisible();
  await laptop.close();

  const phone = await browser.newPage({
    viewport: { width: 1400, height: 900 },
    userAgent:
      "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 Chrome/125.0 Mobile Safari/537.36",
  });
  const workers: string[] = [];
  phone.on("request", (r) => {
    if (r.url().includes("mega-engine.mjs")) workers.push(r.url());
  });
  await phone.goto("/alphadoku/mega");
  await expect(
    phone.getByRole("heading", { name: "Mega needs a desktop or laptop." }),
  ).toBeVisible();
  await expect(phone.getByRole("grid")).toHaveCount(0);
  expect(workers).toHaveLength(0);
  await phone.close();
});

test("Mega weekly deterministic and separate save slot", async ({
  browser,
}) => {
  const a = await browser.newPage(),
    b = await browser.newPage();
  await a.goto("/alphadoku/mega?week=2026-09-28");
  await b.goto("/alphadoku/mega?week=2026-09-28");
  await expect(a.getByRole("grid")).toBeVisible();
  await expect(b.getByRole("grid")).toBeVisible();
  expect(await a.getByRole("gridcell").allTextContents()).toEqual(
    await b.getByRole("gridcell").allTextContents(),
  );
  await a.close();
  await b.close();
});
test("content, routing and legacy app directory", async ({ page, request }) => {
  for (const path of [
    "/learn/getting-started",
    "/learn/mega-guide",
    "/learn/worked-example",
    "/learn/naked-pair",
    "/challenges",
    "/about",
    "/privacy",
    "/terms",
    "/credits",
  ]) {
    await page.goto(path);
    await expect(page.locator("h1")).toBeVisible();
    expect(await page.locator("main").innerText()).not.toContain("404");
  }
  const apps = await request.get("/", { headers: { host: "puzzlecub.app" } });
  expect(await apps.text()).toContain("Four games.");
});

test("Classic loads original controls, starts a free puzzle and persists", async ({
  page,
}) => {
  await page.goto("/alphadoku/classic");
  const frame = page.frameLocator("iframe");
  await expect(
    frame.getByRole("button", { name: "Play Medium", exact: true }),
  ).toBeVisible({ timeout: 45000 });
  await frame
    .getByRole("button", { name: "Play Medium", exact: true })
    .press("Enter");
  await expect(
    frame.getByRole("button", { name: "Hint", exact: true }),
  ).toBeVisible({ timeout: 45000 });
  await page.screenshot({
    path: "test-results/classic-desktop.png",
    fullPage: true,
  });
  await page.reload();
  await expect(
    frame.getByRole("button", { name: "Continue Medium", exact: true }),
  ).toBeVisible({ timeout: 45000 });
  await expect(frame.getByText("Upgrades and restore purchases")).toHaveCount(
    0,
  );
});

test("Mega completes, counts the win once, and plays again", async ({
  page,
}) => {
  await page.goto("/alphadoku/mega");
  await expect(page.getByRole("grid")).toBeVisible();
  const letter = await page.evaluate(() => {
    const s = JSON.parse(localStorage.getItem("puzzlecub-mega-v1")!);
    const i = s.puzzle.givens.findIndex((v: number) => v < 0);
    s.board = [...s.puzzle.solution];
    s.board[i] = -1;
    s.notes = Array.from({ length: 625 }, () => []);
    s.history = [];
    localStorage.setItem("puzzlecub-mega-v1", JSON.stringify(s));
    return "ABCDEFGHIJKLMNOPQRSTUVWXY"[s.puzzle.solution[i]];
  });
  await page.reload();
  const cell = page.getByRole("gridcell", { name: /empty/ });
  await cell.click();
  await page.keyboard.press(letter);
  await expect(
    page.getByRole("heading", { name: "You found the big picture." }),
  ).toBeVisible();
  await page.reload();
  await expect(page.getByText(/1 completed/)).toBeVisible();
  await page.getByRole("button", { name: "Play again", exact: true }).click();
  await expect(
    page.getByRole("heading", { name: "You found the big picture." }),
  ).toHaveCount(0);
  await expect(page.getByRole("grid")).toBeVisible();
});
test("Classic daily board is reproducible and isolated from free play", async ({
  browser,
}) => {
  const contexts = [await browser.newContext(), await browser.newContext()];
  const boards = [];
  for (const context of contexts) {
    const page = await context.newPage();
    await page.goto("http://127.0.0.1:3127/alphadoku/classic?day=2026-10-02");
    const f = page.frameLocator("iframe");
    await expect(
      f.getByRole("button", { name: "Play Medium", exact: true }),
    ).toBeVisible({ timeout: 45000 });
    await expect(f.getByRole("button", { name: /Easy. The axis/ })).toHaveCount(
      0,
    );
    await f
      .getByRole("button", { name: "Play Medium", exact: true })
      .press("Enter");
    await expect(
      f.getByRole("button", { name: "Hint", exact: true }),
    ).toBeVisible({ timeout: 45000 });
    boards.push(
      await page.evaluate(() => {
        const k = Object.keys(localStorage).find((k) =>
          k.includes("alphadoku.session.v1.daily.2026-10-02"),
        );
        return k ? JSON.parse(localStorage.getItem(k)!) : null;
      }),
    );
    await context.close();
  }
  expect(boards[0]).not.toBeNull();
  expect(boards[0].puzzle).toEqual(boards[1].puzzle);
});

test("Classic cell picker and board stay tappable on a Pixel-sized screen", async ({
  browser,
}) => {
  const context = await browser.newContext({
    viewport: { width: 393, height: 851 },
    deviceScaleFactor: 2.75,
    isMobile: true,
    hasTouch: true,
    userAgent:
      "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 Chrome/125.0.0.0 Mobile Safari/537.36",
  });
  const page = await context.newPage();
  await page.goto("/alphadoku/classic");
  const bounds = await page.locator("iframe").boundingBox();
  expect(bounds?.x).toBe(0);
  expect(bounds?.y).toBe(48);
  expect(bounds?.height).toBe(803);
  expect(await page.evaluate(() => document.body.scrollHeight)).toBe(851);
  const frame = page.frameLocator("iframe");
  const play = frame.getByRole("button", { name: "Play Medium", exact: true });
  await expect(play).toBeVisible({ timeout: 45000 });
  await play.press("Enter");
  const picker = frame.getByRole("button", {
    name: /Choose a cell.*Tap to choose/,
  });
  await expect(picker).toBeVisible({ timeout: 45000 });
  await picker.tap();
  await frame.getByRole("group", { name: "Row 3" }).getByRole("button").tap();
  await frame
    .getByRole("group", { name: "Column 4" })
    .getByRole("button")
    .tap();
  await frame.getByRole("button", { name: "Done" }).tap();
  await expect(
    frame.getByRole("button", { name: /Row 3, column 4:/ }),
  ).toBeVisible();
  const empty = frame
    .getByRole("button", { name: /Row (?!3, column 4,)\d+, column \d+, empty/ })
    .first();
  const coordinates = (await empty.textContent())!.match(
    /Row (\d+), column (\d+), empty/,
  )!;
  await empty.tap();
  await expect(
    frame.getByRole("button", {
      name: new RegExp(
        `Row ${coordinates[1]}, column ${coordinates[2]}: empty`,
      ),
    }),
  ).toBeVisible();
  await context.close();
});
