# Cloudflare and WebView payload PR notes

## Scope

Keep these fixes on `codex/cloudflare-cookie-retry` until each change is
validated independently and prepared as a focused upstream pull request.
Do not open a pull request from this branch as-is.

## Upstream comparison

- Issue #611 reports that the bundled Cloudflare bypass still fails.
- Issue #709 requests an optional external Cloudflare bypass proxy.
- PR #766 implements a FlareSolverr/Byparr-compatible proxy path. It does not
  change the bundled WebView resolver result, bind `cf_clearance` to the
  WebView user agent, or preserve non-boolean WebView script payloads.

## Candidate changes

### 1. Pair `cf_clearance` with the solving WebView user agent

Commit: `c5f73b4`

Cloudflare clearance is tied to the browser fingerprint that solved the
challenge. When a stored cookie includes `cf_clearance`, requests must use the
stored WebView user agent even if an extension supplies its own user agent.
Ordinary source cookies continue to preserve the source user agent.

### 2. Retry after the bundled resolver succeeds

Commit: `9d398ad`

The retry policy expects `/resolve_cf` to return `true` when it should retry.
The prior response exposed the remaining-challenge flag, so successful solves
returned `false`. Return success only when the challenge is gone and the solve
did not time out.

### 3. Preserve WebView script payloads

Commit: `5c27f3b` (cherry-picked from `d4fcbc7`)

`evaluateJavascriptViaWebview` is also used by extensions to return extracted
strings and JSON, not only boolean challenge status. Both JavaScript and Dart
bridges must return the payload without casting it to `bool`.

## Validation evidence

- Focused client tests: `flutter test test/services test/eval`
- Windows release build: `flutter build windows --release`
- Live `toki30.com` list requests changed from Cloudflare 403 to 200 after the
  cookie/user-agent and resolver fixes.
- NTK Webtoon list requests changed from the retired `/webtoon` list route to
  the current `/ing` route in the extension repository; that extension change
  is separate from these client PR candidates.

## Suggested PR split

1. Cloudflare cookie and user-agent pairing with focused unit tests.
2. Bundled resolver retry semantics with focused unit tests.
3. WebView bridge payload return type with a regression test covering string
   payloads in both bridges.

