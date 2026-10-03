import { test, expect } from "@playwright/test";
const config = {
  enabled: true,
  h5: true,
  test: true,
  client: "ca-pub-1234567890123456",
  slots: { content: "1234567890", gameplay: "0987654321" },
};
const sdk = `window.mockAdCalls=0; window.mockAdMode='empty';
window.adsbygoogle.push=o=>{
 if(o.onReady){window.mockAdsReady=true;o.onReady();}
 if(o.type){window.mockAdCalls++;if(window.mockAdMode==='shown')o.beforeAd();setTimeout(()=>{if(window.mockAdMode==='shown')o.afterAd();o.adBreakDone({breakStatus:window.mockAdMode==='shown'?'viewed':'noAdPreloaded'});},30);}
};`;
test("ads stay off without publisher activation", async ({ page }) => {
  let requests = 0;
  page.on("request", (r) => {
    if (r.url().includes("googlesyndication")) requests++;
  });
  await page.goto("/chaturang");
  await expect(page.locator("iframe")).toBeVisible();
  await expect(page.locator(".ad-placement")).toHaveCount(0);
  const c = await (await page.request.get("/api/ads/config")).json();
  expect(c.enabled).toBe(false);
  expect(requests).toBe(0);
});
test("H5 skips first game, resumes on no-fill, caps frequency, and resumes after an ad", async ({
  page,
}) => {
  await page.clock.install();
  await page.route("**/api/ads/config", (r) => r.fulfill({ json: config }));
  await page.route("**/pagead/js/adsbygoogle.js?*", (r) =>
    r.fulfill({ contentType: "application/javascript", body: sdk }),
  );
  await page.goto("/");
  await page.waitForFunction(
    () => (window as unknown as { mockAdsReady: boolean }).mockAdsReady,
  );
  await page.evaluate(() => window.puzzlecubAds!.between());
  expect(
    await page.evaluate(
      () => (window as unknown as { mockAdCalls: number }).mockAdCalls,
    ),
  ).toBe(0);
  await page.clock.fastForward(61000);
  await page.evaluate(() => {
    window.puzzlecubAds!.markPlayed();
  });
  const result = page.evaluate(() =>
    window.puzzlecubAds!.between().then(() => true),
  );
  await page.clock.runFor(100);
  expect(await result).toBe(true);
  expect(
    await page.evaluate(
      () => (window as unknown as { mockAdCalls: number }).mockAdCalls,
    ),
  ).toBe(1);
  await page.evaluate(() => {
    window.puzzlecubAds!.markPlayed();
    return window.puzzlecubAds!.between();
  });
  expect(
    await page.evaluate(
      () => (window as unknown as { mockAdCalls: number }).mockAdCalls,
    ),
  ).toBe(1);
  await page.clock.fastForward(180000);
  await page.evaluate(() => {
    (window as unknown as { mockAdMode: string }).mockAdMode = "shown";
    window.puzzlecubAds!.markPlayed();
  });
  const shown = page.evaluate(() =>
    window.puzzlecubAds!.between().then(() => true),
  );
  await expect(page.locator("html")).toHaveClass(/ad-break-active/);
  await page.clock.runFor(100);
  expect(await shown).toBe(true);
  await expect(page.locator("html")).not.toHaveClass(/ad-break-active/);
});
test("ad blocking never holds the next game; gameplay display unit stays away from the board", async ({
  page,
}) => {
  await page.route("**/api/ads/config", (r) => r.fulfill({ json: config }));
  await page.route("**/pagead/js/adsbygoogle.js?*", (r) => r.abort());
  await page.setViewportSize({ width: 850, height: 1100 });
  await page.goto("/alphadoku/classic");
  await expect(page.locator(".gameplay-ad")).toBeVisible();
  const board = await page.locator("iframe").boundingBox();
  const ad = await page.locator(".gameplay-ad").boundingBox();
  expect(ad!.y - (board!.y + board!.height)).toBeGreaterThanOrEqual(150);
  expect(
    await page.evaluate(async () => {
      window.puzzlecubAds!.markPlayed();
      await window.puzzlecubAds!.between();
      return true;
    }),
  ).toBe(true);
});
