# Cloudflare Cookie Retry Design

## Goal

Restore sources protected by a Cloudflare managed challenge by keeping the
clearance cookie and HTTP user agent consistent, then retrying the blocked
request after the WebView resolver succeeds.

## Findings

- `toki30.com` resolves normally and its TLS endpoint is reachable.
- Direct HTTP requests receive `403` with `Cf-Mitigated: challenge`.
- The Windows source WebView renders the site and Mangayomi persists a
  `cf_clearance` cookie for the host.
- NTK supplies a fixed Chrome user agent, while the clearance cookie is issued
  to the WebView2 user agent. `MCookieManager` currently preserves the source's
  mismatched user agent.
- The built-in resolver reports its remaining `isCloudFlare` state as the retry
  result. A successful solve changes that state to `false`, preventing retry.

## Design

Keep the fix in the HTTP client so every JavaScript and Mihon source receives
the same behavior. When the stored cookie header contains `cf_clearance`,
`MCookieManager` must pair it with the stored WebView user agent even if the
source supplied another user agent. Other cookies keep the existing source
header behavior.

The resolver response must represent whether the challenge was solved, not
whether the challenge is still present. Return `true` only after the challenge
page has disappeared and the cookie has been persisted. Timeout and unresolved
challenge paths continue returning `false`.

## Validation

Add focused unit tests for clearance user-agent selection and resolver result
semantics. Run the full Flutter test suite, build the Windows release, and test
`toki30.com` in the Windows Mangayomi client. The change is successful only
when the source list renders after a Cloudflare challenge.

## PR Separation

Keep the Cloudflare fix in dedicated commits on
`codex/cloudflare-cookie-retry`. Do not open a pull request now. The commits can
later be cherry-picked onto an upstream-based branch with the GitHub issue and
PR comparison recorded in the implementation plan.
