## 1. Contracts and navigation

- [x] 1.1 Audit backend DTOs, handlers, permissions, pagination, and tenant checks for every P4 endpoint; record any unsupported operation and verify against Rust source.
- [x] 1.2 Add canonical route parsing, generation, and navigation for P4 entries; verify direct load and browser history with route tests.
- [x] 1.3 Add v4 decoders and requests for site settings and setup; verify optional fields, errors, and payloads with fixtures.
- [x] 1.4 Add v4 decoders and requests for administration collections, applications, and pending follows; verify cursor and authorization cases with fixtures.
- [x] 1.5 Add federation, resolver, and OAuth v4 transport; verify request parameters and response variants with fixtures.

## 2. Setup and site configuration

- [x] 2.1 Implement setup authority and site-state handling; verify configured, anonymous, non-admin, and unconfigured-admin cases in browser tests.
- [x] 2.2 Implement the setup form and failure recovery; verify submission and draft preservation with an isolated fixture.
- [ ] 2.3 Add site identity, description, legal, media, and language settings; verify changes and untouched field preservation with mocked responses.
- [x] 2.4 Add supported registration, federation, content policy, and rate-limit settings; verify validation, denied responses, and current-site refresh.
- [x] 2.5 Preserve existing admin votes, reports, modlog, and bans; verify existing regression tests remain passing.

## 3. Administrative collections

- [ ] 3.1 Implement registration application listing, filtering, approval, and rejection; verify pagination, decision reason, conflict, and non-admin access.
- [x] 3.2 Implement tagline list and supported create, edit, and delete actions; verify request bodies and failure recovery.
- [x] 3.3 Implement custom emoji list and supported create, edit, and delete actions; verify image and optional field handling with fixtures.
- [x] 3.4 Implement OAuth provider management; verify secret omission, create, edit, deletion confirmation, and denied responses.
- [x] 3.5 Implement user inventory and authorized administrator assignment; verify filtering, pagination, and permission failures.
- [ ] 3.6 Implement media inventory and supported actions; verify pagination, access control, and error states.
- [ ] 3.7 Add supported person, community, post, and comment purge actions; verify target-specific confirmation and cancellation in isolated fixtures.
- [x] 3.8 Add federation allow and block administration; verify its policy is distinguished from personal blocks and refreshes on success.

## 4. Federation and review entry points

- [x] 4.1 Add `/instances` with supported federation filters and pagination; verify populated, empty, and failed states.
- [x] 4.2 Add `/legal` using current-site legal text; verify Markdown rendering and absent-text state.
- [x] 4.3 Add `/activitypub/externalInteraction` URI resolution and object routing; verify valid, invalid, inaccessible, and unsupported results.
- [x] 4.4 Add `/pending_follows` for moderators and admins; verify moderator scope, admin all-community filter, paging, approve, reject, and stale requests.

## 5. OAuth authentication

- [x] 5.1 Add provider selection and authorization initiation with random, expiring, provider-bound state; verify redirect URI and state creation.
- [ ] 5.2 Implement `/oauth/callback` validation and exchange; verify mismatch, expiry, replay, denial, and successful session restoration.
- [x] 5.3 Support backend-required OAuth registration details and application answers; verify prompts, failure recovery, and callback data removal.

## 6. Accessibility and acceptance

- [ ] 6.1 Add localized messages and accessible labels, status feedback, and keyboard confirmations; verify locale generation and keyboard browser tests.
- [x] 6.2 Run Elm and JavaScript tests, compilation, and browser regression tests; record commands and results in the change.
- [ ] 6.3 Exercise reversible current-site workflows against the running backend and verify tenant isolation; use isolated fixtures for setup and destructive actions and record any environment limitations.
- [x] 6.4 Validate the change with `openspec validate complete-site-administration-and-federation --strict` and check repository whitespace with `git diff --check`.
