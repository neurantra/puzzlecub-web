import { test, expect, type Page } from "@playwright/test";
import { readFileSync } from "node:fs";

async function preferences(page: Page) {
  await page.addInitScript(() => {
    localStorage.setItem(
      "flutter.puzzlecub.mazewords.maze_words.player.v1",
      JSON.stringify(JSON.stringify({ onboarded: true, birthYear: 1990 })),
    );
    localStorage.setItem(
      "flutter.puzzlecub.slide-and-sort.ageProfile",
      JSON.stringify(JSON.stringify({ declared: true, year: 1990 })),
    );
    localStorage.setItem(
      "flutter.puzzlecub.fillthejar.jar.audience.birthYear.v1",
      "1990",
    );
  });
}
for (const slug of ["mazewords", "slide-and-sort", "mapopia", "fillthejar"]) {
  test(`${slug} loads on mobile and records real gameplay`, async ({
    page,
  }) => {
    await preferences(page);
    await page.setViewportSize({ width: 393, height: 851 });
    const errors: string[] = [],
      plays: string[] = [],
      external: string[] = [];
    page.on("pageerror", (error) => errors.push(error.message));
    page.on("request", (request) => {
      if (
        request.url().endsWith("/api/usage") &&
        request.postDataJSON()?.plays === 1
      )
        plays.push(request.postDataJSON().page);
      if (/firebase|revenuecat|purchases-js/.test(request.url()))
        external.push(request.url());
    });
    await page.goto(`/${slug}`);
    const frame = page.frameLocator("iframe.collection-frame");
    await expect(frame.locator("flt-semantics-host")).toBeAttached({
      timeout: 45000,
    });
    expect(plays).toEqual([]);
    if (slug === "mazewords") {
      await frame.getByRole("button", { name: "Let’s wander" }).press("Enter");
      await expect(
        frame.getByRole("button", { name: "Pause", exact: true }),
      ).toBeVisible();
      await page.waitForTimeout(500); // Flutter's route transition moves the board into place.
      const board = frame.getByText(
        "Trace through open corridors and lift your finger to submit.",
        { exact: true },
      );
      await expect(board).toBeVisible();
      const bounds = (await board.boundingBox())!;
      await page.mouse.click(
        bounds.x + bounds.width / 2,
        bounds.y + bounds.height / 2,
      );
      await expect(
        frame.getByRole("button", { name: "Pause", exact: true }),
      ).toBeVisible();
    } else if (slug === "slide-and-sort") {
      await frame.getByRole("button", { name: "Let's play" }).press("Enter");
      await expect(frame.getByText("0", { exact: true })).toBeVisible();
      const tiles = frame
        .getByRole("button")
        .filter({ hasText: /^[A-X](, in place)?\s+[A-X]$/ });
      // A legal adjacent tile advances the counter; non-adjacent tiles do nothing.
      for (let index = 0; index < (await tiles.count()); index++) {
        await tiles.nth(index).click({ force: true });
        await page.waitForTimeout(60);
        if (await frame.getByText("1", { exact: true }).count()) break;
      }
      await expect(frame.getByText("1", { exact: true })).toBeVisible();
    } else if (slug === "mapopia") {
      await frame
        .getByRole("button", { name: "Let’s explore Europe" })
        .press("Enter");
      await frame
        .getByRole("button", { name: "Begin expedition" })
        .press("Enter");
      await page.waitForTimeout(1500);
      const pack = JSON.parse(
        readFileSync("mapopia-game/assets/geo/europe.json", "utf8"),
      );
      // A real board attempt must reach the engine, whether the shuffled
      // selected piece belongs here or produces the game's wrong-place feedback.
      const index = pack.pieces.findIndex(
        (piece: { name: string }) => piece.name === "France",
      );
      await frame
        .getByRole("button", { name: `Map position ${index + 1}`, exact: true })
        .click({ force: true });
      await expect(
        frame.getByText(/^(1 of 38 placed|1 invalid attempt)$/),
      ).toBeVisible();
    } else {
      await frame
        .getByRole("button", { name: "Skip", exact: true })
        .press("Enter");
      await frame
        .getByRole("button", { name: /Rectangle pile/ })
        .press("Enter");
      await frame
        .getByRole("button", { name: /Drop at column/ })
        .first()
        .click({ force: true });
      await expect(frame.getByText("1/3 · 50%", { exact: true })).toBeVisible();
    }
    if (process.env.PUZZLECUB_TEST_DATABASE === "1")
      await expect.poll(() => plays.includes(`/${slug}`)).toBe(true);
    await expect(page.locator("body")).toHaveJSProperty("scrollWidth", 393);
    await page.screenshot({
      path: `test-results/${slug}-mobile.png`,
      fullPage: true,
    });
    expect(errors).toEqual([]);
    expect(external).toEqual([]);
  });
}

test("protected game onboarding does not load advertising providers", async ({
  page,
}) => {
  const adRequests: string[] = [];
  await page.route("**/api/ads/config", (route) =>
    route.fulfill({
      json: {
        enabled: true,
        h5: true,
        client: "ca-pub-5992130091579926",
        slots: { gameplay: "1234567890", content: "1234567890" },
      },
    }),
  );
  await page.route("**/*googlesyndication*", (route) => {
    adRequests.push(route.request().url());
    return route.abort();
  });
  for (const slug of ["mazewords", "slide-and-sort", "fillthejar"]) {
    await page.goto(`/${slug}`);
    await expect(
      page
        .frameLocator("iframe")
        .getByText(/year.*birth|year were you born/)
        .first(),
    ).toBeVisible({ timeout: 45000 });
    await expect(page.locator(".gameplay-ad")).toHaveCount(0);
  }
  expect(adRequests).toEqual([]);
});
