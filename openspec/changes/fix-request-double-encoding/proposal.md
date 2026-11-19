# Proposal

## Why

Dynamic profile, community, and multi-community route segments are passed through Elm's route parser without decoding their percent escapes. When those encoded names are later percent-encoded for API query parameters, the backend receives percent escape text instead of the original Unicode name.

## What Changes

- Decode percent-encoded dynamic route segments once when parsing profile, community, and multi-community routes.
- Encode those dynamic segments when building navigation URLs so route values round-trip safely.
- Add regression coverage for Unicode names and literal percent escapes, including profile handles used by person API queries.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `lemmy-api-integration`: Specify that person lookup handles selected from a route arrive at the API in their original decoded form after one query-encoding pass.

## Impact

- `Lemmy.Route` path parsing and URL generation for profiles, communities, and multi-communities.
- Profile person and content lookup requests, which encode decoded route handles once for the query string.
