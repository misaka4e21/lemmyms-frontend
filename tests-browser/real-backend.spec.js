import AxeBuilder from '@axe-core/playwright';
import { expect, test } from '@playwright/test';

const enabled = Boolean(process.env.COMMUNE_REAL_BACKEND);
const base = process.env.COMMUNE_REAL_BACKEND_URL || 'http://127.0.0.1:4173';
const adminUser = process.env.COMMUNE_REAL_ADMIN_USER || 'admin';
const adminPassword = process.env.COMMUNE_REAL_ADMIN_PASSWORD || '';

test.describe('real Lemmy backend', () => {
  test.use({ extraHTTPHeaders: { 'X-Forwarded-For': '10.' + '0.0.' + String(1 + (Date.now() % 200)) } });

  test.skip(!enabled || !adminPassword, 'Configure COMMUNE_REAL_BACKEND and COMMUNE_REAL_ADMIN_PASSWORD.');

  test('exercises the migrated v4 workflows', async ({ page }) => {
    await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));

    const suffix = Date.now().toString(36);
    const communityName = 'e2e' + suffix;
    const communityTitle = 'E2E ' + suffix;
    const topicTitle = 'Real topic ' + suffix;
    const editedTitle = topicTitle + ' edited';
    const replyText = 'Real reply ' + suffix;
    const editedReply = 'Real reply edited ' + suffix;

    await page.goto(base + '/login');
    await page.getByLabel('Username or email').fill(adminUser);
    await page.getByLabel('Password').fill(adminPassword);
    await page.getByRole('button', { name: 'Log in', exact: true }).click();
    await expect(page.locator('#navigation-drawer')).toContainText('@' + adminUser);

    await page.goto(base + '/create_community');
    await page.getByLabel('Community name').fill(communityName);
    await page.getByLabel('Community title').fill(communityTitle);
    await page.getByLabel('Sidebar (Markdown)').fill('Sidebar ' + suffix);
    await page.getByLabel('Summary').fill('Summary ' + suffix);
    await page.getByLabel('Visibility').selectOption('public');
    await page.getByLabel('Post upvotes').selectOption('all');
    await page.getByLabel('Post downvotes').selectOption('all');
    await page.getByRole('button', { name: 'Create', exact: true }).click();
    await page.waitForURL(url => url.pathname === '/c/' + communityName);
    await expect(page.getByRole('heading', { level: 1, name: communityTitle })).toBeVisible();

    await page.goto(base + '/communities');
    await expect(page.getByRole('link', { name: communityTitle })).toBeVisible();
    await page.goto(base + '/c/' + communityName);

    await page.getByRole('link', { name: 'Publish topic' }).click();
    await page.getByLabel('Topic title').fill(topicTitle);
    await page.getByLabel('Message').fill('Real backend body');
    await page.getByRole('button', { name: 'Publish topic' }).click();
    await expect(page).toHaveURL(/\/post\/[^/]+$/);
    const postId = page.url().split('/').pop();
    await expect(page.getByRole('heading', { level: 1, name: topicTitle })).toBeVisible();

    const postArticle = page.getByRole('article').filter({ hasText: topicTitle }).first();
    const voteResponse = await page.request.post(base + '/api/v4/post/like', {
      data: { post_id: Number(postId), is_upvote: false }
    });
    expect(voteResponse.ok()).toBeTruthy();
    await page.reload();
    await expect(postArticle.getByRole('button', { name: /^Clear vote/ })).toBeVisible();

    await page.getByRole('link', { name: 'Edit post' }).click();
    await page.getByLabel('Topic title').fill(editedTitle);
    await page.getByRole('button', { name: 'Save changes' }).click();
    await expect(page.getByRole('heading', { level: 1, name: editedTitle })).toBeVisible();

    await page.getByRole('button', { name: 'Reply', exact: true }).click();
    await page.getByLabel('Message').fill(replyText);
    await page.getByRole('button', { name: 'Publish reply' }).click();
    const replyArticle = page.getByRole('article').filter({ hasText: replyText }).first();
    await expect(replyArticle).toBeVisible();

    await replyArticle.getByRole('link', { name: 'Edit comment' }).click();
    await page.getByLabel('Message').fill(editedReply);
    await page.getByRole('button', { name: 'Save changes' }).click();
    await expect(page.getByText(editedReply)).toBeVisible();

    const editCommentHref = await page.getByRole('link', { name: 'Edit comment' }).first().getAttribute('href');
    const commentId = editCommentHref.split('/')[2];
    const deleteResponse = await page.request.delete(base + '/api/v4/comment', {
      data: { comment_id: Number(commentId), deleted: true }
    });
    expect(deleteResponse.ok()).toBeTruthy();
    await page.reload();
    await expect(page.getByText(editedReply)).toHaveCount(0);

    await page.goto(base + '/c/' + communityName + '/settings');
    await expect(page.getByRole('heading', { name: 'Manage community' })).toBeVisible();
    await expect(page.getByRole('heading', { name: 'Managers' })).toBeVisible();
    await expect(page.getByText('http://localhost/u/' + adminUser)).toBeVisible();
    await expect(page.getByLabel('Sidebar (Markdown)')).toHaveValue('Sidebar ' + suffix);

    await page.goto(base + '/admin');
    await expect(page.getByRole('heading').first()).toBeVisible();
    await page.goto(base + '/reports');
    await expect(page.getByRole('heading').first()).toBeVisible();
    await page.goto(base + '/modlog');
    await expect(page.getByRole('heading').first()).toBeVisible();

    await page.goto(base + '/search?kind=posts&q=' + encodeURIComponent(editedTitle));
    await expect(page.getByRole('link', { name: editedTitle })).toBeVisible();

    await page.goto(base + '/settings');
    await page.getByLabel('Display name').fill('Admin E2E');
    await page.getByRole('button', { name: 'Save profile' }).click();
    await expect(page.getByText('Changes saved.')).toBeVisible();

    await page.goto(base + '/notifications');
    await expect(page.getByRole('heading').first()).toBeVisible();

    await page.goto(base + '/signup');
    await expect(page.getByText('Registration requires administrator approval.')).toBeVisible();

    await page.goto(base + '/post/' + postId);
    const axe = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa']).analyze();
    expect(axe.violations).toEqual([]);

    await page.getByRole('button', { name: 'Log out' }).click();
    await expect(page).toHaveURL(/\/login$/);
  });
});
