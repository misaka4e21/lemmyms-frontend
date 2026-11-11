# Deployment

Serve frontend assets and the Lemmy v4 API under the same HTTPS authority. The session cookie is HttpOnly, SameSite=Lax, host-scoped, and Secure on HTTPS; splitting the browser origin from the API breaks those guarantees.

The sample `deploy/nginx.conf` routes `/api/`, federation paths, `.well-known`, media paths, and health checks to the backend. The frontend generates `/c/:name`, `/post/:post_id/:comment_id?`, and `/u/:username` for its detail pages. The backend `/communities/:id` ActivityPub Group resource remains a federation path and is not a frontend route. Content negotiation sends `application/activity+json` and `application/ld+json` requests upstream while HTML requests receive the SPA. Deep frontend routes use the SPA document. `/assets/i18n/` uses `try_files $uri =404`, so a missing hashed catalog cannot return HTML that a client might mistake for translation data.

## Release layout

Use immutable release directories with a `current` symlink, for example:

```text
/srv/commune/frontend/releases/2026-10-21T12-00-00Z/
/srv/commune/frontend/releases/2026-10-21T12-00-00Z/assets/i18n/
/srv/commune/frontend/current -> releases/2026-10-21T12-00-00Z
```

Build with an explicit Elm cache:

```sh
ELM_HOME=/tmp/commune-elm-home npm ci
ELM_HOME=/tmp/commune-elm-home npm run build
npm run i18n:check
```

Deploy the generated `dist/` directory. The generated Elm accessors and catalog hashes belong to one build and must be released together. Before switching `current`, stage it with prior hashed catalogs when older open clients remain supported:

```sh
npm run release:stage -- dist /srv/commune/frontend/releases/2026-10-21T12-00-00Z /srv/commune/frontend/releases/2026-10-21T11-00-00Z
```

The staging command copies the build and retains JSON catalogs from the previous release unless the new build already contains the same hash. Keep those files for at least the configured asset/browser cache window. Catalog JSON is public interface text; it contains no credentials or user data.

Use long-lived immutable caching for hashed assets. Do not cache `index.html` as immutable. Apply security headers compatible with authorized private media and verify the backend's Origin handling and cookie scope in staging.

## Rollback

Point `current` back to the preceding complete release and restore the frontend version that matches that release. Keep catalog hashes from both releases present so clients that loaded either application version can finish switching languages. No backend schema or database migration is required for this localization pipeline.

If availability is being drained intentionally, retain the hashed assets through the cache window before deleting an old release. Never reset hashes to simulate a version change and never let the SPA fallback answer a missing `/assets/i18n/*.json` request.
