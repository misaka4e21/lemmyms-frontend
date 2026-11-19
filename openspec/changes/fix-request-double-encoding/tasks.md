# Tasks

## 1. Trace request encoding

- [x] 1.1 Reproduce the problematic request from the captured `%25E5...` URL and trace it through route parsing and the HTTP transport; verify the route parser preserves `%E5...` and the API caller encodes it again
- [x] 1.2 Inventory manual percent encoding and `Url.Builder.toQuery` usage in API query construction; verify the inventory covers both `Api.elm` and `Lemmy/Api.elm`

## 2. Fix dynamic route encoding

- [x] 2.1 Decode percent-encoded profile, community, and multi-community route segments once; verify route values are decoded application strings
- [x] 2.2 Encode dynamic route names when generating navigation paths and retain the existing person query encoding; verify paths round-trip and person requests contain the original handle
- [x] 2.3 Add regression coverage for Unicode route names and literal percent escapes; verify they parse once, route generation preserves their original value, and the person query receives one encoding pass

## 3. Verify integration

- [x] 3.1 Run the route and Elm checks and verify the Unicode profile handle produces the expected person query value without a second encoding pass
