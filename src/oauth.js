const OAUTH_STATE_KEY = 'lemmyms.oauth.pending';
const OAUTH_TTL_MS = 5 * 60 * 1000;

function base64url(bytes) {
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll('+', '-').replaceAll('/', '_').replace(/=+$/, '');
}

function randomToken(crypto, size) {
  return base64url(crypto.getRandomValues(new Uint8Array(size)));
}

export async function beginOAuth(provider, details, { storage, crypto, origin, now = Date.now() }) {
  if (!Number.isSafeInteger(provider.id) || provider.id <= 0 || !crypto?.subtle) throw new Error('invalid_provider');
  const authorization = new URL(provider.authorizationEndpoint);
  if (!['https:', 'http:'].includes(authorization.protocol)) throw new Error('invalid_provider');
  const state = randomToken(crypto, 32);
  const redirectUri = `${origin}/oauth/callback`;
  const verifier = provider.usePkce ? randomToken(crypto, 48) : null;
  authorization.searchParams.set('client_id', provider.clientId);
  authorization.searchParams.set('response_type', 'code');
  authorization.searchParams.set('scope', provider.scopes);
  authorization.searchParams.set('redirect_uri', redirectUri);
  authorization.searchParams.set('state', state);
  if (verifier) {
    const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(verifier));
    authorization.searchParams.set('code_challenge', base64url(new Uint8Array(digest)));
    authorization.searchParams.set('code_challenge_method', 'S256');
  }
  storage.setItem(OAUTH_STATE_KEY, JSON.stringify({
    state, providerId: provider.id, redirectUri, verifier,
    username: details.username.trim(), answer: details.answer.trim(),
    expiresAt: now + OAUTH_TTL_MS,
  }));
  return authorization.href;
}

export function consumeOAuthCallback(url, { storage, origin, now = Date.now() }) {
  let pending;
  try {
    const raw = storage.getItem(OAUTH_STATE_KEY);
    storage.removeItem(OAUTH_STATE_KEY);
    pending = JSON.parse(raw || 'null');
  } catch {
    return null;
  }
  const callback = new URL(url);
  const state = callback.searchParams.get('state');
  const code = callback.searchParams.get('code');
  if (callback.origin !== origin || callback.pathname !== '/oauth/callback' || callback.searchParams.has('error') ||
      !state || !code || code.length > 300 || !pending || pending.state !== state ||
      !Number.isSafeInteger(pending.providerId) || pending.providerId <= 0 ||
      pending.redirectUri !== `${origin}/oauth/callback` ||
      !Number.isFinite(pending.expiresAt) || pending.expiresAt < now || pending.expiresAt > now + OAUTH_TTL_MS ||
      (pending.verifier !== null && typeof pending.verifier !== 'string') ||
      typeof pending.username !== 'string' || typeof pending.answer !== 'string') return null;
  return { providerId: pending.providerId, code, redirectUri: pending.redirectUri,
    verifier: pending.verifier, username: pending.username, answer: pending.answer };
}
