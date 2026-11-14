import { expect, test } from '@playwright/test';

const base = process.env.COMMUNE_REAL_BACKEND_URL || 'http://127.0.0.1:4175';
const password = process.env.COMMUNE_REAL_ADMIN_PASSWORD || '';

test('reads P4 pages against the current Lemmy backend', async ({ page }) => {
  test.skip(!process.env.COMMUNE_REAL_BACKEND || !password, 'Configure the real backend and administrator password.');
  if (process.env.COMMUNE_TEST_ELM_JS) await page.route('**/elm.js', route => route.fulfill({ path: process.env.COMMUNE_TEST_ELM_JS, contentType: 'text/javascript' }));
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  await page.goto(`${base}/instances`);
  await expect(page.getByRole('heading', { name: 'Federated instances' })).toBeVisible();
  await expect(page.getByText('No content', { exact: true })).toBeVisible();
  await page.goto(`${base}/legal`);
  await expect(page.getByRole('heading', { name: 'Legal information' })).toBeVisible();

  await page.goto(`${base}/login`);
  await page.getByLabel('Username or email').fill(process.env.COMMUNE_REAL_ADMIN_USER || 'admin');
  await page.getByLabel('Password', { exact: true }).fill(password);
  await page.getByRole('button', { name: 'Log in', exact: true }).click();
  await expect(page.locator('#navigation-drawer')).toContainText('@admin');

  for (const [path, title] of [
    ['/admin/settings', 'Vote settings'],
    ['/admin/configuration', 'Site configuration'],
    ['/admin/users', 'Site users'],
    ['/admin/media', 'Site media'],
    ['/admin/federation', 'Federation policy'],
    ['/admin/oauth', 'OAuth providers'],
    ['/admin/taglines', 'Taglines'],
    ['/admin/emoji', 'Custom emoji'],
    ['/registration_applications', 'Registration applications'],
    ['/pending_follows', 'Pending follow requests']
  ]) {
    await page.goto(base + path);
    await expect(page.getByRole('heading', { level: 1, name: title })).toBeVisible();
    await expect(page.locator('main [role="status"]')).toHaveCount(0);
    await expect(page.locator('main [role="alert"]')).toHaveCount(0);
    if (path === '/admin/configuration') await expect(page.getByLabel('Site name')).not.toHaveValue('');
  }
});
