import { test, expect } from '@playwright/test';

// Example Playwright e2e test. Replace with flows that exercise your
// deployed app (or a local dev server — see `webServer` in playwright.config.ts).

test('homepage has expected title', async ({ page }) => {
  // Replace with your real baseURL / path.
  // Skip if no server is running so the skeleton runs green on first install.
  test.skip(!process.env.E2E_BASE_URL, 'Set E2E_BASE_URL to run e2e example');

  await page.goto('/');
  await expect(page).toHaveTitle(/.+/);
});

test('api ping returns 200', async ({ request }) => {
  test.skip(!process.env.E2E_BASE_URL, 'Set E2E_BASE_URL to run e2e example');

  const res = await request.get('/ping');
  expect(res.status()).toBe(200);
});
