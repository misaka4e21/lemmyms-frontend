import assert from 'node:assert/strict';
import { webcrypto } from 'node:crypto';
import test from 'node:test';
import { beginOAuth, consumeOAuthCallback } from '../src/oauth.js';

function storage() {
  const data = new Map();
  return { getItem: key => data.get(key) ?? null, setItem: (key, value) => data.set(key, value), removeItem: key => data.delete(key) };
}

const provider = { id: 17, authorizationEndpoint: 'https://id.example/authorize?prompt=login', clientId: 'client', scopes: 'openid email', usePkce: true };

test('binds state and PKCE to the provider and consumes a valid callback once', async () => {
  const store = storage();
  const options = { storage: store, crypto: webcrypto, origin: 'https://forum.example', now: 10000 };
  const url = new URL(await beginOAuth(provider, { username: ' alice ', answer: ' hello ' }, options));
  assert.equal(url.searchParams.get('redirect_uri'), 'https://forum.example/oauth/callback');
  assert.equal(url.searchParams.get('code_challenge_method'), 'S256');
  assert.ok(url.searchParams.get('code_challenge'));
  const callback = `https://forum.example/oauth/callback?state=${url.searchParams.get('state')}&code=abc`;
  const result = consumeOAuthCallback(callback, options);
  assert.equal(result.providerId, 17);
  assert.equal(result.username, 'alice');
  assert.equal(result.answer, 'hello');
  assert.ok(result.verifier.length >= 43);
  assert.equal(consumeOAuthCallback(callback, options), null);
});

test('rejects mismatched, expired, denied and cross-origin callbacks', async () => {
  for (const mode of ['mismatch', 'expired', 'denied', 'origin']) {
    const store = storage();
    const options = { storage: store, crypto: webcrypto, origin: 'https://forum.example', now: 10000 };
    const url = new URL(await beginOAuth(provider, { username: '', answer: '' }, options));
    const state = mode === 'mismatch' ? 'wrong' : url.searchParams.get('state');
    const origin = mode === 'origin' ? 'https://other.example' : options.origin;
    const suffix = mode === 'denied' ? '&error=access_denied' : '';
    const callback = `${origin}/oauth/callback?state=${state}&code=abc${suffix}`;
    assert.equal(consumeOAuthCallback(callback, { ...options, now: mode === 'expired' ? 400001 : 10000 }), null);
    assert.equal(consumeOAuthCallback(callback, options), null);
  }
});
