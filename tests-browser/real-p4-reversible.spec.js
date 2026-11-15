import { expect, test } from '@playwright/test';

const base = process.env.COMMUNE_REAL_BACKEND_URL || 'http://127.0.0.1:4175';
const password = process.env.COMMUNE_REAL_ADMIN_PASSWORD || '';

test('saves and restores a current-site setting against the real backend', async ({ page }) => {
  test.skip(process.env.COMMUNE_REAL_REVERSIBLE !== '1' || !password, 'Explicitly enable the reversible backend acceptance test.');
  if (process.env.COMMUNE_TEST_ELM_JS) await page.route('**/elm.js', route => route.fulfill({ path: process.env.COMMUNE_TEST_ELM_JS, contentType: 'text/javascript' }));
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  await page.goto(`${base}/login`);
  await page.getByLabel('Username or email').fill(process.env.COMMUNE_REAL_ADMIN_USER || 'admin');
  await page.getByLabel('Password', { exact: true }).fill(password);
  await page.getByRole('button', { name: 'Log in', exact: true }).click();
  await expect(page.locator('#navigation-drawer')).toContainText('@admin');

  await page.goto(`${base}/admin/configuration`);
  await expect(page.getByRole('heading', { level: 1, name: 'Site configuration' })).toBeVisible();
  const originalName = await page.evaluate(async () => {
    const response = await fetch('/api/v4/site');
    if (!response.ok) throw new Error(`Could not read current site: ${response.status}`);
    return (await response.json()).site_view.site.name;
  });
  const temporaryName = `T-${Date.now()}`;

  try {
    await page.getByLabel('Site name').fill(temporaryName);
    const saveResponsePromise = page.waitForResponse(response => response.url().endsWith('/api/v4/site') && response.request().method() === 'PUT');
    await page.getByRole('button', { name: 'Save changes' }).click();
    const saveResponse = await saveResponsePromise;
    expect(saveResponse.status(), await saveResponse.text()).toBe(200);
    await expect.poll(() => page.evaluate(async () => (await (await fetch('/api/v4/site')).json()).site_view.site.name)).toBe(temporaryName);
    await expect(page.getByLabel('Site name')).toHaveValue(temporaryName);
  } finally {
    const restoreStatus = await page.evaluate(async name => {
      const response = await fetch('/api/v4/site', {
        method: 'PUT',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ name })
      });
      return response.status;
    }, originalName);
    if (restoreStatus !== 200) throw new Error(`Could not restore the original site name: HTTP ${restoreStatus}`);
  }

  await expect.poll(() => page.evaluate(async () => (await (await fetch('/api/v4/site')).json()).site_view.site.name)).toBe(originalName);
});
