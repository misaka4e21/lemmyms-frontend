## Context

`Feature.SiteAdmin` already handles current-site votes, reports, modlog, and bans. Community management already handles community-scoped pending follows. LemmyMultisite exposes `/api/v4/site`, administration collections, federation policy, `/resolve_object`, and `/oauth/authenticate`. Site creation requires an authenticated administrator and rejects an already configured site. The UI must retain tenant isolation and the existing same-origin session boundary.

## Goals / Non-Goals

**Goals:**
- Add direct-loadable Lemmy entry points and complete supported current-site administration flows.
- Keep permissions, pagination, optional fields, and errors faithful to the checked-in backend contracts.
- Make destructive and authentication flows testable with isolated fixtures.

**Non-Goals:**
- Installation-wide tenant provisioning or cross-site administration.
- Backend modifications, unsupported fields, or automatic changes to existing site policy.
- Running setup or purge operations against the shared live test site.

## Decisions

### Organize workspaces by authority

Extend the existing admin workspace with grouped settings and collection screens, keeping existing panels. Add separate canonical routes for setup, applications, pending follows, instances, legal, OAuth callback, and external interaction. The registration queue requires site-admin authority; pending follows can be used by moderators and admins, with all-community selection reserved for admins. Reuse community approval actions rather than introducing a second interpretation of their permissions.

### Use v4 DTOs and current-site state

Inspect backend request and response types before implementing each form, including paging and nullable update semantics. Submit only supported fields and distinguish omitted values from explicit clearing. Refresh site or collection state on success and after stale conflicts; retain drafts on errors. The existing v4 API layer avoids an independent administration client and keeps cookies same-origin.

### Model setup and OAuth as state machines

Use `site_setup` and the current session to select setup, sign-in, complete, or denied states. Site creation requires an admin; do not assume ordinary registration creates one. OAuth initiation stores a random, expiring, single-use state bound to the provider and redirect URI, and the callback validates it before exchange. Clear authorization data and callback query from history, and follow the backend's registration and application outcomes. A generic redirect without state validation would permit unsolicited callbacks.

### Resolve remote interaction through the backend

Send the supplied URI to the v4 resolver and route only supported returned object types. Do not fetch arbitrary URIs directly from the browser or derive local identifiers from URI text. Read legal content from the site response and federation lists from the v4 endpoint.

### Confirm destructive changes

Explicit confirmation names the target before purge, provider deletion, and other destructive operations. Backend authorization remains authoritative. Tests use mocked contracts and isolated data; live checks are limited to reversible, authorized workflows.

## Risks / Trade-offs

- [Backend field and permission differences] → Audit the current Rust DTOs and handlers per operation and cover request bodies, omission, and denied responses with fixtures.
- [OAuth secrets and callback reuse] → Never display an assumed existing secret; validate and consume short-lived state, clear callback data, and test replay and mismatch.
- [Tenant leakage or destructive test data] → Use the current host and session, verify tenant-specific responses, and isolate setup and purge acceptance data.
- [Large scope] → Implement and verify by the task groups; keep unsupported backend behavior visibly unavailable rather than simulating it.

## Migration Plan

Deploy the frontend with the existing v4 backend and no schema migration. Existing routes and administration panels remain available. Rollback consists of restoring the prior frontend; server-side changes made by administrators remain in effect.
