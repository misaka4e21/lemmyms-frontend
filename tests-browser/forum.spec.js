import AxeBuilder from '@axe-core/playwright';
import { expect, test } from '@playwright/test';

const person = {
  id: 1,
  name: 'alice',
  display_name: 'Alice',
  avatar: null,
  banner: null,
  bio: 'Bio',
  local: true,
  deleted: false,
  bot_account: false,
  ap_id: 'https://forum.test/u/alice',
  instance_id: 1,
  post_count: 1,
  comment_count: 0,
  published_at: '2026-10-20T08:30:00Z',
  updated_at: null
};

const community = {
  id: 1,
  name: 'news',
  title: 'News',
  sidebar: 'Daily **news**',
  summary: 'Daily news',
  removed: false,
  published_at: '2026-10-20T08:30:00Z',
  deleted: false,
  nsfw: false,
  ap_id: 'https://forum.test/c/news',
  local: true,
  icon: null,
  banner: null,
  posting_restricted_to_mods: false,
  visibility: 'public',
  subscribers: 4,
  posts: 1,
  comments: 1,
  users_active_day: 1,
  users_active_week: 1,
  users_active_month: 1,
  users_active_half_year: 1,
  subscribers_local: 4,
  report_count: 0,
  unresolved_report_count: 0,
  post_upvotes: 'all',
  post_downvotes: 'all',
  comment_upvotes: 'all',
  comment_downvotes: 'all',
  instance_id: 1,
  updated_at: null
};

const communityActions = {
  followed_at: '2026-10-20T08:30:00Z',
  blocked_at: null,
  became_moderator_at: '2026-10-20T08:30:00Z',
  received_ban_at: null,
  ban_expires_at: null,
  follow_state: 'accepted',
  notifications: null
};

const post = {
  id: 1,
  name: 'Hello world',
  url: null,
  body: 'Hello **world**',
  creator_id: 1,
  community_id: 1,
  removed: false,
  locked: false,
  published_at: '2026-10-20T08:30:00Z',
  updated_at: null,
  deleted: false,
  nsfw: false,
  thumbnail_url: null,
  ap_id: 'https://forum.test/post/1',
  local: true,
  language_id: 0,
  featured_community: false,
  featured_local: false,
  alt_text: null,
  comments: 1,
  score: 2,
  upvotes: 2,
  downvotes: 0,
  report_count: 0,
  unresolved_report_count: 0,
  newest_comment_time_at: null
};

const postActions = {
  read_at: null,
  read_comments_at: null,
  saved_at: null,
  voted_at: null,
  hidden_at: null,
  vote_is_upvote: null,
  read_comments_amount: 0,
  notifications: null
};

const comment = {
  id: 10,
  creator_id: 2,
  post_id: 1,
  content: 'A reply',
  removed: false,
  published_at: '2026-10-20T08:31:00Z',
  updated_at: null,
  deleted: false,
  ap_id: 'https://forum.test/comment/10',
  local: true,
  path: '0.10',
  distinguished: false,
  language_id: 0,
  score: 0,
  upvotes: 0,
  downvotes: 0,
  child_count: 0,
  report_count: 0,
  unresolved_report_count: 0,
  locked: false
};

const replyPerson = { ...person, id: 2, name: 'bob', display_name: 'Bob', ap_id: 'https://forum.test/u/bob' };

const myUser = {
  local_user_view: {
    local_user: {
      id: 1,
      person_id: 1,
      email: 'alice@forum.test',
      show_nsfw: false,
      blur_nsfw: false,
      theme: 'browser',
      default_post_sort_type: 'active',
      default_listing_type: 'local',
      interface_language: 'browser',
      show_avatars: true,
      show_bot_accounts: true,
      show_read_posts: true,
      email_verified: true,
      accepted_application: true,
      admin: true,
      post_listing_mode: 'list',
      default_comment_sort_type: 'hot',
      show_score: true,
      show_upvotes: true,
      show_downvotes: 'show',
      local_site_id: 1
    },
    person,
    banned: false,
    ban_expires_at: null
  },
  follows: [],
  moderates: [{ community, moderator: person }],
  community_blocks: [],
  instance_communities_blocks: [],
  instance_persons_blocks: [],
  person_blocks: [],
  keyword_blocks: [],
  discussion_languages: [0]
};

const site = {
  site_view: {
    site: {
      id: 1,
      name: 'Commune test',
      sidebar: null,
      summary: null,
      icon: null,
      banner: null,
      content_warning: null,
      ap_id: 'https://forum.test/',
      instance_id: 1,
      published_at: '2026-10-20T08:30:00Z'
    },
    local_site: {
      id: 1,
      site_id: 1,
      site_setup: true,
      community_creation_admin_only: false,
      email_verification_required: false,
      private_instance: false,
      registration_mode: 'open',
      federation_enabled: true,
      default_post_listing_type: 'local',
      default_post_sort_type: 'active',
      default_comment_sort_type: 'hot',
      default_post_upvotes: 'all',
      default_post_downvotes: 'all',
      default_comment_upvotes: 'all',
      default_comment_downvotes: 'all',
      default_theme: 'browser',
      legal_information: null,
      hostname: 'forum.test'
    }
  },
  admins: [],
  version: '1.0.0-beta.3',
  tagline: null,
  my_feed_token: null,
  captcha_enabled: false
};

function pageOf(items) {
  return { items, next_page: null, prev_page: null };
}

function fixtures() {
  return {
    signedIn: false,
    posts: { 1: post },
    comments: { 10: comment },
    community,
    tags: [],
    crossPosts: [],
    calls: []
  };
}

function postView(state) {
  const value = state.posts[1];
  return {
    post: value,
    creator: person,
    community: state.community,
    community_actions: communityActions,
    tags: state.tags,
    post_actions: { ...postActions },
    creator_is_admin: true,
    can_mod: true,
    creator_is_moderator: true,
    creator_banned_from_community: false
  };
}

function commentView(state) {
  return {
    comment: state.comments[10],
    creator: replyPerson,
    post: state.posts[1],
    community: state.community,
    community_actions: communityActions,
    comment_actions: { voted_at: null, saved_at: null, vote_is_upvote: null },
    person_actions: null,
    creator_is_admin: false,
    can_mod: true,
    tags: state.tags
  };
}

function communityView(state) {
  return { community: state.community, community_actions: communityActions, can_mod: true, tags: state.tags };
}

function notificationView() {
  return {
    notification: {
      id: 1,
      recipient_id: 1,
      comment_id: 10,
      read: false,
      published_at: '2026-10-20T08:31:00Z',
      kind: 'reply',
      post_id: 1,
      private_message_id: null,
      modlog_id: null,
      creator_id: 2
    },
    data: {
      type_: 'comment',
      comment,
      creator: replyPerson,
      post,
      community,
      comment_actions: { voted_at: null, saved_at: null, vote_is_upvote: null },
      creator_is_admin: false,
      can_mod: true
    }
  };
}

function reportView() {
  return {
    type_: 'post',
    post_report: {
      id: 7,
      creator_id: 2,
      post_id: 1,
      original_post_name: 'Hello world',
      original_post_url: null,
      original_post_body: 'Hello **world**',
      reason: 'spam',
      resolved: false,
      resolver_id: null,
      published_at: '2026-10-20T08:32:00Z',
      updated_at: null,
      violates_instance_rules: false,
      conclusion: null
    },
    post,
    community,
    creator: replyPerson,
    resolver: null,
    post_creator: person,
    creator_is_admin: false,
    creator_is_moderator: false,
    creator_banned: false,
    creator_banned_from_community: false
  };
}

function modlogView() {
  return {
    modlog: {
      id: 3,
      kind: 'mod_ban_from_community',
      is_revert: false,
      reason: 'spam',
      expires_at: null,
      published_at: '2026-10-20T08:33:00Z',
      bulk_action_parent_id: null,
      child_count: 0
    },
    moderator: person,
    target_person: replyPerson,
    target_community: community
  };
}

async function mockApi(page, state, { authenticated = false } = {}) {
  state.signedIn = authenticated;
  await page.route('**/api/v4/**', async route => {
    const request = route.request();
    const url = new URL(request.url());
    const path = url.pathname;
    const method = request.method();
    let body = {};
    try { body = request.postDataJSON() || {}; } catch { body = {}; }
    state.calls.push({ method, path, search: url.search, body });

    if (path === '/api/v4/site') return json(route, 200, site);
    if (path === '/api/v4/account') return state.signedIn ? json(route, 200, myUser) : json(route, 401, { error: 'not_logged_in' });
    if (path === '/api/v4/account/unread_counts') return json(route, 200, { notification_count: 1 });
    if (path === '/api/v4/account/notification/list') return json(route, 200, pageOf([notificationView()]));
    if (path === '/api/v4/account/notification/mark_as_read') return route.fulfill({ status: 204 });
    if (path === '/api/v4/account/notification/mark_as_read/all') return route.fulfill({ status: 204 });
    if (path === '/api/v4/account/settings/save' && method === 'PUT') {
      myUser.local_user_view.person.display_name = body.display_name || 'Alice';
      myUser.local_user_view.person.bio = body.bio || '';
      return json(route, 200, { success: true });
    }
    if (path === '/api/v4/account/auth/verify_email' && method === 'POST') return json(route, 200, { success: true });
    if (path === '/api/v4/account/auth/password_change' && method === 'POST') return json(route, 200, { success: true });
    if (path === '/api/v4/person') return json(route, 200, { person_view: { person, is_admin: true, person_actions: null, banned: false, ban_expires_at: null } });
    if (path === '/api/v4/post/list') return json(route, 200, pageOf([postView(state)]));
    if (path === '/api/v4/post' && method === 'GET') return json(route, 200, { post_view: postView(state), community_view: communityView(state), cross_posts: state.crossPosts, moderators: [{ community, moderator: person }] });
    if (path === '/api/v4/person/content') {
      const type = url.searchParams.get('type_');
      return json(route, 200, {
        items: [type === 'comments' ? { type_: 'comment', ...commentView(state) } : { type_: 'post', ...postView(state) }],
        next_page: null,
        prev_page: null
      });
    }
    if (path === '/api/v4/account/saved' || path === '/api/v4/account/liked' || path === '/api/v4/account/read' || path === '/api/v4/account/hidden') {
      return json(route, 200, pageOf([postView(state)]));
    }
    if (path === '/api/v4/post' && method === 'POST') {
      state.posts[1] = { ...post, id: 2, name: body.name, body: body.body };
      return json(route, 200, { post_view: postView(state) });
    }
    if (path === '/api/v4/post' && method === 'PUT') return json(route, 200, { post_view: postView(state) });
    if (path === '/api/v4/post/like') {
      postActions.vote_is_upvote = body.is_upvote;
      state.posts[1].score = body.is_upvote === false ? -1 : body.is_upvote === true ? 1 : 0;
      return json(route, 200, { post_view: postView(state) });
    }
    if (path === '/api/v4/post/save' || path === '/api/v4/post/mark_as_read' || path === '/api/v4/post/hide') return json(route, 200, { post_view: postView(state) });
    if (path === '/api/v4/comment/list') return json(route, 200, pageOf([commentView(state)]));
    if (path === '/api/v4/comment' && method === 'GET') {
      if (url.searchParams.get('id') === '999') return json(route, 404, { error: 'could_not_find_comment' });
      return json(route, 200, { comment_view: commentView(state) });
    }
    if (path === '/api/v4/comment' && method === 'POST') {
      state.comments[10] = { ...comment, content: body.content };
      return json(route, 200, { comment_view: commentView(state) });
    }
    if (path === '/api/v4/comment' && method === 'PUT') {
      state.comments[10] = { ...state.comments[10], content: body.content };
      return json(route, 200, { comment_view: commentView(state) });
    }
    if (path === '/api/v4/comment' && method === 'DELETE') return json(route, 200, { success: true });
    if (path === '/api/v4/post/like/list' || path === '/api/v4/comment/like/list') {
      return json(route, 200, {
        items: [{ creator: replyPerson, creator_banned: false, creator_banned_from_community: false, is_upvote: true }],
        next_page: null,
        prev_page: null
      });
    }
    if (path === '/api/v4/post/remove' || path === '/api/v4/post/lock' || path === '/api/v4/post/feature' || path === '/api/v4/comment/remove' || path === '/api/v4/comment/lock' || path === '/api/v4/comment/distinguish' || path === '/api/v4/account/block/person' || path === '/api/v4/account/block/community' || path === '/api/v4/post/mark_as_read') {
      return route.fulfill({ status: 204 });
    }
    if (path === '/api/v4/community/list') return json(route, 200, pageOf([communityView(state)]));
    if (path === '/api/v4/community' && method === 'GET') return json(route, 200, { community_view: communityView(state), moderators: [{ community, moderator: person }], discussion_languages: [0] });
    if (path === '/api/v4/community' && method === 'POST') {
      state.community = { ...community, id: 2, name: body.name, title: body.title, visibility: body.visibility };
      return json(route, 200, { community_view: communityView(state), moderators: [{ community: state.community, moderator: person }], discussion_languages: [0] });
    }
    if (path === '/api/v4/community' && method === 'PUT') return json(route, 200, { community_view: communityView(state), moderators: [{ community, moderator: person }], discussion_languages: [0] });
    if (path === '/api/v4/community/follow') return route.fulfill({ status: 204 });
    if (path === '/api/v4/community/tag') return route.fulfill({ status: 204 });
    if (path === '/api/v4/community/notifications') return route.fulfill({ status: 204 });
    if (path === '/api/v4/community/icon' || path === '/api/v4/community/banner') {
      return json(route, 200, { image_url: 'https://forum.test/pictrs/image/community.png', filename: 'community.png' });
    }
    if (path === '/api/v4/community/mod' || path === '/api/v4/community/ban_user') return route.fulfill({ status: 204 });
    if (path === '/api/v4/community/pending_follows/list') return json(route, 200, pageOf([]));
    if (path === '/api/v4/search') {
      return json(route, 200, {
        resolve: (url.searchParams.get('search_term') || '').includes('http') ? { type_: 'post', ...postView(state) } : null,
        comments: url.searchParams.get('type_') === 'comments' ? [commentView(state)] : [],
        posts: url.searchParams.get('type_') === 'posts' ? [postView(state)] : [],
        communities: url.searchParams.get('type_') === 'communities' ? [communityView(state)] : [],
        persons: url.searchParams.get('type_') === 'users' ? [{ person, is_admin: true, person_actions: null, banned: false, ban_expires_at: null }] : [],
        prev_page: null,
        next_page: null
      });
    }
    if (path === '/api/v4/report/list') {
      const cursor = url.searchParams.get('page_cursor');
      return json(route, 200, {
        items: [reportView()],
        prev_page: cursor ? 'first' : null,
        next_page: cursor ? null : 'next-report'
      });
    }
    if (path.endsWith('/report/resolve')) return route.fulfill({ status: 204 });
    if (path === '/api/v4/modlog') return json(route, 200, pageOf([modlogView()]));
    if (path === '/api/v4/admin/ban') return route.fulfill({ status: 204 });
    if (path === '/api/v4/account/auth/logout') { state.signedIn = false; return route.fulfill({ status: 204 }); }
    return json(route, 404, { error: 'not_found' });
  });
  await page.route('**/api/v3/user/login', async route => {
    state.signedIn = true;
    return route.fulfill({ status: 200, contentType: 'application/json', headers: { 'set-cookie': 'jwt=mock; Path=/; HttpOnly; SameSite=Lax' }, body: JSON.stringify({ jwt: 'mock' }) });
  });
}

function json(route, status, body) {
  return route.fulfill({ status, contentType: 'application/json; charset=utf-8', body: JSON.stringify(body) });
}

async function open(page, path) {
  await page.goto(path);
  await expect(page.locator('main')).toBeVisible();
}

test('browses latest, community, post and search', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/');
  await expect(page.getByRole('heading', { name: 'Latest discussions' }).first()).toBeVisible();
  await expect(page.getByRole('link', { name: 'Hello world' })).toBeVisible();
  await expect(page.getByText('Hello world').first()).toBeVisible();
  await page.getByRole('link', { name: 'Hello world' }).click();
  await expect(page.getByRole('heading', { level: 1, name: 'Hello world' })).toBeVisible();
  await expect(page.getByText('A reply')).toBeVisible();
  await page.goto('/communities');
  await expect(page.getByRole('link', { name: 'News' })).toBeVisible();
  const communityListCall = state.calls.find(call => call.path === '/api/v4/community/list');
  expect(communityListCall).toBeTruthy();
  const communitySort = new URLSearchParams(communityListCall.search).get('sort');
  expect(['active_six_months', 'active_monthly', 'active_weekly', 'active_daily', 'hot', 'new', 'old', 'name_asc', 'name_desc', 'comments', 'posts', 'subscribers', 'subscribers_local']).toContain(communitySort);
  expect(communitySort).not.toBe('top');
  await page.getByRole('link', { name: 'News' }).click();
  await expect(page.getByRole('heading', { level: 1, name: 'News' })).toBeVisible();
  const renderedLinks = await page.locator('a').evaluateAll(nodes => nodes.map(node => node.getAttribute('href') || ''));
  expect(renderedLinks.some(href => /^\/communities\/\d+/.test(href) || /^\/posts\//.test(href) || /^\/profiles\//.test(href))).toBe(false);
  await page.goBack();
  await expect(page.getByRole('link', { name: 'News' })).toBeVisible();
  await page.goForward();
  await expect(page.getByRole('heading', { level: 1, name: 'News' })).toBeVisible();
  await page.goto('/search?kind=posts&q=Hello');
  await expect(page.getByRole('link', { name: 'Hello world' })).toBeVisible();
});

test('logs in, posts, replies and edits a comment', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state);
  await page.goto('/login');
  await page.getByLabel('Username or email').fill('alice');
  await page.getByLabel('Password').fill('long-enough-password');
  await page.getByRole('button', { name: 'Log in', exact: true }).click();
  await expect(page.locator('#navigation-drawer')).toContainText('@alice');
  await page.goto('/create_post?community_id=1');
  await page.getByLabel('Topic title').fill('New topic');
  await page.getByLabel('Message').fill('New body');
  await page.getByRole('button', { name: 'Publish topic' }).click();
  await expect(page.getByRole('heading', { level: 1, name: 'New topic' })).toBeVisible();
  await page.getByRole('button', { name: 'Reply', exact: true }).click();
  await page.getByLabel('Message').fill('New reply');
  await page.getByRole('button', { name: 'Publish reply' }).click();
  await expect(page.getByText('New reply')).toBeVisible();
  await page.getByRole('link', { name: 'Edit comment' }).click();
  await page.getByLabel('Message').fill('Edited reply');
  await page.getByRole('button', { name: 'Save changes' }).click();
  await expect(page.getByText('Edited reply')).toBeVisible();
});

test('votes, saves and hides a post', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await page.goto('/post/1');
  const postArticle = page.getByRole('article').filter({ hasText: 'Hello world' }).first();
  await postArticle.getByRole('button', { name: /^Upvote/ }).click();
  await expect(postArticle.getByRole('button', { name: /^Clear vote/ })).toBeVisible();
  await postArticle.getByRole('button', { name: 'Save post' }).click();
  await postArticle.getByRole('button', { name: 'Hide for me' }).click();
});

test('updates profile and reads notifications', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await page.goto('/settings');
  await page.getByLabel('Display name').fill('Alice Updated');
  await page.getByRole('button', { name: 'Save profile' }).click();
  await expect(page.getByText('Changes saved.')).toBeVisible();
  await page.goto('/notifications');
  await expect(page.locator('.notification-list')).toContainText('bob');
});

test('admin report and modlog pages render', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await page.goto('/reports');
  await expect(page.getByText('spam')).toBeVisible();
  await page.goto('/modlog');
  await expect(page.getByText('mod_ban_from_community')).toBeVisible();
});

test('resolves comment permalinks and canonical account routes', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await page.goto('/comment/10');
  await expect(page).toHaveURL(/\/post\/1\/10$/);
  await expect(page.locator('#comment-10')).toBeFocused();
  await page.goto('/post/1/10');
  await expect(page.locator('#comment-10')).toBeFocused();
  await page.goto('/u/alice');
  await expect(page.getByText('Bio')).toBeVisible();
  await page.goto('/settings');
  const displayName = await page.getByLabel('Display name').inputValue();
  await page.goto('/settings/profile');
  await expect(page.getByLabel('Display name')).toHaveValue(displayName);
});

test('rejects former Commune routes and missing comment targets', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state);
  for (const path of ['/communities/1', '/posts/1', '/profiles/alice', '/register']) {
    await page.goto(path);
    await expect(page.getByRole('heading', { name: 'This content is unavailable.' })).toBeVisible();
  }
  await page.goto('/comment/999');
  await expect(page.getByText('This content is unavailable.')).toBeVisible();
  await expect(page.getByRole('article')).toHaveCount(0);
});

test('keeps token paths until submission and replaces them after success', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state);
  await page.goto('/verify_email/token-123');
  await expect(page).toHaveURL(/\/verify_email\/token-123$/);
  await page.getByLabel('Password').fill('long-enough-password');
  await page.getByRole('button', { name: 'Finish registration' }).click();
  await expect(page).toHaveURL(/\/login$/);
  await page.goto('/password_change/token-456');
  await expect(page).toHaveURL(/\/password_change\/token-456$/);
  await page.getByLabel('New password').fill('long-enough-password');
  await page.getByRole('button', { name: 'Set new password' }).click();
  await expect(page).toHaveURL(/\/login$/);
});

test('preserves report filters across cursor pagination', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await page.goto('/reports');
  await page.getByLabel('Report state').selectOption('open');
  await page.getByLabel('Community ID').fill('1');
  await page.getByRole('button', { name: 'Apply filter' }).click();
  await expect(page).toHaveURL(/state=open/);
  await expect(page).toHaveURL(/community_id=1/);
  await page.getByRole('link', { name: 'Next page' }).click();
  await expect(page).toHaveURL(/page_cursor=next-report/);
  await expect(page).toHaveURL(/state=open/);
  await expect(page).toHaveURL(/community_id=1/);
  const reportCalls = state.calls.filter(call => call.path === '/api/v4/report/list');
  expect(reportCalls.some(call => call.search.includes('page_cursor=next-report'))).toBeTruthy();
});

test('loads community management by name and uses the resolved id', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await page.goto('/c/news/settings');
  await expect(page.getByRole('heading', { name: 'Manage community' })).toBeVisible();
  await page.getByLabel('Person ID').fill('2');
  await page.getByRole('button', { name: 'Add manager' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/community/mod' && call.body.community_id === 1)).toBeTruthy();
});

test('applies listing controls, view modes, NSFW reveal, and cross-posts', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/');
  await page.getByLabel('Listing').selectOption('subscribed');
  await expect(page).toHaveURL(/type=subscribed/);
  await page.getByLabel('Sort').selectOption('new');
  await expect(page).toHaveURL(/sort=new/);
  await page.getByLabel('Time range').selectOption('86400');
  await expect(page).toHaveURL(/time_range=86400/);
  await page.getByLabel('Layout').selectOption('small_card');
  await expect(page).toHaveURL(/view=small_card/);
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/post/list' && call.search.includes('type=subscribed') && call.search.includes('sort=new') && call.search.includes('time_range_seconds=86400'))).toBeTruthy();
  await expect(page.locator('.post-card-small_card')).toBeVisible();

  state.posts[1] = { ...post, nsfw: true, thumbnail_url: 'https://forum.test/pictrs/image/post.png' };
  myUser.local_user_view.local_user.blur_nsfw = true;
  const cross = postView(state);
  cross.post = { ...cross.post, id: 2, name: 'Cross post' };
  state.crossPosts = [cross];
  await page.goto('/post/1');
  await expect(page.locator('#post-1').getByText('Show NSFW content')).toBeVisible();
  await expect(page.locator('#post-1 .post-content')).not.toBeVisible();
  await page.locator('#post-1').getByText('Show NSFW content').click();
  await expect(page.locator('#post-1 .post-content')).toBeVisible();
  await expect(page.getByRole('heading', { name: 'Cross-posts' })).toBeVisible();
});

test('performs moderation actions and opens the vote list', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await page.goto('/post/1');
  const postArticle = page.getByRole('article').filter({ hasText: 'Hello world' }).first();
  await postArticle.getByText('Action').click();
  await postArticle.getByRole('button', { name: 'Remove' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/post/remove')).toBeTruthy();
  await page.goto('/post/1');
  await postArticle.getByText('Action').click();
  await postArticle.getByRole('button', { name: 'Lock post' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/post/lock')).toBeTruthy();
  await page.goto('/post/1');
  await postArticle.getByText('Action').click();
  await postArticle.getByRole('button', { name: 'Feature in community' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/post/feature')).toBeTruthy();

  await page.goto('/post/1');
  await postArticle.getByText('Action').click();
  await postArticle.getByRole('button', { name: 'Mark read' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/post/mark_as_read')).toBeTruthy();
  await page.goto('/post/1');
  await postArticle.getByText('Action').click();
  await postArticle.getByRole('button', { name: 'Block community' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/account/block/community')).toBeTruthy();

  await page.goto('/post/1');
  await postArticle.getByText('Action').click();
  await postArticle.getByRole('button', { name: 'View votes' }).click();
  await expect(page.locator('#vote-dialog')).toBeVisible();
  await expect(page.locator('#vote-dialog')).toContainText('bob');
  await page.locator('#vote-dialog').getByRole('button', { name: 'Close', exact: true }).click();
  await expect(page.locator('#vote-dialog')).toHaveCount(0);
  await expect(page.locator('#view-votes-post-1')).toBeFocused();

  const commentArticle = page.getByRole('article').filter({ hasText: 'A reply' }).first();
  await commentArticle.getByText('Action').click();
  await commentArticle.getByRole('button', { name: 'Distinguish comment' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/comment/distinguish')).toBeTruthy();
  await page.goto('/post/1');
  await commentArticle.getByText('Action').click();
  await commentArticle.getByRole('button', { name: 'Lock post' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/comment/lock')).toBeTruthy();
  await page.goto('/post/1');
  await commentArticle.getByText('Action').click();
  await commentArticle.getByRole('button', { name: 'Remove' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/comment/remove')).toBeTruthy();
});

test('shows community tags, moderators, notifications, and uploaded images', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  state.tags = [{ id: 5, name: 'news', display_name: 'News tag', summary: null, community_id: 1, color: 'color_01', deleted: false }];
  await mockApi(page, state, { authenticated: true });
  await page.goto('/c/news');
  await expect(page.getByText('News tag')).toBeVisible();
  await expect(page.getByRole('heading', { name: 'Moderators' })).toBeVisible();
  await page.getByLabel('Community notifications').selectOption('mute');
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/community/notifications' && call.body.mode === 'mute')).toBeTruthy();

  await page.goto('/c/news/settings');
  await page.getByLabel('Tag name').fill('release');
  await page.getByRole('button', { name: 'Add tag' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/community/tag' && call.body.name === 'release')).toBeTruthy();
  await page.getByRole('button', { name: 'Delete tag' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/community/tag' && call.body.delete === true)).toBeTruthy();
  await page.locator('#manage-icon').setInputFiles({ name: 'icon.png', mimeType: 'image/png', buffer: Buffer.from('icon') });
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/community/icon')).toBeTruthy();
  await page.locator('#manage-banner').setInputFiles({ name: 'banner.png', mimeType: 'image/png', buffer: Buffer.from('banner') });
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/community/banner')).toBeTruthy();
});

test('searches comments, users, and URLs, and switches profile tabs', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await page.goto('/search?kind=comments&q=A');
  await expect(page.getByText('A reply')).toBeVisible();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/search' && call.search.includes('type_=comments'))).toBeTruthy();

  await page.goto('/search?kind=users&q=alice');
  await expect(page.getByRole('link', { name: 'Alice' })).toBeVisible();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/search' && call.search.includes('type_=users'))).toBeTruthy();

  await page.goto('/search?kind=url&q=https%3A%2F%2Fexample.test%2Fpost');
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/search' && call.search.includes('post_url_only=true'))).toBeTruthy();
  await expect(page.getByRole('heading', { name: 'Resolved' })).toBeVisible();

  await page.goto('/u/alice');
  await page.getByRole('tab', { name: 'Comments' }).click();
  await expect(page).toHaveURL(/view=comments/);
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/person/content' && call.search.includes('type_=comments'))).toBeTruthy();
  await page.getByRole('tab', { name: 'Comments' }).focus();
  await page.keyboard.press('ArrowRight');
  await expect(page).toHaveURL(/view=saved/);
  await page.getByRole('tab', { name: 'Saved' }).click();
  await expect(page).toHaveURL(/view=saved/);
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/account/saved')).toBeTruthy();
});

test('has no automated accessibility violations on the latest page', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state);
  await page.goto('/');
  const axe = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa']).analyze();
  expect(axe.violations).toEqual([]);
});
