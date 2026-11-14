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
const remotePerson = { ...person, id: 3, name: 'carol', display_name: 'Carol', local: false, ap_id: 'https://remote.test/u/carol' };

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
    postCreator: null,
    privateMessage: privateMessageView(),
    failPrivateMessage: false,
    multiCommunity: multiCommunityView(),
    multiCommunities: [multiCommunityView()],
    entryLimit: false,
    privateReport: false,
    failSettings: false,
    calls: []
  };
}

function postView(state) {
  const value = state.posts[1];
  return {
    post: value,
    creator: state.postCreator || person,
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

function privateMessageView() {
  return {
    private_message: {
      id: 30,
      creator_id: 2,
      recipient_id: 1,
      content: 'Hello **there**',
      deleted: false,
      deleted_by_recipient: false,
      removed: false,
      published_at: '2026-10-20T08:31:00Z',
      updated_at: null,
      ap_id: 'https://forum.test/private_message/30',
      local: true
    },
    creator: replyPerson,
    recipient: person
  };
}

function privateMessageNotification(state) {
  return {
    notification: {
      id: 2,
      recipient_id: 1,
      comment_id: null,
      read: false,
      published_at: '2026-10-20T08:31:00Z',
      kind: 'private_message',
      post_id: null,
      private_message_id: 30,
      modlog_id: null,
      creator_id: 2
    },
    data: {
      type_: 'private_message',
      ...state.privateMessage
    }
  };
}

function multiCommunityView() {
  return {
    multi: {
      id: 5,
      creator_id: 1,
      name: 'tech',
      title: 'Tech',
      summary: 'Grouped technology feeds',
      sidebar: 'Tech sidebar',
      local: true,
      deleted: false,
      ap_id: 'https://forum.test/m/tech',
      subscribers: 3,
      subscribers_local: 2,
      communities: 1,
      published_at: '2026-10-20T08:30:00Z',
      updated_at: null
    },
    follow_state: 'accepted',
    owner: person
  };
}

function multiCommunityResponse(state) {
  return {
    multi_community_view: state.multiCommunity,
    communities: [communityView(state)]
  };
}

function privateMessageReportView() {
  return {
    type_: 'private_message',
    private_message_report: {
      id: 9,
      creator_id: 1,
      private_message_id: 30,
      original_pm_text: 'Hello there',
      reason: 'spam',
      resolved: false,
      resolver_id: null,
      published_at: '2026-10-20T08:31:00Z',
      updated_at: null,
      conclusion: null
    },
    private_message: privateMessageView().private_message,
    creator: person,
    private_message_creator: replyPerson,
    resolver: null
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
  if (process.env.COMMUNE_TEST_ELM_JS) await page.route('**/elm.js', route => route.fulfill({ path: process.env.COMMUNE_TEST_ELM_JS, contentType: 'text/javascript' }));
  await page.route('**/api/v4/**', async route => {
    const request = route.request();
    const url = new URL(request.url());
    const path = url.pathname;
    const method = request.method();
    let body = {};
    try { body = request.postDataJSON() || {}; } catch { body = {}; }
    state.calls.push({ method, path, search: url.search, body });

    if (['/api/v4/site/icon', '/api/v4/site/banner'].includes(path)) {
      const target = state.configSite || site;
      const kind = path.split('/').at(-1);
      target.site_view.site[kind] = method === 'POST' ? `https://forum.test/${kind}.png` : null;
      return json(route, 200, method === 'POST' ? { image_url: target.site_view.site[kind], filename: `${kind}.png` } : { success: true });
    }
    if (path === '/api/v4/site' && method === 'POST') {
      if (state.failSiteSetup) return json(route, 400, { error: 'invalid_input' });
      site.site_view.local_site.site_setup = true;
      return json(route, 200, site.site_view);
    }
    if (path === '/api/v4/site' && method === 'PUT') {
      if (state.siteConfigDelay) await new Promise(resolve => setTimeout(resolve, state.siteConfigDelay));
      if (state.failSiteConfig) return json(route, 403, { error: 'not_an_admin' });
      const target = state.configSite || site;
      for (const [key, value] of Object.entries(body)) {
        if (['name', 'summary', 'sidebar', 'content_warning'].includes(key)) target.site_view.site[key] = value;
        else if (key === 'discussion_languages') target.discussion_languages = value;
        else if (key.startsWith('rate_limit_')) target.site_view.local_site_rate_limit[key.slice(11)] = value;
        else target.site_view.local_site[key] = value;
      }
      return json(route, 200, { site_view: target.site_view });
    }
    if (path === '/api/v4/site') return json(route, 200, { ...(state.configSite || site), admin_oauth_providers: state.providers || [], oauth_providers: state.publicProviders || [] });
    if (path === '/api/v4/oauth/authenticate') {
      if (state.oauthFail) return json(route, 400, { error: state.oauthFail === true ? 'oauth_authorization_invalid' : state.oauthFail });
      if (state.oauthEstablishSession) state.signedIn = true;
      return json(route, 200, state.oauthResult || { jwt: 'mock-token', registration_created: false, verify_email_sent: false });
    }
    if (path === '/api/v4/admin/users') {
      const cursor = url.searchParams.get('page_cursor');
      return json(route, 200, { items: state.siteUsers || [], prev_page: cursor ? 'first' : null, next_page: cursor ? null : 'next-user' });
    }
    if (path === '/api/v4/image/list') {
      if (state.failMedia) return json(route, 403, { error: 'forbidden' });
      const cursor = url.searchParams.get('page_cursor');
      return json(route, 200, { items: state.siteMedia || [], prev_page: cursor ? 'first' : null, next_page: cursor ? null : 'next-media' });
    }
    if (path === '/api/v4/admin/add') {
      if (state.failAdminChange) return json(route, 403, { error: 'forbidden' });
      state.siteUsers.find(item => item.person.id === body.person_id).local_user.admin = body.added;
      return json(route, 200, { admins: [] });
    }
    if (path === '/api/v4/oauth_provider') {
      if (state.failProvider) return json(route, 403, { error: 'forbidden' });
      if (method === 'POST') {
        const { client_secret, ...publicFields } = body;
        state.providers.push({ id: 15, ...publicFields });
      }
      if (method === 'PUT') {
        const provider = state.providers.find(item => item.id === body.id);
        const { client_secret, ...publicFields } = body;
        Object.assign(provider, publicFields);
      }
      if (method === 'DELETE') state.providers = state.providers.filter(item => item.id !== body.id);
      return json(route, 200, { success: true });
    }
    if (path === '/api/v4/admin/tagline/list') return json(route, 200, pageOf(state.taglines || []));
    if (path === '/api/v4/admin/tagline') {
      if (state.failTagline) return json(route, 400, { error: 'invalid_input' });
      if (method === 'POST') state.taglines.push({ id: 11, content: body.content, published_at: '2026-11-13T08:00:00Z' });
      if (method === 'PUT') state.taglines.find(item => item.id === body.id).content = body.content;
      if (method === 'DELETE') state.taglines = state.taglines.filter(item => item.id !== body.id);
      return json(route, 200, { success: true });
    }
    if (path === '/api/v4/custom_emoji/list') return json(route, 200, { custom_emojis: state.customEmojis || [] });
    if (path === '/api/v4/custom_emoji') {
      if (state.failEmoji) return json(route, 400, { error: 'invalid_input' });
      if (method === 'POST') state.customEmojis.push({ custom_emoji: { id: 12, ...body }, keywords: body.keywords.map(keyword => ({ keyword })) });
      if (method === 'PUT') {
        const item = state.customEmojis.find(emoji => emoji.custom_emoji.id === body.id);
        item.custom_emoji = { ...item.custom_emoji, ...body };
        item.keywords = body.keywords.map(keyword => ({ keyword }));
      }
      if (method === 'DELETE') state.customEmojis = state.customEmojis.filter(item => item.custom_emoji.id !== body.id);
      return json(route, 200, { success: true });
    }
    if (path === '/api/v4/admin/registration_application/list') {
      const cursor = url.searchParams.get('page_cursor');
      return json(route, 200, { items: state.applications || [], prev_page: cursor ? 'first' : null, next_page: cursor ? null : 'next-application' });
    }
    if (path === '/api/v4/admin/registration_application/approve') {
      if (state.applicationDelay) await new Promise(resolve => setTimeout(resolve, state.applicationDelay));
      if (state.failApplication) return json(route, 409, { error: 'conflict' });
      state.applications = [];
      return json(route, 200, { success: true });
    }
    if (path === '/api/v4/resolve_object') {
      const uri = url.searchParams.get('q');
      if (uri?.includes('unavailable')) return json(route, 404, { error: 'not_found' });
      if (uri?.includes('unsupported')) return json(route, 200, { type_: 'unknown' });
      return json(route, 200, { type_: 'community', ...communityView(state) });
    }
    if (path === '/api/v4/federated_instances') {
      if (state.failInstances) return json(route, 503, { error: 'unavailable' });
      if (state.federationRecords) return json(route, 200, pageOf(state.federationRecords));
      const filter = url.searchParams.get('domain_filter');
      const cursor = url.searchParams.get('page_cursor');
      const items = filter === 'missing' ? [] : [{ instance: { domain: cursor ? 'second.example' : 'first.example' } }];
      return json(route, 200, { items, ...(cursor ? { prev_page: 'first' } : {}), ...(!cursor && items.length ? { next_page: 'next' } : {}) });
    }
    if (path === '/api/v4/admin/instance/allow' || path === '/api/v4/admin/instance/block') {
      if (state.failFederation) return json(route, 400, { error: 'invalid_input' });
      const item = state.federationRecords.find(record => record.instance.domain === body.instance);
      if (path.endsWith('/allow')) item.allowed = body.allow ? {} : null;
      if (path.endsWith('/block')) item.blocked = body.block ? {} : null;
      return json(route, 200, item);
    }
    if (path === '/api/v4/account' && method === 'GET') return state.signedIn ? json(route, 200, state.identity || myUser) : json(route, 401, { error: 'not_logged_in' });
    if (path === '/api/v4/account/unread_counts') return json(route, 200, { notification_count: 1 });
    if (path === '/api/v4/account/notification/list') {
      if (url.searchParams.get('type_') === 'private_message') return json(route, 200, pageOf([privateMessageNotification(state)]));
      return json(route, 200, pageOf([notificationView()]));
    }
    if (path === '/api/v4/private_message' && method === 'POST') {
      if (state.failPrivateMessage) return json(route, 400, { error: 'invalid_input' });
      state.privateMessage.private_message.content = body.content;
      return json(route, 200, { private_message_view: state.privateMessage });
    }
    if (path === '/api/v4/private_message' && method === 'PUT') {
      state.privateMessage.private_message.content = body.content;
      return json(route, 200, { private_message_view: state.privateMessage });
    }
    if (path === '/api/v4/private_message' && method === 'DELETE') {
      state.privateMessage.private_message.deleted = true;
      return json(route, 200, { private_message_view: state.privateMessage });
    }
    if (path === '/api/v4/private_message/report') return route.fulfill({ status: 204 });
    if (path === '/api/v4/multi_community/list') return json(route, 200, pageOf(state.multiCommunities));
    if (path === '/api/v4/multi_community' && method === 'GET') return json(route, 200, multiCommunityResponse(state));
    if (path === '/api/v4/multi_community' && method === 'POST') {
      state.multiCommunity.multi.name = body.name || state.multiCommunity.multi.name;
      state.multiCommunity.multi.title = body.title || null;
      state.multiCommunity.multi.summary = body.summary || null;
      state.multiCommunity.multi.sidebar = body.sidebar || null;
      return json(route, 200, { multi_community_view: state.multiCommunity });
    }
    if (path === '/api/v4/multi_community' && method === 'PUT') {
      state.multiCommunity.multi.title = body.title || null;
      state.multiCommunity.multi.summary = body.summary || null;
      state.multiCommunity.multi.sidebar = body.sidebar || null;
      if (typeof body.deleted === 'boolean') state.multiCommunity.multi.deleted = body.deleted;
      return json(route, 200, { multi_community_view: state.multiCommunity });
    }
    if (path === '/api/v4/multi_community/entry' && method === 'POST') {
      if (state.entryLimit) return json(route, 400, { error: 'multi_community_entry_limit_reached' });
      return json(route, 200, { community_view: communityView(state), moderators: [] });
    }
    if (path === '/api/v4/multi_community/entry' && method === 'DELETE') return route.fulfill({ status: 204 });
    if (path === '/api/v4/multi_community/follow' && method === 'POST') {
      state.multiCommunity.follow_state = body.follow ? (state.multiCommunity.multi.local ? 'accepted' : 'pending') : null;
      return json(route, 200, { multi_community_view: state.multiCommunity });
    }
    if (path === '/api/v4/account/notification/mark_as_read') return route.fulfill({ status: 204 });
    if (path === '/api/v4/account/notification/mark_as_read/all') return route.fulfill({ status: 204 });
    if (path === '/api/v4/account/settings/save' && method === 'PUT') {
      if (state.failSettings) return json(route, 400, { error: 'invalid_input' });
      myUser.local_user_view.person.display_name = body.display_name || 'Alice';
      myUser.local_user_view.person.bio = body.bio || '';
      myUser.local_user_view.local_user.theme = body.theme || 'browser';
      myUser.local_user_view.local_user.default_listing_type = body.default_listing_type || 'local';
      myUser.local_user_view.local_user.default_items_per_page = body.default_items_per_page || 20;
      return json(route, 200, myUser);
    }
    if (path === '/api/v4/account/login/list') {
      return json(route, 200, { logins: [{ user_id: 1, published_at: '2026-10-20T08:30:00Z', ip: '127.0.0.1', user_agent: 'Playwright' }] });
    }
    if (path === '/api/v4/account/invite/list') {
      return json(route, 200, pageOf([{ token: 'invite-token', max_uses: 3, uses_count: 1, expires_at: '2027-01-01T00:00:00Z', published_at: '2026-10-20T08:30:00Z' }]));
    }
    if (path === '/api/v4/account/invite' && method === 'POST') return route.fulfill({ status: 204 });
    if (path === '/api/v4/account/invite' && method === 'DELETE') return route.fulfill({ status: 204 });
    if (path === '/api/v4/account/avatar' || path === '/api/v4/account/banner') {
      return json(route, 200, { image_url: 'https://forum.test/pictrs/image/account.png', filename: 'account.png' });
    }
    if (path === '/api/v4/account/auth/totp/generate') {
      return json(route, 200, { totp_secret_url: 'otpauth://totp/Forum:alice?secret=ABC123' });
    }
    if (path === '/api/v4/account/auth/totp/edit') {
      return json(route, 200, { enabled: Boolean(body.enabled) });
    }
    if (path === '/api/v4/account/auth/get_captcha') {
      return json(route, 200, { ok: { png: 'iVBORw0KGgo=', wav: 'UklGRg==', uuid: 'captcha-uuid' } });
    }
    if (path === '/api/v4/account/auth/register') {
      return json(route, 200, { jwt: null, registration_created: true, verify_email_sent: false });
    }
    if (path === '/api/v4/account/settings/export') {
      return json(route, 200, { display_name: 'Alice', settings: {} });
    }
    if (path === '/api/v4/account/data/export') {
      return json(route, 200, { person: { name: 'alice' } });
    }
    if (path === '/api/v4/account/settings/import') return route.fulfill({ status: 204 });
    if (path === '/api/v4/account/donation_dialog_shown') return route.fulfill({ status: 204 });
    if (path === '/api/v4/account' && method === 'DELETE') {
      state.signedIn = false;
      return route.fulfill({ status: 204 });
    }
    if (path === '/api/v4/account/auth/verify_email' && method === 'POST') return json(route, 200, { success: true });
    if (path === '/api/v4/account/auth/password_change' && method === 'POST') return json(route, 200, { success: true });
    if (path === '/api/v4/person') {
      if ((url.searchParams.get('username') || '').includes('carol')) return json(route, 404, { error: 'not_found' });
      if (url.searchParams.get('person_id') === '2' || url.searchParams.get('username') === 'bob') {
        return json(route, 200, { person_view: { person: replyPerson, is_admin: false, person_actions: null, banned: false, ban_expires_at: null } });
      }
      return json(route, 200, { person_view: { person, is_admin: true, person_actions: null, banned: false, ban_expires_at: null } });
    }
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
    if (path === '/api/v4/community/pending_follows/list') {
      if (!state.followQueue) return json(route, 200, pageOf([]));
      const cursor = url.searchParams.get('page_cursor');
      return json(route, 200, { items: state.followQueue, prev_page: cursor ? 'first' : null, next_page: cursor ? null : 'next-follow' });
    }
    if (path === '/api/v4/community/pending_follows/approve') {
      if (state.failFollowDecision) return json(route, 409, { error: 'conflict' });
      state.followQueue = [];
      return json(route, 200, { success: true });
    }
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
      if (state.privateReport) {
        return json(route, 200, { items: [privateMessageReportView()], prev_page: null, next_page: null });
      }
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

test('shows current site legal information and its empty state', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state);
  site.site_view.local_site.legal_information = 'Read the **terms**.';
  try {
    await open(page, '/legal');
    await expect(page.getByRole('heading', { name: 'Legal information' })).toBeVisible();
    await expect(page.locator('main strong')).toHaveText('terms');
    site.site_view.local_site.legal_information = null;
    await page.reload();
    await expect(page.getByText('No content', { exact: true })).toBeVisible();
  } finally {
    site.site_view.local_site.legal_information = null;
  }
});

test('browses federated instances with filters, pagination, and errors', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state);
  await open(page, '/instances?kind=allowed&domain_filter=example');
  await expect(page.getByRole('heading', { name: 'Federated instances' })).toBeVisible();
  await expect(page.getByText('first.example')).toBeVisible();
  await page.getByRole('link', { name: 'Next page' }).click();
  await expect(page.getByText('second.example')).toBeVisible();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/federated_instances' && call.search.includes('kind=allowed') && call.search.includes('domain_filter=example') && call.search.includes('page_cursor=next'))).toBeTruthy();
  await page.getByLabel('Domain').fill('missing');
  await page.getByRole('button', { name: 'Filter' }).click();
  await expect(page.getByText('No content', { exact: true })).toBeVisible();
  state.failInstances = true;
  await page.reload();
  await expect(page.getByRole('alert')).toBeVisible();
});

test('preserves direct P4 routes across browser history', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await open(page, '/instances');
  await expect(page.getByRole('heading', { name: 'Federated instances' })).toBeVisible();
  await page.goto('/admin/users');
  await expect(page.getByRole('heading', { name: 'Site users' })).toBeVisible();
  await page.goBack();
  await expect(page.getByRole('heading', { name: 'Federated instances' })).toBeVisible();
  await page.goForward();
  await expect(page.getByRole('heading', { name: 'Site users' })).toBeVisible();
});

test('resolves external interaction and reports invalid or unavailable objects', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state);
  await page.goto('/activitypub/externalInteraction?uri=https%3A%2F%2Fremote.example%2Fc%2Fnews');
  await expect(page).toHaveURL(/\/c\/news$/);
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/resolve_object' && new URLSearchParams(call.search).get('q') === 'https://remote.example/c/news')).toBeTruthy();
  for (const uri of ['invalid', 'https://remote.example/unavailable', 'https://remote.example/unsupported']) {
    await page.goto(`/activitypub/externalInteraction?uri=${encodeURIComponent(uri)}`);
    await expect(page.getByRole('alert')).toBeVisible();
    await expect(page).toHaveURL(/externalInteraction/);
  }
});

test('reviews pending follows with admin filters and refreshes on success or conflict', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  state.followQueue = [{ person: replyPerson, community, is_new_instance: false, follow_state: 'approval_required' }];
  await mockApi(page, state, { authenticated: true });
  await open(page, '/pending_follows?all_communities=true&unread_only=true');
  await expect(page.getByText('bob@forum.test · news')).toBeVisible();
  await page.getByRole('link', { name: 'Next page' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/community/pending_follows/list' && call.search.includes('all_communities=true') && call.search.includes('unread_only=true') && call.search.includes('page_cursor=next-follow'))).toBeTruthy();
  state.failFollowDecision = true;
  await page.getByRole('button', { name: 'Reject' }).click();
  await expect(page.getByRole('alert')).toBeVisible();
  await expect(page.getByText('bob@forum.test · news')).toBeVisible();
  state.failFollowDecision = false;
  await page.getByRole('button', { name: 'Accept' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/community/pending_follows/approve' && call.body.community_id === 1 && call.body.follower_id === 2 && call.body.approve === true)).toBeTruthy();
  await expect(page.getByText('No pending follow requests.')).toBeVisible();
  state.followQueue = [{ person: replyPerson, community, is_new_instance: false, follow_state: 'approval_required' }];
  await page.reload();
  await page.getByRole('button', { name: 'Reject' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/community/pending_follows/approve' && call.body.approve === false)).toBeTruthy();
  await expect(page.getByText('No pending follow requests.')).toBeVisible();
});

test('limits pending follows to moderators and administrators', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  state.identity = { ...myUser, local_user_view: { ...myUser.local_user_view, local_user: { ...myUser.local_user_view.local_user, admin: false } } };
  state.followQueue = [{ person: replyPerson, community, is_new_instance: false, follow_state: 'approval_required' }];
  await mockApi(page, state, { authenticated: true });
  await open(page, '/pending_follows?all_communities=true');
  await expect(page.getByText('bob@forum.test · news')).toBeVisible();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/community/pending_follows/list' && call.search.includes('all_communities=false'))).toBeTruthy();
  state.identity = { ...state.identity, moderates: [] };
  await page.reload();
  await expect(page.getByRole('button', { name: 'Accept' })).toHaveCount(0);
  await expect(page.getByText('bob@forum.test · news')).toHaveCount(0);
});

test('reviews registration applications and preserves a rejected decision draft', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  state.applications = [{ registration_application: { id: 8, answer: 'I like the forum', published_at: '2026-11-13T08:00:00Z', deny_reason: null }, creator: replyPerson }];
  await mockApi(page, state, { authenticated: true });
  await open(page, '/registration_applications?unread_only=true');
  await expect(page.getByRole('heading', { name: 'Registration applications' })).toBeVisible();
  await expect(page.getByText('I like the forum')).toBeVisible();
  await page.getByRole('link', { name: 'Next page' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/admin/registration_application/list' && call.search.includes('unread_only=true') && call.search.includes('page_cursor=next-application'))).toBeTruthy();
  await page.getByLabel('Reason').fill('Needs more detail');
  state.failApplication = true;
  state.applicationDelay = 250;
  await page.getByRole('button', { name: 'Reject' }).click();
  await expect(page.locator('main .loading-state')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Reject' })).toBeDisabled();
  await expect(page.getByRole('alert')).toHaveText('This content changed. Your draft is safe; compare the latest source.');
  state.applicationDelay = 0;
  await expect(page.getByLabel('Reason')).toHaveValue('Needs more detail');
  state.failApplication = false;
  await page.getByRole('button', { name: 'Reject' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/admin/registration_application/approve' && call.method === 'PUT' && call.body.id === 8 && call.body.approve === false && call.body.deny_reason === 'Needs more detail')).toBeTruthy();
  await expect(page.getByText('No content', { exact: true })).toBeVisible();
  state.applications = [{ registration_application: { id: 9, answer: 'Another application', published_at: '2026-11-13T08:00:00Z' }, creator: replyPerson }];
  await page.reload();
  await page.getByRole('button', { name: 'Accept' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/admin/registration_application/approve' && call.body.id === 9 && call.body.approve === true && !('deny_reason' in call.body))).toBeTruthy();
});

test('denies registration application controls to non-admins', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  state.identity = { ...myUser, local_user_view: { ...myUser.local_user_view, local_user: { ...myUser.local_user_view.local_user, admin: false } } };
  await mockApi(page, state, { authenticated: true });
  await open(page, '/registration_applications');
  await expect(page.getByRole('alert')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Accept' })).toHaveCount(0);
  expect(state.calls.some(call => call.path === '/api/v4/admin/registration_application/list')).toBe(false);
});

test('site setup checks authorization and preserves a failed draft', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  site.site_view.local_site.site_setup = false;
  try {
    await open(page, '/setup');
    await page.getByLabel('Site name').fill('Example site');
    await page.getByLabel('Legal information').fill('Terms');
    state.failSiteSetup = true;
    await page.getByRole('button', { name: 'Save changes' }).click();
    await expect(page.getByRole('alert')).toBeVisible();
    await expect(page.getByLabel('Site name')).toHaveValue('Example site');
    state.failSiteSetup = false;
    await page.getByRole('button', { name: 'Save changes' }).click();
    await expect.poll(() => state.calls.some(call => call.path === '/api/v4/site' && call.method === 'POST' && call.body.name === 'Example site' && call.body.legal_information === 'Terms')).toBeTruthy();
    await expect(page).toHaveURL(/\/$/);
    await page.goto('/setup');
    await expect(page.getByText('This site has already been set up.')).toBeVisible();
    site.site_view.local_site.site_setup = false;
    state.identity = { ...myUser, local_user_view: { ...myUser.local_user_view, local_user: { ...myUser.local_user_view.local_user, admin: false } } };
    await page.reload();
    await expect(page.getByRole('alert')).toBeVisible();
    await expect(page.getByLabel('Site name')).toHaveCount(0);
    state.signedIn = false;
    await page.reload();
    await expect(page.getByRole('link', { name: 'Log in' }).last()).toBeVisible();
    expect(state.calls.filter(call => call.path === '/api/v4/site' && call.method === 'POST')).toHaveLength(2);
  } finally {
    site.site_view.local_site.site_setup = true;
  }
});

test('site configuration preserves untouched fields and failed drafts', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  state.configSite = structuredClone(site);
  state.configSite.site_view.local_site.legal_information = 'Previous terms';
  Object.assign(state.configSite.site_view.local_site, { federation_signed_fetch: true, nsfw_content_disallowed: false, oauth_registration: true });
  state.configSite.discussion_languages = [0, 1];
  state.configSite.site_view.local_site_rate_limit = Object.fromEntries(
    ['message', 'post', 'register', 'image', 'comment', 'search', 'import_user_settings'].flatMap(category => [[`${category}_max_requests`, 10], [`${category}_interval_seconds`, 60]])
  );
  await mockApi(page, state, { authenticated: true });
  await open(page, '/admin/configuration');
  const axe = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa']).analyze();
  expect(axe.violations).toEqual([]);
  await page.getByLabel('Site name').fill('Changed site');
  await page.getByLabel('Summary').fill('New summary');
  await page.getByLabel('Legal information').fill('');
  await page.getByLabel('Discussion language IDs (comma separated)').fill('2147483648');
  await expect(page.getByLabel('Discussion language IDs (comma separated)')).toHaveAttribute('aria-invalid', 'true');
  await expect(page.getByRole('button', { name: 'Save changes' })).toBeDisabled();
  await page.getByLabel('Discussion language IDs (comma separated)').fill('0, 2');
  await page.getByLabel('Private site').check();
  await page.getByLabel('Registration mode').selectOption('closed');
  await page.getByLabel('Enable federation').uncheck();
  await page.getByLabel('Content warning').fill('Warning');
  await page.locator('#rate_limit_post_interval_seconds').fill('0');
  await expect(page.getByRole('button', { name: 'Save changes' })).toBeDisabled();
  await expect(page.locator('#rate_limit_post_interval_seconds')).toHaveAttribute('aria-invalid', 'true');
  await expect(page.locator('#rate_limit_post_interval_seconds')).toHaveAttribute('aria-describedby', 'site-configuration-error');
  await expect(page.locator('#site-configuration-error')).toBeVisible();
  await page.locator('#rate_limit_post_interval_seconds').fill('90');
  await expect(page.locator('#rate_limit_post_interval_seconds')).not.toHaveAttribute('aria-invalid');
  state.failSiteConfig = true;
  state.siteConfigDelay = 250;
  await page.getByRole('button', { name: 'Save changes' }).click();
  await expect(page.locator('main [role="status"]')).toBeVisible();
  await expect(page.getByRole('alert')).toBeVisible();
  state.siteConfigDelay = 0;
  await expect(page.getByLabel('Site name')).toHaveValue('Changed site');
  state.failSiteConfig = false;
  await page.getByRole('button', { name: 'Save changes' }).click();
  await expect.poll(() => state.calls.filter(call => call.path === '/api/v4/site' && call.method === 'PUT').length).toBe(2);
  const payload = state.calls.filter(call => call.path === '/api/v4/site' && call.method === 'PUT').at(-1).body;
  expect(payload).toEqual({ content_warning: 'Warning', discussion_languages: [0, 2], federation_enabled: false, legal_information: '', name: 'Changed site', private_instance: true, rate_limit_post_interval_seconds: 90, registration_mode: 'closed', summary: 'New summary' });
  await expect(page.getByRole('button', { name: 'Save changes' })).toBeDisabled();
  await expect(page.getByLabel('Site name')).toHaveValue('Changed site');
  await page.locator('#site-icon-file').setInputFiles({ name: 'icon.png', mimeType: 'image/png', buffer: Buffer.from('image') });
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/site/icon' && call.method === 'POST')).toBeTruthy();
  await expect(page.locator('#site-remove-icon')).toBeEnabled();
  await page.locator('#site-remove-icon').focus();
  await page.keyboard.press('Enter');
  await expect(page.getByRole('dialog')).toBeVisible();
  await expect(page.getByRole('dialog').getByRole('heading')).toHaveText('Remove site icon');
  await expect(page.getByRole('dialog')).toContainText('This removes the image from the site.');
  await page.keyboard.press('Escape');
  await expect(page.locator('#site-remove-icon')).toBeFocused();
  expect(state.calls.some(call => call.path === '/api/v4/site/icon' && call.method === 'DELETE')).toBe(false);
  await page.locator('#site-remove-icon').click();
  await page.getByRole('dialog').getByRole('button', { name: 'Confirm' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/site/icon' && call.method === 'DELETE')).toBeTruthy();
  await expect(page.locator('#site-remove-icon')).toBeDisabled();
  await page.locator('#site-banner-file').setInputFiles({ name: 'banner.png', mimeType: 'image/png', buffer: Buffer.from('image') });
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/site/banner' && call.method === 'POST')).toBeTruthy();
  await expect(page.locator('#site-remove-banner')).toBeEnabled();
  await page.locator('#site-remove-banner').click();
  await expect(page.getByRole('dialog').getByRole('heading')).toHaveText('Remove site banner');
  await expect(page.getByRole('dialog')).toContainText('This removes the image from the site.');
  await page.getByRole('dialog').getByRole('button', { name: 'Confirm' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/site/banner' && call.method === 'DELETE')).toBeTruthy();
  await expect(page.locator('#site-remove-banner')).toBeDisabled();
});

test('site configuration does not expose controls to non-admins', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  state.identity = { ...myUser, local_user_view: { ...myUser.local_user_view, local_user: { ...myUser.local_user_view.local_user, admin: false } } };
  await mockApi(page, state, { authenticated: true });
  await open(page, '/admin/configuration');
  await expect(page.getByRole('alert')).toBeVisible();
  await expect(page.getByLabel('Site name')).toHaveCount(0);
  expect(state.calls.some(call => call.path === '/api/v4/site' && call.method === 'PUT')).toBe(false);
});

test('creates, edits, and confirms deletion of site taglines', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  state.taglines = [{ id: 10, content: 'Existing tagline', published_at: '2026-11-13T08:00:00Z' }];
  await mockApi(page, state, { authenticated: true });
  await open(page, '/admin/taglines');
  await expect(page.getByRole('heading', { name: 'Taglines' })).toBeVisible();
  await page.locator('#new-tagline').fill('New tagline');
  state.failTagline = true;
  await page.getByRole('button', { name: 'Create' }).click();
  await expect(page.getByRole('alert')).toBeVisible();
  await expect(page.locator('#new-tagline')).toHaveValue('New tagline');
  state.failTagline = false;
  await page.getByRole('button', { name: 'Create' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/admin/tagline' && call.method === 'POST' && call.body.content === 'New tagline')).toBeTruthy();
  await expect(page.locator('#tagline-11')).toHaveValue('New tagline');
  await page.locator('#tagline-10').fill('Edited tagline');
  await page.locator('#tagline-10').locator('..').getByRole('button', { name: 'Save changes' }).click();
  await expect.poll(() => state.calls.some(call => call.method === 'PUT' && call.path === '/api/v4/admin/tagline' && call.body.id === 10 && call.body.content === 'Edited tagline')).toBeTruthy();
  await page.locator('#tagline-delete-10').click();
  await expect(page.getByRole('dialog')).toContainText('Edited tagline');
  await page.getByRole('dialog').getByRole('button', { name: 'Cancel' }).click();
  await expect(page.locator('#tagline-delete-10')).toBeFocused();
  expect(state.calls.some(call => call.method === 'DELETE' && call.path === '/api/v4/admin/tagline')).toBe(false);
  await page.locator('#tagline-delete-10').click();
  await page.getByRole('dialog').getByRole('button', { name: 'Confirm' }).click();
  await expect.poll(() => state.calls.some(call => call.method === 'DELETE' && call.path === '/api/v4/admin/tagline' && call.body.id === 10)).toBeTruthy();
  await expect(page.locator('#tagline-10')).toHaveCount(0);
});

test('manages custom emoji and preserves failed input', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  state.customEmojis = [];
  await mockApi(page, state, { authenticated: true });
  await open(page, '/admin/emoji');
  await page.getByLabel('Shortcode').fill('hello');
  await page.getByLabel('Image URL').fill('https://forum.test/image.png');
  await page.getByLabel('Alternative text').fill('Hello');
  await page.getByLabel('Category').fill('greetings');
  await page.getByLabel('Keywords, separated by commas').fill('hi, wave');
  state.failEmoji = true;
  await page.getByRole('button', { name: 'Create' }).click();
  await expect(page.getByRole('alert')).toBeVisible();
  await expect(page.getByLabel('Shortcode')).toHaveValue('hello');
  state.failEmoji = false;
  await page.getByRole('button', { name: 'Create' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/custom_emoji' && call.method === 'POST' && call.body.image_url === 'https://forum.test/image.png' && call.body.keywords.join(',') === 'hi,wave')).toBeTruthy();
  await page.getByRole('button', { name: 'Edit emoji' }).click();
  await expect(page.getByLabel('Keywords, separated by commas')).toHaveValue('hi, wave');
  await page.getByLabel('Alternative text').fill('Greeting');
  await page.getByRole('button', { name: 'Save changes' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/custom_emoji' && call.method === 'PUT' && call.body.id === 12 && call.body.alt_text === 'Greeting')).toBeTruthy();
  await page.locator('#emoji-delete-12').click();
  await expect(page.getByRole('dialog')).toContainText(':hello:');
  await page.getByRole('dialog').getByRole('button', { name: 'Confirm' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/custom_emoji' && call.method === 'DELETE' && call.body.id === 12)).toBeTruthy();
  await expect(page.getByText('No content', { exact: true })).toBeVisible();
});

test('manages OAuth providers without exposing or replacing an unchanged secret', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  state.providers = [];
  await mockApi(page, state, { authenticated: true });
  await open(page, '/admin/oauth');
  const fields = {
    'Provider name': 'Example provider',
    'Issuer URL': 'https://identity.example',
    'Authorization endpoint': 'https://identity.example/authorize',
    'Token endpoint': 'https://identity.example/token',
    'User info endpoint': 'https://identity.example/userinfo',
    'User ID claim': 'sub',
    'Client ID': 'client-id',
    'Client secret': 'secret-value',
    'Scopes': 'openid email'
  };
  for (const [name, value] of Object.entries(fields)) await page.getByLabel(name, { exact: true }).fill(value);
  state.failProvider = true;
  await page.getByRole('button', { name: 'Create' }).click();
  await expect(page.getByRole('alert')).toBeVisible();
  await expect(page.getByLabel('Provider name')).toHaveValue('Example provider');
  state.failProvider = false;
  await page.getByRole('button', { name: 'Create' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/oauth_provider' && call.method === 'POST' && call.body.client_secret === 'secret-value')).toBeTruthy();
  await page.getByRole('button', { name: 'Edit provider' }).click();
  await expect(page.getByLabel('Client secret')).toHaveValue('');
  await expect(page.getByLabel('Client ID')).toBeDisabled();
  await page.getByLabel('Provider name').fill('Edited provider');
  await page.getByRole('button', { name: 'Save changes' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/oauth_provider' && call.method === 'PUT' && call.body.id === 15 && call.body.display_name === 'Edited provider' && !('client_secret' in call.body) && !('client_id' in call.body) && !('issuer' in call.body))).toBeTruthy();
  await page.locator('#provider-delete-15').click();
  await expect(page.getByRole('dialog')).toContainText('Edited provider');
  await page.getByRole('dialog').getByRole('button', { name: 'Cancel' }).click();
  await expect(page.locator('#provider-delete-15')).toBeFocused();
  await page.locator('#provider-delete-15').click();
  await page.getByRole('dialog').getByRole('button', { name: 'Confirm' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/oauth_provider' && call.method === 'DELETE' && call.body.id === 15)).toBeTruthy();
});

test('does not expose OAuth provider management to non-admins', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  state.identity = { ...myUser, local_user_view: { ...myUser.local_user_view, local_user: { ...myUser.local_user_view.local_user, admin: false } } };
  await mockApi(page, state, { authenticated: true });
  await open(page, '/admin/oauth');
  await expect(page.getByRole('alert')).toBeVisible();
  await expect(page.getByLabel('Client secret')).toHaveCount(0);
  expect(state.calls.some(call => call.path === '/api/v4/oauth_provider')).toBe(false);
});

test('validates and consumes an OAuth callback before exchanging the code', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  state.oauthEstablishSession = true;
  await mockApi(page, state);
  await open(page, '/login');
  const origin = new URL(page.url()).origin;
  await page.evaluate(originValue => sessionStorage.setItem('lemmyms.oauth.pending', JSON.stringify({
    state: 'test-state', providerId: 15, redirectUri: `${originValue}/oauth/callback`,
    verifier: 'v'.repeat(64), username: 'newuser', answer: 'Application', expiresAt: Date.now() + 60000
  })), origin);
  await page.goto('/oauth/callback?code=auth-code&state=test-state');
  await expect(page.getByRole('heading', { name: 'Complete OAuth sign-in' })).toBeVisible();
  await expect(page).toHaveURL(/\/oauth\/callback$/);
  await page.getByLabel('Two-factor authentication code (if enabled)').fill('123456');
  await page.getByRole('button', { name: 'Continue' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/oauth/authenticate' && call.body.code === 'auth-code' && call.body.oauth_provider_id === 15 && call.body.redirect_uri === `${origin}/oauth/callback` && call.body.pkce_code_verifier === 'v'.repeat(64) && call.body.username === 'newuser' && call.body.answer === 'Application' && call.body.totp_2fa_token === '123456')).toBeTruthy();
  await expect(page).toHaveURL(/\/$/);
  await page.goto('/oauth/callback?code=auth-code&state=test-state');
  await expect(page.getByRole('alert')).toContainText('invalid or expired');
  expect(state.calls.filter(call => call.path === '/api/v4/oauth/authenticate')).toHaveLength(1);
});

test('starts OAuth with a fresh provider-bound state and PKCE challenge', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  state.publicProviders = [{ id: 15, display_name: 'Identity provider', authorization_endpoint: 'https://id.example/authorize', client_id: 'client', scopes: 'openid email', use_pkce: true }];
  await mockApi(page, state);
  await page.route('https://id.example/**', route => route.fulfill({ status: 200, body: 'identity provider' }));
  await open(page, '/login');
  const origin = new URL(page.url()).origin;
  await page.getByLabel('Username for a new account (optional for existing accounts)').fill('newuser');
  await page.getByLabel('Registration application answer, if required').fill('Application');
  const request = page.waitForRequest(req => req.url().startsWith('https://id.example/authorize'));
  await page.getByRole('button', { name: 'Identity provider' }).click();
  const authorization = new URL((await request).url());
  expect(authorization.searchParams.get('client_id')).toBe('client');
  expect(authorization.searchParams.get('redirect_uri')).toBe(`${origin}/oauth/callback`);
  expect(authorization.searchParams.get('code_challenge_method')).toBe('S256');
  expect(authorization.searchParams.get('code_challenge')).toBeTruthy();
  expect(authorization.searchParams.get('state')).toBeTruthy();
  await page.goto(`${origin}/login`);
  const pending = await page.evaluate(() => JSON.parse(sessionStorage.getItem('lemmyms.oauth.pending')));
  expect(pending.providerId).toBe(15);
  expect(pending.username).toBe('newuser');
  expect(pending.answer).toBe('Application');
  expect(pending.state).toBe(authorization.searchParams.get('state'));
});

test('reports OAuth registration and verification outcomes', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state);
  await open(page, '/login');
  const origin = new URL(page.url()).origin;
  for (const [result, message] of [
    [{ registration_created: true, verify_email_sent: false }, 'Your registration application was submitted.'],
    [{ registration_created: false, verify_email_sent: true }, 'Check your email to complete registration.']
  ]) {
    state.oauthResult = result;
    await page.evaluate(originValue => sessionStorage.setItem('lemmyms.oauth.pending', JSON.stringify({
      state: 'valid', providerId: 15, redirectUri: `${originValue}/oauth/callback`, verifier: null,
      username: 'newuser', answer: 'answer', expiresAt: Date.now() + 60000
    })), origin);
    await page.goto('/oauth/callback?code=auth-code&state=valid');
    await page.getByRole('button', { name: 'Continue' }).click();
    await expect(page.getByText(message)).toBeVisible();
  }
});

test('explains missing OAuth registration details and preserves the application answer', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  state.publicProviders = [{ id: 15, display_name: 'Identity provider', authorization_endpoint: 'https://id.example/authorize', client_id: 'client', scopes: 'openid email', use_pkce: true }];
  state.oauthFail = 'registration_username_required';
  await mockApi(page, state);
  await open(page, '/login');
  const origin = new URL(page.url()).origin;
  await page.evaluate(originValue => sessionStorage.setItem('lemmyms.oauth.pending', JSON.stringify({
    state: 'valid', providerId: 15, redirectUri: `${originValue}/oauth/callback`, verifier: null,
    username: '', answer: 'My application', expiresAt: Date.now() + 60000
  })), origin);
  await page.goto('/oauth/callback?code=auth-code&state=valid');
  await page.getByRole('button', { name: 'Continue' }).click();
  await expect(page.getByRole('alert')).toContainText('A username is required');
  await page.getByRole('link', { name: 'Log in' }).last().click();
  await expect(page.getByLabel('Registration application answer, if required')).toHaveValue('My application');
});

test('rejects OAuth state mismatches and does not claim a session without a cookie', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state);
  await open(page, '/login');
  const origin = new URL(page.url()).origin;
  const seed = async () => page.evaluate(originValue => sessionStorage.setItem('lemmyms.oauth.pending', JSON.stringify({
    state: 'right', providerId: 15, redirectUri: `${originValue}/oauth/callback`, verifier: null,
    username: '', answer: '', expiresAt: Date.now() + 60000
  })), origin);
  await seed();
  await page.goto('/oauth/callback?code=auth-code&state=wrong');
  await expect(page.getByRole('alert')).toContainText('invalid or expired');
  expect(state.calls.some(call => call.path === '/api/v4/oauth/authenticate')).toBe(false);
  await seed();
  await page.goto('/oauth/callback?code=auth-code&state=right');
  await page.getByRole('button', { name: 'Continue' }).click();
  await expect(page.getByRole('alert')).toContainText('server did not establish a session');
});

test('filters site users and confirms administrator role changes', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  state.siteUsers = [{ ...myUser.local_user_view, person: replyPerson, local_user: { ...myUser.local_user_view.local_user, id: 2, person_id: 2, admin: false } }];
  await mockApi(page, state, { authenticated: true });
  await open(page, '/admin/users?sort=old&banned_only=true');
  await expect(page.getByText('bob@forum.test')).toBeVisible();
  await page.getByRole('link', { name: 'Next page' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/admin/users' && call.search.includes('banned_only=true') && call.search.includes('sort=old') && call.search.includes('page_cursor=next-user'))).toBeTruthy();
  await page.getByRole('button', { name: 'Grant administrator' }).click();
  await expect(page.getByRole('dialog')).toContainText('bob@forum.test');
  await page.getByRole('dialog').getByRole('button', { name: 'Cancel' }).click();
  await expect(page.locator('#site-admin-2')).toBeFocused();
  state.failAdminChange = true;
  await page.getByRole('button', { name: 'Grant administrator' }).click();
  await page.getByRole('dialog').getByRole('button', { name: 'Confirm' }).click();
  await expect(page.getByRole('alert')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Grant administrator' })).toBeVisible();
  state.failAdminChange = false;
  await page.getByRole('button', { name: 'Grant administrator' }).click();
  await page.getByRole('dialog').getByRole('button', { name: 'Confirm' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/admin/add' && call.body.person_id === 2 && call.body.added === true)).toBeTruthy();
  await expect(page.getByRole('button', { name: 'Remove administrator' })).toBeVisible();
  await page.getByRole('button', { name: 'Remove administrator' }).click();
  await page.getByRole('dialog').getByRole('button', { name: 'Confirm' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/admin/add' && call.body.person_id === 2 && call.body.added === false)).toBeTruthy();
  await expect(page.getByRole('button', { name: 'Grant administrator' })).toBeVisible();
  state.identity = { ...myUser, local_user_view: { ...myUser.local_user_view, local_user: { ...myUser.local_user_view.local_user, admin: false } } };
  await page.reload();
  await expect(page.getByRole('alert')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Grant administrator' })).toHaveCount(0);
});

test('lists current site media with paging and reports access failures', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  state.siteMedia = [{ local_image: { pictrs_alias: 'photo.png', published_at: '2026-11-13T08:00:00Z' }, person: replyPerson }];
  await mockApi(page, state, { authenticated: true });
  await open(page, '/admin/media');
  await expect(page.getByRole('heading', { name: 'Site media' })).toBeVisible();
  await expect(page.getByText('Uploaded by bob@forum.test')).toBeVisible();
  await expect(page.getByRole('link', { name: 'photo.png' })).toHaveAttribute('href', '/api/v4/image/photo.png');
  await page.getByRole('link', { name: 'Next page' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/image/list' && call.search.includes('page_cursor=next-media'))).toBeTruthy();
  state.failMedia = true;
  await page.reload();
  await expect(page.getByRole('alert')).toBeVisible();
});

test('updates site federation policies independently of personal blocks', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  state.federationRecords = [{ instance: { domain: 'remote.example' }, allowed: null, blocked: null }];
  await mockApi(page, state, { authenticated: true });
  await open(page, '/admin/federation');
  await expect(page.getByText('remote.example · Linked')).toBeVisible();
  await expect(page.getByText('These rules apply to this site and are separate from personal blocks.')).toBeVisible();
  await page.getByLabel('Domain').fill('remote.example');
  await page.getByLabel('Reason').fill('Trusted');
  state.failFederation = true;
  await page.getByRole('button', { name: 'Save changes' }).click();
  await expect(page.getByRole('alert')).toBeVisible();
  await expect(page.getByLabel('Domain')).toHaveValue('remote.example');
  state.failFederation = false;
  await page.getByRole('button', { name: 'Save changes' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/admin/instance/allow' && call.body.instance === 'remote.example' && call.body.allow === true && call.body.reason === 'Trusted')).toBeTruthy();
  await expect(page.getByText('remote.example · Allowed')).toBeVisible();
  await page.getByLabel('Domain').fill('remote.example');
  await page.getByLabel('Reason').fill('Policy change');
  await page.getByLabel('Policy action').selectOption('unallow');
  await page.getByRole('button', { name: 'Save changes' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/admin/instance/allow' && call.body.allow === false)).toBeTruthy();
  await expect(page.getByText('remote.example · Linked')).toBeVisible();
  await page.getByLabel('Domain').fill('remote.example');
  await page.getByLabel('Reason').fill('Abuse');
  await page.getByLabel('Policy action').selectOption('block');
  await page.getByLabel('Block expiry, Unix seconds (optional)').fill('-1');
  await expect(page.getByLabel('Block expiry, Unix seconds (optional)')).toHaveAttribute('aria-describedby', 'federation-expires-error');
  await expect(page.locator('#federation-expires-error')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Save changes' })).toBeDisabled();
  await page.getByLabel('Block expiry, Unix seconds (optional)').fill('2000000000');
  await expect(page.locator('#federation-expires-error')).toHaveCount(0);
  await page.getByRole('button', { name: 'Save changes' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/admin/instance/block' && call.body.block === true && call.body.expires_at === 2000000000)).toBeTruthy();
  await expect(page.getByText('remote.example · Blocked')).toBeVisible();
  await page.getByLabel('Domain').fill('remote.example');
  await page.getByLabel('Reason').fill('Resolved');
  await page.getByLabel('Policy action').selectOption('unblock');
  await page.getByRole('button', { name: 'Save changes' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/admin/instance/block' && call.body.block === false && !('expires_at' in call.body))).toBeTruthy();
  expect(state.calls.some(call => call.path.includes('/account/block'))).toBe(false);
});

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
  await page.getByRole('button', { name: 'Save changes' }).click();
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

test('loads site vote settings and preserves untouched vote modes', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  site.site_view.local_site.default_post_upvotes = 'local';
  site.site_view.local_site.default_post_downvotes = 'all';
  try {
    await open(page, '/admin/settings');
    const upvotes = page.getByLabel('Upvotes enabled');
    const downvotes = page.getByLabel('Downvotes enabled');
    await expect(upvotes).toBeChecked();
    await expect(downvotes).toBeChecked();
    await downvotes.uncheck();
    await page.getByRole('button', { name: 'Save changes' }).click();
    await expect.poll(() => state.calls.some(call => call.path === '/api/v4/site' && call.method === 'PUT' && call.body.default_post_downvotes === 'disable' && !('default_post_upvotes' in call.body))).toBeTruthy();
    await expect(downvotes).not.toBeChecked();
    await expect(upvotes).toBeChecked();
  } finally {
    site.site_view.local_site.default_post_upvotes = 'all';
    site.site_view.local_site.default_post_downvotes = 'all';
  }
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
  const userCard = page.locator('#main-content article').filter({ hasText: 'https://forum.test/u/alice' });
  await expect(userCard.getByRole('link')).toHaveAttribute('href', '/u/alice');
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

test('saves complete account settings and applies the theme', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await page.goto('/settings');
  await page.getByLabel('Display name').fill('Alice P2');
  await page.getByLabel('Theme').selectOption('dark');
  await page.getByLabel('Listing').selectOption('subscribed');
  await page.getByLabel('Items per page').fill('30');
  await page.getByRole('button', { name: 'Save changes' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/account/settings/save' && call.body.display_name === 'Alice P2' && call.body.theme === 'dark' && call.body.default_listing_type === 'subscribed' && call.body.default_items_per_page === 30)).toBeTruthy();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
});

test('preserves unsaved settings and sends cleared optional fields', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  state.failSettings = true;
  await mockApi(page, state, { authenticated: true });
  await page.goto('/settings');
  await page.getByLabel('Display name').fill('Unsaved name');
  await page.getByRole('button', { name: 'Save changes' }).click();
  await expect(page.getByRole('alert').filter({ hasText: 'Check your input and try again.' })).toBeVisible();
  await expect(page.getByLabel('Display name')).toHaveValue('Unsaved name');
  state.failSettings = false;
  await page.getByLabel('Display name').fill('');
  await page.getByRole('button', { name: 'Save changes' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/account/settings/save' && call.body.display_name === null)).toBeTruthy();
});

test('uploads account images, enables TOTP, and shows login history', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await page.goto('/settings');
  await page.locator('#account-avatar').setInputFiles({ name: 'avatar.png', mimeType: 'image/png', buffer: Buffer.from('avatar') });
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/account/avatar')).toBeTruthy();
  await page.locator('#account-banner').setInputFiles({ name: 'banner.png', mimeType: 'image/png', buffer: Buffer.from('banner') });
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/account/banner')).toBeTruthy();
  await page.getByRole('button', { name: 'Set up two-factor authentication' }).click();
  await expect(page.getByText('otpauth://totp/Forum:alice?secret=ABC123')).toBeVisible();
  await page.getByLabel('Authentication code').fill('123456');
  await page.getByRole('button', { name: 'Enable two-factor authentication' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/account/auth/totp/edit' && call.body.enabled === true && call.body.totp_token === '123456')).toBeTruthy();
  await expect(page.getByText('127.0.0.1')).toBeVisible();
  await expect(page.getByText('Playwright')).toBeVisible();
});

test('exports, imports, invites, and cancels account deletion', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await page.goto('/settings');
  const downloadPromise = page.waitForEvent('download');
  await page.getByRole('button', { name: 'Export settings' }).click();
  const download = await downloadPromise;
  expect(download.suggestedFilename()).toBe('lemmy-settings.json');
  await page.locator('#settings-import').setInputFiles({ name: 'broken.json', mimeType: 'application/json', buffer: Buffer.from('{broken') });
  await expect(page.getByRole('alert').filter({ hasText: 'Check your input and try again.' })).toBeVisible();
  await page.locator('#settings-import').setInputFiles({ name: 'settings.json', mimeType: 'application/json', buffer: Buffer.from('{"display_name":"Imported"}') });
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/account/settings/import' && call.body.display_name === 'Imported')).toBeTruthy();
  await expect(page.getByText('invite-token')).toBeVisible();
  await page.getByLabel('Maximum uses').fill('2');
  await page.getByLabel('Expires at').fill('2027-01-01T00:00:00Z');
  await page.getByRole('button', { name: 'Create invitation' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/account/invite' && call.method === 'POST' && call.body.max_uses === 2)).toBeTruthy();
  await page.getByRole('button', { name: 'Revoke' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/account/invite' && call.method === 'DELETE' && call.body.token === 'invite-token')).toBeTruthy();
  await page.getByRole('button', { name: 'Delete account' }).click();
  await expect(page.locator('#delete-account-dialog')).toBeVisible();
  await page.getByRole('button', { name: 'Cancel' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/account' && call.method === 'DELETE')).toBeFalsy();
  await page.getByRole('button', { name: 'Delete account' }).click();
  await page.locator('#delete-account-dialog').getByLabel('Current password').fill('secret-password');
  await page.locator('#delete-account-dialog').getByLabel('Also delete my posts and comments').check();
  await page.locator('#delete-account-dialog').getByRole('button', { name: 'Delete account' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/account' && call.method === 'DELETE' && call.body.password === 'secret-password' && call.body.delete_content === true)).toBeTruthy();
  await expect(page).toHaveURL(/\/login$/);
});

test('handles registration applications, captcha, and the donation prompt', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state);
  site.site_view.local_site.registration_mode = 'require_application';
  site.site_view.local_site.application_question = 'Why do you want to join?';
  site.captcha_enabled = true;
  await page.goto('/signup');
  await expect(page.getByText('Why do you want to join?')).toBeVisible();
  await page.getByLabel('Username').fill('newuser');
  await page.getByLabel('Email').fill('new@example.test');
  await page.getByLabel('Password', { exact: true }).fill('long-enough-password');
  await page.getByLabel('New password').fill('long-enough-password');
  await page.getByLabel('Why do you want to join?').fill('Because');
  await page.getByLabel('Captcha answer').fill('1234');
  await page.getByRole('button', { name: 'Create account' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/account/auth/register' && call.body.answer === 'Because' && call.body.captcha_uuid === 'captcha-uuid')).toBeTruthy();
  site.site_view.local_site.registration_mode = 'open';
  site.site_view.local_site.application_question = null;
  site.captcha_enabled = false;
});

test('shows and dismisses the donation prompt once', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await page.goto('/');
  await expect(page.getByText('This instance relies on donations to keep running. You can support it from the site page.')).toBeVisible();
  await page.getByRole('button', { name: 'Dismiss' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/account/donation_dialog_shown')).toBeTruthy();
  await expect(page.getByText('This instance relies on donations to keep running. You can support it from the site page.')).toHaveCount(0);
});

test('handles closed and invitation registration modes', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state);
  site.site_view.local_site.registration_mode = 'closed';
  await page.goto('/signup');
  await expect(page.getByText('Registration is closed on this site.')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Create account' })).toHaveCount(0);
  site.site_view.local_site.registration_mode = 'require_invitation';
  await page.goto('/signup');
  await expect(page.getByText('Registration requires an invitation.')).toBeVisible();
  site.site_view.local_site.registration_mode = 'open';
});

test('opens own profile from the drawer identity header', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await page.goto('/');
  await expect(page.locator('#top-bar-profile')).toHaveCount(0);
  await expect(page.locator('.top-bar-profile')).toHaveCount(0);
  const drawer = page.locator('#navigation-drawer');
  const profileHeader = drawer.locator('.drawer-profile');
  await expect(profileHeader).toHaveAttribute('href', '/u/alice');
  await expect(profileHeader).toHaveAccessibleName(/Profile Alice @alice/);
  await expect(profileHeader).toContainText('Alice');
  await expect(profileHeader).toContainText('@alice');
  await expect(profileHeader).toContainText('Site administrator');
  await expect(drawer.locator('nav').getByRole('link', { name: 'Profile', exact: true })).toHaveCount(0);
  const labels = await drawer.locator('nav > .drawer-item').evaluateAll(nodes =>
    nodes.map(node => node.querySelector('.drawer-label')?.textContent?.trim() ?? '')
  );
  expect(labels).toEqual([
    'Latest discussions',
    'Communities',
    'Federated instances',
    'Legal information',
    'Search',
    'Notifications',
    'Manage site',
    'Pending follow requests',
    'My content',
    'Blocks',
    'Profile settings',
    'Log out'
  ]);
  await profileHeader.focus();
  await expect(profileHeader).toBeFocused();
  await page.keyboard.press('Enter');
  await expect(page).toHaveURL(/\/u\/alice$/);
  await expect(page.getByRole('tab', { name: 'Saved' })).toBeVisible();
  await page.goto('/u/alice@forum.test');
  await expect(page.getByRole('tab', { name: 'Saved' })).toBeVisible();
  expect(state.calls.some(call => call.path === '/api/v4/person' && call.search.includes('alice%40forum.test'))).toBeTruthy();
});

test('closes the modal drawer after opening the profile from its header', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  await page.setViewportSize({ width: 360, height: 800 });
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await page.goto('/');
  await page.locator('#menu-button').click();
  const drawer = page.locator('dialog#navigation-drawer');
  await expect(drawer).toBeVisible();
  await expect(drawer.locator('.drawer-profile')).toHaveAccessibleName(/Profile Alice @alice/);
  await expect.poll(() => page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBeTruthy();
  await drawer.locator('.drawer-profile').click();
  await expect(page).toHaveURL(/\/u\/alice$/);
  await expect(page.locator('dialog#navigation-drawer')).toHaveCount(0);
});

test('uses local and remote profile handles in author links', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state);
  await page.goto('/');
  await expect(page.getByRole('link', { name: 'Alice (alice@forum.test)' })).toHaveAttribute('href', '/u/alice');
  state.postCreator = remotePerson;
  await page.goto('/');
  await expect(page.getByRole('link', { name: 'Carol (carol@remote.test)' })).toHaveAttribute('href', '/u/carol@remote.test');
  await page.goto('/u/carol@remote.test');
  await expect(page.getByText('This content is unavailable.')).toBeVisible();
  expect(state.calls.some(call => call.path === '/api/v4/person' && call.search.includes('carol'))).toBeTruthy();
});

test('normalizes a local ban actor URL to the single username', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await page.goto('/admin/bans');
  await page.getByLabel('Actor URI').fill('http://forum.test/u/admin');
  await page.getByLabel('Ban reason').fill('test');
  await page.getByRole('button', { name: 'Create ban' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/person' && call.search === '?username=admin')).toBeTruthy();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/admin/ban')).toBeTruthy();
});

test('keeps the hostname in a remote ban actor URL', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await page.goto('/admin/bans');
  await page.getByLabel('Actor URI').fill('https://remote.test/u/carol');
  await page.getByLabel('Ban reason').fill('test');
  await page.getByRole('button', { name: 'Create ban' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/person' && call.search === '?username=carol%40remote.test')).toBeTruthy();
});

test('reads and acts on private messages', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await page.goto('/notifications?kind=messages');
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/account/notification/list' && call.search.includes('type_=private_message'))).toBeTruthy();
  await expect(page.getByRole('link', { name: 'Bob', exact: true })).toBeVisible();
  await expect(page.getByText('Hello there')).toBeVisible();
  await expect(page.getByRole('link', { name: 'Reply' })).toHaveAttribute('href', '/create_private_message/2');
  await page.getByRole('button', { name: 'Mark read' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/account/notification/mark_as_read')).toBeTruthy();
  await page.getByRole('button', { name: 'Report message' }).click();
  await page.getByLabel('Reason').fill('spam');
  await page.getByRole('button', { name: 'Submit report' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/private_message/report' && call.body.private_message_id === 30 && call.body.reason === 'spam')).toBeTruthy();
  await page.getByRole('button', { name: 'Delete message' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/private_message' && call.method === 'DELETE')).toBeTruthy();
  await expect(page.getByText('Message deleted.')).toBeVisible();
});

test('edits a private message owned by the reader', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  state.privateMessage.creator = person;
  state.privateMessage.private_message.creator_id = 1;
  state.privateMessage.private_message.recipient_id = 2;
  state.privateMessage.private_message.content = 'Editable message';
  await mockApi(page, state, { authenticated: true });
  await page.goto('/notifications?kind=messages');
  await expect(page.getByText('Editable message')).toBeVisible();
  await page.getByRole('button', { name: 'Edit message' }).click();
  await page.getByLabel('Message').fill('Edited message');
  await page.getByRole('button', { name: 'Save message' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/private_message' && call.method === 'PUT' && call.body.private_message_id === 30 && call.body.content === 'Edited message')).toBeTruthy();
  await expect(page.getByText('Edited message')).toBeVisible();
});

test('composes a private message and preserves a failed draft', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await page.goto('/create_private_message/2');
  await expect(page.getByText('Bob')).toBeVisible();
  await page.getByLabel('Message').fill('Hello Bob');
  await page.getByRole('button', { name: 'Send message' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/private_message' && call.method === 'POST' && call.body.recipient_id === 2 && call.body.content === 'Hello Bob')).toBeTruthy();
  await page.waitForURL(url => url.pathname === '/u/bob');
  state.failPrivateMessage = true;
  await page.goto('/create_private_message/2');
  await page.getByLabel('Message').fill('Keep this draft');
  await page.getByRole('button', { name: 'Send message' }).click();
  await expect(page.getByRole('alert').filter({ hasText: 'Check your input and try again.' })).toBeVisible();
  await expect(page.getByLabel('Message')).toHaveValue('Keep this draft');
});

test('offers message entry from another profile', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await page.goto('/u/bob');
  await expect(page.getByRole('link', { name: 'Send message' })).toHaveAttribute('href', '/create_private_message/2');
  await page.goto('/u/alice');
  await expect(page.getByRole('link', { name: 'Send message' })).toHaveCount(0);
  myUser.local_user_view.local_user.private_messages_enabled = false;
  await page.goto('/u/bob');
  await expect(page.getByRole('link', { name: 'Send message' })).toHaveCount(0);
  myUser.local_user_view.local_user.private_messages_enabled = true;
});

test('browses multi-communities and follows one', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await page.goto('/multi_communities');
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/multi_community/list' && call.search.includes('type_=local') && call.search.includes('sort=subscribers'))).toBeTruthy();
  await expect(page.getByRole('link', { name: 'Tech', exact: true })).toHaveAttribute('href', '/m/tech');
  await page.getByLabel('Listing').selectOption('all');
  await page.waitForURL(url => url.pathname === '/multi_communities' && url.searchParams.get('type') === 'all');
  await page.getByLabel('Search communities').fill('tech');
  await page.getByRole('button', { name: 'Search' }).click();
  await expect(page).toHaveURL(/q=tech/);
  await page.goto('/m/tech');
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/multi_community' && call.search.includes('name=tech'))).toBeTruthy();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/post/list' && call.search.includes('multi_community_name=tech'))).toBeTruthy();
  await expect(page.getByText('Tech sidebar')).toBeVisible();
  await expect(page.getByRole('link', { name: 'News', exact: true }).first()).toBeVisible();
  await page.getByRole('button', { name: 'Unfollow' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/multi_community/follow' && call.body.follow === false)).toBeTruthy();
});

test('creates and manages a multi-community', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  await page.goto('/create_multi_community');
  await page.getByLabel('Name', { exact: true }).fill('newmulti');
  await page.getByLabel('Title', { exact: true }).fill('New multi');
  await page.getByLabel('Summary').fill('Summary');
  await page.getByLabel('Sidebar (Markdown)').fill('Sidebar');
  await page.getByRole('button', { name: 'Create', exact: true }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/multi_community' && call.method === 'POST' && call.body.name === 'newmulti')).toBeTruthy();
  await page.waitForURL(url => url.pathname === '/m/newmulti');
  state.multiCommunity.multi.name = 'tech';
  state.multiCommunity.multi.title = 'Tech';
  await page.goto('/m/tech/settings');
  await page.getByLabel('Title', { exact: true }).fill('Updated Tech');
  await page.getByRole('button', { name: 'Save changes' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/multi_community' && call.method === 'PUT' && call.body.title === 'Updated Tech')).toBeTruthy();
  await page.waitForURL(url => url.pathname === '/m/tech');
  await page.goto('/m/tech/settings');
  await page.getByLabel('Search communities').fill('news');
  await page.getByRole('button', { name: 'Search' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/community/list' && call.search.includes('search_term=news'))).toBeTruthy();
  await page.getByRole('button', { name: 'Add community' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/multi_community/entry' && call.method === 'POST' && call.body.community_id === 1)).toBeTruthy();
  state.entryLimit = true;
  await page.getByRole('button', { name: 'Add community' }).click();
  await expect(page.getByText('This multi-community already has the maximum of 50 communities.')).toBeVisible();
  await page.getByRole('button', { name: 'Remove community' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/multi_community/entry' && call.method === 'DELETE')).toBeTruthy();
  await page.getByRole('button', { name: 'Delete multi-community' }).click();
  await page.getByRole('button', { name: 'Confirm' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/multi_community' && call.method === 'PUT' && call.body.deleted === true)).toBeTruthy();
  await page.waitForURL(url => url.pathname === '/multi_communities');
});

test('hides multi-community management from an ordinary reader', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  myUser.local_user_view.local_user.admin = false;
  state.multiCommunity.multi.creator_id = 2;
  await mockApi(page, state, { authenticated: true });
  await page.goto('/m/tech/settings');
  await expect(page.getByText('This action is not allowed, or your access has changed.')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Save changes' })).toHaveCount(0);
  myUser.local_user_view.local_user.admin = true;
  state.multiCommunity.multi.creator_id = 1;
});

test('resolves a private message report in the admin workspace', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  state.privateReport = true;
  await mockApi(page, state, { authenticated: true });
  await page.goto('/reports');
  await expect(page.getByText('Bob: Hello **there**')).toBeVisible();
  await page.getByLabel('Resolution note').fill('handled');
  await page.getByRole('button', { name: 'Resolve', exact: true }).click();
  await page.getByRole('button', { name: 'Confirm' }).click();
  await expect.poll(() => state.calls.some(call => call.path === '/api/v4/private_message/report/resolve' && call.body.report_id === 9 && call.body.resolved === true && call.body.conclusion === 'handled')).toBeTruthy();
});

test('has no automated accessibility violations on the latest page', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  for (const path of ['/', '/multi_communities', '/m/tech', '/m/tech/settings']) {
    await page.goto(path);
    const axe = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa']).analyze();
    expect(axe.violations).toEqual([]);
  }
});

test('P4 administration and federation pages have no automated accessibility violations', async ({ page }) => {
  await page.addInitScript(() => localStorage.setItem('commune.locale', 'en-US'));
  const state = fixtures();
  await mockApi(page, state, { authenticated: true });
  for (const [path, title] of [
    ['/instances', 'Federated instances'],
    ['/legal', 'Legal information'],
    ['/admin/users', 'Site users'],
    ['/admin/media', 'Site media'],
    ['/admin/federation', 'Federation policy'],
    ['/admin/oauth', 'OAuth providers'],
    ['/admin/taglines', 'Taglines'],
    ['/admin/emoji', 'Custom emoji'],
    ['/registration_applications', 'Registration applications'],
    ['/pending_follows', 'Pending follow requests']
  ]) {
    await page.goto(path);
    await expect(page.getByRole('heading', { level: 1, name: title })).toBeVisible();
    await expect(page.locator('main .loading-state')).toHaveCount(0);
    await expect(page.locator('main [role="alert"]')).toHaveCount(0);
    const axe = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa']).analyze();
    expect(axe.violations, path).toEqual([]);
  }
});
