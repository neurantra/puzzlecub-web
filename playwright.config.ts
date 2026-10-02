import { defineConfig } from "@playwright/test";
export default defineConfig({
  testDir: "./tests/browser",
  use: { baseURL: "http://127.0.0.1:3127", headless: true, channel: "chrome" },
  timeout: 60000,
  workers: 1,
  reporter: "list",
});
