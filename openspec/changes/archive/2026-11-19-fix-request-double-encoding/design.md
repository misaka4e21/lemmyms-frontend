# Design

## Context

See proposal.md for the motivation. `Url.Parser.string` returns a path segment as it appears in `Url.path`; it does not percent-decode it. The current route parser therefore passes `%E5...` into the profile page for a Unicode username. `Feature.Profile.loadPublic` then calls `Url.percentEncode`, producing `%25E5...` in the API request. `elm/http` passes the assembled URL directly to `XMLHttpRequest.open`, so the extra encoding originates at the route boundary rather than in the HTTP transport.

## Goals / Non-Goals

**Goals:**

- Decode dynamic profile, community, and multi-community path segments exactly once at route parsing.
- Percent-encode those values when generating route paths so navigation round-trips decoded names.
- Preserve API query encoding so a decoded person handle is encoded once when used as a query value.

**Non-Goals:**

- Change API endpoints, parameter names, or backend query parsing.
- Normalize query values or alter unrelated search, cursor, or request-body behavior.

## Decisions

1. **Decode selected dynamic path segments in the route parser.** Add a path parser that applies `Url.percentDecode` once and rejects malformed escapes. Use it for profile, community, and multi-community names because each is subsequently used as decoded application data and may be sent in an API query. Leave unrelated path segments unchanged.

2. **Encode dynamic names when building those routes.** `Url.Builder` joins path segments without percent-encoding them. Apply `Url.percentEncode` to route names before passing them to `Builder.absolute`; the route parser then restores the original value once. This handles Unicode and literal percent text without changing route semantics.

3. **Keep API query encoding at the API call site.** Profile API calls already percent-encode the username. With a decoded route value, this produces the expected single encoded query value. Do not add a global decode to the HTTP wrapper, which would risk reinterpreting legitimate percent text in unrelated queries.

## Risks / Trade-offs

- [Malformed percent escapes in a dynamic path will no longer be treated as an ordinary route name] → Reject malformed encoded names as an invalid route rather than passing ambiguous text to API requests.
- [Encoding existing dynamic routes can alter their visible URL representation] → Keep the same route shape and verify decoded route equality after URL generation and parsing.

## Migration Plan

The frontend change is self-contained and requires no backend rollout. If a navigation regression appears, revert the route parser and path generation changes together; the API endpoints and backend-visible username format remain unchanged.
