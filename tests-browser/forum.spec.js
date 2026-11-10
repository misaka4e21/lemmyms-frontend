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
    creator_is_admin: false,
    can_mod: true
  };
}

function communityView(state) {
  return { community: state.community, community_actions: communityActions, can_mod: true };
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
    if (path === '/api/v4/person') return json(route, 200, { person_view: { person, is_admin: true, person_actions: null, banned: false, ban_expires_at: null } });
    if (path === '/api/v4/post/list') return json(route, 200, pageOf([postView(state)]));
    if (path === '/api/v4/post' && method === 'GET') return json(route, 200, { post_view: postView(state), community_view: communityView(state), cross_posts: [], moderators: [{ community, moderator: person }] });
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
    if (path === '/api/v4/comment' && method === 'GET') return json(route, 200, { comment_view: commentView(state) });
    if (path === '/api/v4/comment' && method === 'POST') {
      state.comments[10] = { ...comment, content: body.content };
      return json(route, 200, { comment_view: commentView(state) });
    }
    if (path === '/api/v4/comment' && method === 'PUT') {
      state.comments[10] = { ...state.comments[10], content: body.content };
      return json(route, 200, { comment_view: commentView(state) });
    }
    if (path === '/api/v4/comment' && method === 'DELETE') return json(route, 200, { success: true });
    if (path === '/api/v4/community/list') return json(route, 200, pageOf([communityView(state)]));
    if (path === '/api/v4/community' && method === 'GET') return json(route, 200, { community_view: communityView(state), moderators: [{ community, moderator: person }], discussion_languages: [0] });
    if (path === '/api/v4/community' && method === 'POST') {
      state.community = { ...community, id: 2, name: body.name, title: body.title, visibility: body.visibility };
      return json(route, 200, { community_view: communityView(state), moderators: [{ community: state.community, moderator: person }], discussion_languages: [0] });
    }
    if (path === '/api/v4/community' && method === 'PUT') return json(route, 200, { community_view: communityView(state), moderators: [{ community, moderator: person }], discussion_languages: [0] });
    if (path === '/api/v4/community/follow') return route.fulfill({ status: 204 });
    if (path === '/api/v4/community/pending_follows/list') return json(route, 200, pageOf([]));
    if (path === '/api/v4/search') {
      return json(route, 200, {
        resolve: null,
        comments: [],
        posts: url.searchParams.get('type_') === 'posts' ? [postView(state)] : [],
        communities: url.searchParams.get('type_') === 'communities' ? [communityView(state)] : [],
        persons: [],
        prev_page: null,
        next_page: null
      });
    }
    if (path === '/api/v4/report/list') return json(route, 200, pageOf([reportView()]));
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
  await mockApi(page, state);
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
  await page.goto('/communities/1/new');
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
  await page.goto('/posts/1');
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
  await page.goto('/settings/profile');
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
  await page.goto('/admin/reports');
  await expect(page.getByText('spam')).toBeVisible();
  await page.goto('/admin/modlog');
  await expect(page.getByText('mod_ban_from_community')).toBeVisible();
});

test('has no automated accessibility violations on the latest page', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state);
  await page.goto('/');
  const axe = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa']).analyze();
  expect(axe.violations).toEqual([]);
});
