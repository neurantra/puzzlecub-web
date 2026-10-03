import { test, expect } from "@playwright/test";

test("Chaturang keeps the mobile flow, plays against the worker, offers hints and restarts freely", async ({
  page,
}) => {
  const payloads: { page: string; plays: number; completions: number }[] = [];
  page.on("request", (r) => {
    if (r.url().endsWith("/api/usage")) payloads.push(r.postDataJSON());
  });
  await page.goto("/chaturang");
  const frame = page.frameLocator("iframe.chaturang-frame");
  await expect(
    frame.getByRole("button", { name: "Play against AI", exact: true }),
  ).toBeVisible({ timeout: 45000 });
  await expect(
    frame.getByText("FREE TO PLAY · AGAINST AI", { exact: true }),
  ).toBeVisible();
  await expect(
    frame.getByRole("button", { name: "Full game", exact: true }),
  ).toHaveCount(0);
  await expect(
    frame.getByRole("button", { name: "Play with a friend", exact: false }),
  ).toHaveCount(0);
  const inner = page
    .frames()
    .find((f) => f.url().includes("/chaturang-game/"))!;
  // Exercise the compiled searcher, including its lossless opening-book hashes.
  const opening = await inner.evaluate(async () => {
    const w = window as unknown as {
      puzzlecubSearch: (s: string) => Promise<string>;
      puzzlecubStopSearch: (s: string) => void;
    };
    const result = JSON.parse(
      await w.puzzlecubSearch(
        JSON.stringify({ id: "test-engine", depth: 3, budget: 500, moves: [] }),
      ),
    );
    w.puzzlecubStopSearch("test-engine");
    return result;
  });
  expect(opening.move).toEqual([4, 6, 4, 5, null]);
  expect(opening.nodes).toBe(0); // A real opening-book hit, not a random recovery.
  await frame
    .getByRole("button", { name: "Play against AI", exact: true })
    .press("Enter");
  await expect(
    frame.getByRole("heading", { name: "Choose your side" }),
  ).toBeVisible();
  await page.waitForTimeout(1600); // The app's card entry and shuffle ceremony.
  await frame
    .getByRole("button", { name: /Choose royal card/ })
    .first()
    .press("Enter");
  const turn = frame.getByText(/^(White|Black) to move$/);
  await expect(turn).toBeVisible({ timeout: 30000 });
  expect(payloads.some((p) => p.page === "/chaturang" && p.plays === 1)).toBe(
    false,
  );
  const human = (await turn.textContent())!.startsWith("White")
    ? "white"
    : "black";
  const pawn = frame
    .getByRole("button", { name: new RegExp(", " + human + " Soldier$") })
    .first();
  const square = (await pawn.textContent())!.split(",")[0];
  await pawn.press("Enter");
  await frame
    .getByRole("button", { name: /legal destination/ })
    .first()
    .press("Enter");
  await expect(frame.getByText("Move 2", { exact: true })).toBeVisible({
    timeout: 30000,
  });
  await expect(turn).toBeVisible();
  await expect(
    frame.getByRole("button", { name: square + ", empty", exact: true }),
  ).toBeVisible();
  if (process.env.PUZZLECUB_TEST_DATABASE === "1")
    await expect
      .poll(() =>
        payloads.some((p) => p.page === "/chaturang" && p.plays === 1),
      )
      .toBe(true);
  await frame.getByRole("button", { name: "Hint", exact: true }).press("Enter");
  await expect(
    frame.getByRole("button", { name: /legal destination/ }).first(),
  ).toBeVisible({ timeout: 20000 });
  await frame
    .getByRole("button", { name: "Game options", exact: true })
    .press("Enter");
  await frame
    .getByRole("menuitem", { name: "Restart", exact: true })
    .press("Enter");
  await expect(
    frame.getByText("Restart the game?", { exact: true }),
  ).toBeVisible();
  await frame
    .getByRole("button", { name: "Restart", exact: true })
    .press("Enter");
  await expect(frame.getByText("Move 1", { exact: true })).toBeVisible({
    timeout: 30000,
  });
  await expect(turn).toBeVisible();
  if (process.env.PUZZLECUB_TEST_DATABASE === "1")
    await expect
      .poll(() =>
        payloads.some((p) => p.page === "/chaturang" && p.completions === 1),
      )
      .toBe(true);
  await page.screenshot({
    path: "test-results/chaturang-desktop.png",
    fullPage: true,
  });
  await page.setViewportSize({ width: 393, height: 851 });
  await expect(page.locator("body")).toHaveJSProperty("scrollWidth", 393);
  const box = await page.locator("iframe.chaturang-frame").boundingBox();
  expect(box!.y).toBeLessThanOrEqual(51);
  expect(box!.height).toBeLessThanOrEqual(801);
  await page.screenshot({
    path: "test-results/chaturang-mobile.png",
    fullPage: true,
  });
});
