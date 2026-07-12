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

### 4. Detect actual Cloudflare challenge responses

An application API can legitimately return JSON with status 403 while still
being served through Cloudflare. Treating every Cloudflare-server 403 as a
challenge opens the resolver unnecessarily and can freeze reader requests.
Use Cloudflare's `cf-mitigated: challenge` response header instead.

### 5. Support the optional WebView timeout argument

Extensions may call `evaluateJavascriptViaWebview` with the documented three
required arguments. Read the fourth timeout argument only when it is present,
otherwise use 30 seconds. This avoids a `RangeError` before the WebView starts.

### 6. Inject extraction scripts at document start

Reader pages can start image API requests before `onLoadStop`. Register the
same extension scripts as `AT_DOCUMENT_START` user scripts so fetch
interceptors are active before page scripts, while retaining `onLoadStop` as a
compatibility fallback.

### 7. Share concurrent identical WebView evaluations

The reader can request the same page list concurrently. Windows WebView2 does
not reliably create multiple headless WebViews on the shared environment.
Share one active evaluation by URL and script payload; request-specific cookie
headers are intentionally excluded from the key because either valid request
can bootstrap the same page extraction.

## Validation evidence

- Focused client tests: `flutter test test/services test/eval`
- Windows release build: `flutter build windows --release`
- Live `toki30.com` list requests changed from Cloudflare 403 to 200 after the
  cookie/user-agent and resolver fixes.
- Windows Debug UI validation opened uncached NTK Webtoon episodes directly:
  episode 7 returned 98 images and episode 6 returned 103 images.
- NTK Webtoon list requests changed from the retired `/webtoon` list route to
  the current `/ing` route in the extension repository; that extension change
  is separate from these client PR candidates.

## Suggested PR split

1. Cloudflare cookie and user-agent pairing with focused unit tests.
2. Bundled resolver retry semantics with focused unit tests.
3. WebView bridge payload return type with a regression test covering string
   payloads in both bridges.
4. Cloudflare challenge classification and optional WebView timeout handling.
5. Early WebView script injection and concurrent evaluation sharing.
