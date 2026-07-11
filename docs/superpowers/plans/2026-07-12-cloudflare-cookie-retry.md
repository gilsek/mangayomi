# Cloudflare Cookie Retry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Windows Mangayomi reuse Cloudflare clearance cookies with the matching WebView user agent and retry after a successful challenge solve.

**Architecture:** Add small pure helpers beside `MClient` so cookie/user-agent and resolver-result semantics are directly testable. Wire those helpers into the existing interceptor and local WebView resolver without changing unrelated request behavior.

**Tech Stack:** Flutter, Dart, `http_interceptor`, `flutter_inappwebview`, Flutter test.

## Global Constraints

- Validate on the Windows client before any other platform.
- Do not access or install anything on the Android tablet.
- Do not add dependencies.
- Keep Cloudflare changes in dedicated commits and do not open a PR.

---

### Task 1: Clearance User-Agent Pairing

**Files:**
- Modify: `lib/services/http/m_client.dart`
- Test: `test/services/http/m_client_cloudflare_test.dart`

**Interfaces:**
- Produces: `String? userAgentForStoredCookie(String cookie, String storedUserAgent, String? requestUserAgent)`
- Consumes: stored cookie header, stored WebView user agent, and source request user agent.

- [ ] Write a failing test proving `cf_clearance` selects the stored WebView user agent while ordinary cookies preserve the request user agent.
- [ ] Run `flutter test test/services/http/m_client_cloudflare_test.dart` and verify the missing helper causes the expected failure.
- [ ] Implement the pure helper and use it in `MCookieManager.interceptRequest`.
- [ ] Run the focused test and verify it passes.
- [ ] Commit as `fix: pair Cloudflare cookies with WebView user agent`.

### Task 2: Resolver Retry Semantics

**Files:**
- Modify: `lib/services/http/m_client.dart`
- Test: `test/services/http/m_client_cloudflare_test.dart`

**Interfaces:**
- Produces: `bool cloudflareSolveResult({required bool timedOut, required bool challengeRemaining})`
- Consumes: resolver timeout state and final challenge state.

- [ ] Write a failing test proving a cleared challenge returns `true` and timeout or remaining challenge returns `false`.
- [ ] Run the focused test and verify the missing helper causes the expected failure.
- [ ] Implement the helper and use it for the `/resolve_cf` response.
- [ ] Run the focused test and verify it passes.
- [ ] Commit as `fix: retry requests after Cloudflare solve`.

### Task 3: Windows Runtime Verification

**Files:**
- Modify only if runtime evidence exposes another root cause.

**Interfaces:**
- Consumes: the two fixes from Tasks 1 and 2.
- Produces: a Windows release build and recorded live verification evidence.

- [ ] Run the complete `flutter test` suite and require zero failures.
- [ ] Run `flutter build windows --release` and require exit code 0.
- [ ] Launch the patched Windows client against the existing database.
- [ ] Open NTK Webtoon, complete the WebView challenge if needed, then refresh.
- [ ] Verify the source list renders instead of `Failed to bypass Cloudflare`.
- [ ] Compare the final commits with GitHub issues `#611`, `#709`, and PR `#766`; record why this fix is separate.
