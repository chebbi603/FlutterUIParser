Project: demo_json_parser (Flutter)
# Test Results — 2025-11-05
Latest run: see `docs/history/flutter-test-results-run71.md` for details.

## Summary (Run 77 — Unit — 48 tests passed) — Docs alignment
- Command: `flutter test`
- Result: All tests passed
- Total: 48 tests
- Duration: ~5s

- Notable Output (truncated)
```
00:05 +48: All tests passed!
📊 Tracked: tap (component=x, page=null, scope=public, ...)
⚠️ No backendUrl configured; keeping 1 events in memory
```

## Summary (Run 76 — Backend authenticated fallback unaffected)
- Command: `flutter test`
- Result: All tests passed
- Total: 48 tests
- Duration: ~7s

- Context
  - Verified that backend change to include base authenticated pages in partial contracts does not impact Flutter contract parsing or navigation/auth gating.
  - Analytics batching and tagging logs remain stable; ingestion stubs continue to print expected diagnostics in tests.

- Notable Output (truncated)
```
00:07 +48: All tests passed!
📊 Tracked: tap (component=btn1, page=null, scope=public, ...)
⚠️ No backendUrl configured; keeping 1 events in memory
```

## Summary (Run 74 — Dispatch trackEvent via AnalyticsService)
- Command: `flutter test`
- Result: All tests passed
- Total: 48 tests
- Duration: ~4s

- Context
  - Added a dispatcher special-case to route contract `analytics` `trackEvent` actions through `AnalyticsService` batching and perform an immediate `flush()`.
  - Ensures single-click events (e.g., podcast item clicks) are ingested consistently into MongoDB alongside bottom navigation events.
  - Updated `docs/flutter-analytics_backend_configuration.md` with an Action Routing section.

- Notable Output (truncated)
```
00:04 +48: All tests passed!
📊 Tracked: pageEnter (component=null, page=home, scope=public, ...)
📊 Tracked: pageExit (component=null, page=home, scope=public, ...)
```

## Summary (Run 73 — Contract-level analytics normalization)
- Command: `flutter test`
- Result: All tests passed
- Total: 48 tests
- Duration: ~5s

- Context
  - Enforced canonical analytics endpoint paths in `CanonicalContract.fromJson` by normalizing legacy `'/event'`, `'/events'`, and `'/analytics/event(s)'` to `'/events'`.
  - Trimmed trailing `'/analytics'` from analytics service `baseUrl` during service parsing.
  - Updated `docs/flutter-analytics_backend_configuration.md` with Contract-Level Normalization details.

- Notable Output (truncated)
```
00:05 +48: All tests passed!
📊 Tracked: tap (component=x, page=null, scope=public, ...)
⚠️ No backendUrl configured; keeping 1 events in memory
```

## Summary (Run 72 — Analytics URL path normalization)
- Command: `flutter test`
- Result: All tests passed
- Total: 48 tests
- Duration: ~4s

- Context
  - Normalized analytics backend URL paths to canonical `'/events'` in `lib/app.dart`.
  - Coerces common misconfigurations like `'/analytics'` or `'/analytics/events'` to ensure clicks and flushes target the correct ingestion endpoint.
  - Updated `docs/flutter-analytics_backend_configuration.md` and `docs/flutter-whats-new.md` accordingly.

- Notable Output (truncated)
```
00:04 +48: All tests passed!
[diag][pageGrid] page=home columns=3 spacing=12.0 children=3
📊 Tracked: pageEnter (component=null, page=home, scope=public, ...)
```

## Summary (Run 71 — Token-only auth gating fix)
- Command: `flutter test`
- Result: All tests passed
- Total: 48 tests
- Duration: ~6s

- Context
  - Relaxed authentication predicate in `lib/app.dart` to consider a session authenticated when a non-empty `authToken` exists, without requiring `state.user.id`.
  - Fixes post-login redirect when backend returns tokens but omits `user.id`.
  - Updated `docs/flutter-navigation_auth_enforcement.md` to reflect token-based gating.

- Notable Output (truncated)
```
00:06 +48: All tests passed!
📊 Tracked: pageEnter (component=null, page=home, scope=public, ...)
⚠️ No backendUrl configured; keeping 1 events in memory
```

## Summary (Run 64 — EnhancedPageBuilder & Nav refresh validated)
- Command: `flutter test`
- Result: All tests passed
- Total: 45 tests
- Duration: ~6s

- Notable Output (truncated)
```
00:06 +45: All tests passed!
[diag][page] enter id=page1 layout=column components=2 bg=-
📊 Tracked: pageEnter
[diag][component] Create type=textButton id=btn1
📊 Tracked: tap (component=btn1)
📊 Tracked: pageExit (page=page1)
[diag][page] enter id=home layout=column components=0 bg=-
📊 Tracked: pageExit (page=home)
```

## Summary (Run 67 — Auth Username/Name Persisted, Auto-Login Removed)
- Command: `flutter test`
- Result: All tests passed
- Total: 47 tests
- Duration: ~2s

- Context
  - Updated `AuthService.login` to persist `state.user.username` and `state.user.name` from backend response; adds fallbacks so one populates the other when missing.
  - Removed debug-only auto-login in `lib/app.dart` to prevent unintended authentication on startup.

- Notable Output (truncated)
```
00:02 +47: All tests passed!
[diag][page] enter id=home layout=scroll components=3 bg=-
📊 Tracked: pageEnter (component=null, page=home, scope=public, ...)
```

## Summary (Run 68 — Username Greeting Verified, Page Grid Validated)
- Command: `flutter test`
- Result: All tests passed
- Total: 48 tests
- Duration: ~4s

- Context
  - Added widget test to assert "Welcome Back, ${state.user.username}" resolves correctly when `state.user.username` is present.
  - Confirmed page-level grid rendering via `GridView.count` with `columns` and `spacing` from page config.
  - Changes under test include persisting `user.username`/`user.name` in `AuthService` and removal of debug auto-login in `app.dart`.

- Notable Output (truncated)
```
00:04 +48: All tests passed!
[diag][binding] text id=- field="text" value="Welcome Back, ${state.user.username}"
00:04 +1: test/widgets/welcome_back_username_test.dart: Welcome Back shows username when available
[diag][pageGrid] page=home columns=3 spacing=12.0 children=3
```

## Summary (Run 63 — Optional field validation for response properties)
- Command: `flutter test`
- Result: All tests passed
- Total: 45 tests
- Duration: ~3s

- Context
  - Updated `ApiService._validateResponseSchema` to only validate properties present in the response and skip null values in `_validateValueAgainstSchema`.
  - Prevents erroneous failures like `ApiException: Field "_id" must be string` when optional fields are absent.
  - Combined with prior ObjectId coercion, responses are now validated robustly against the contract.

- Notable Output (truncated)
```
00:03 +45: All tests passed!
```

## Summary (Run 62 — Response validation: ObjectId coercion for string fields)
- Command: `flutter test`
- Result: All tests passed
- Total: 45 tests
- Duration: ~3s

- Context
  - Enhanced `ApiService` response validation now accepts common ObjectId-like map shapes for fields typed as `string` by coercing to strings (`$oid`, `oid`, `id`, `value`, `string`, `hex`, `hexString`).
  - Fixes debug auto-login failure `ApiException: Field "_id" must be string` when backend returns Mongo-style `_id` objects.

- Notable Output (truncated)
```
00:03 +45: All tests passed!
```

## Summary (Run 59 — Analytics cast guard for Map types)
- Command: `flutter test`
- Result: All tests passed
- Total: 45 tests
- Duration: ~3s

- Context
  - Replaced fragile `as Map<String, dynamic>?` casts in `AnalyticsService` with guard patterns.
  - Prevents runtime error: `type 'String' is not a subtype of type 'Map<String, dynamic>?' in type cast` when unexpected payloads are encountered.

- Additional Change
  - `_formatEventForBackend` now reads `state.user` defensively (supports Map or String), avoiding generic cast failures.

- Notable Output (truncated)
```
00:03 +45: All tests passed!
```

## Summary (Run 58 — Per-event top-level id alias for backend attribution)
- Command: `flutter test`
- Result: All tests passed
- Total: 45 tests
- Duration: ~3s

## Context
- `AnalyticsService._formatEventForBackend` now includes a top-level `id` when a valid 24-hex user id exists in global state (`state.user.id`).
- Backend honors per-event alias (`id`/`_id`/`userId`) for attribution, preventing fallback to `000000000000000000000000`.
- Client continues to mirror `data.userId` for analytics segmentation.

## Notable Output (truncated)
```
00:03 +45: All tests passed!
```

## Summary (Run 55 — MVP public events ingestion)
- Command: `flutter test`
- Result: All tests passed
- Total: 44 tests
- Duration: ~3s

## Context
- Backend changed: event ingestion endpoints (`POST /events`, `POST /events/tracking-event`) are public in MVP.
- No Flutter code changes required; `AnalyticsService.flush()` continues to include `Authorization` when available, but backend accepts requests without it.
- Navigation-triggered immediate flush behavior remains the same.

## Notable Output (truncated)
```
00:03 +44: All tests passed!
```
## Summary (Run 57 — Nav bar version/refresh + lifecycle flush)
- Command: `flutter test`
- Result: All tests passed
- Total: 45 tests
- Duration: ~3s

## Context
- Added contract version label and refresh button to navigation bar (`enhanced_page_builder.dart`).
- Integrated lifecycle flush hooks in `app.dart` via `WidgetsBindingObserver` including `hidden` state handling.
- Removed client-side contract validation from `ContractService`; now trusts backend.
- Added widget test `test/widgets/navigation_bar_refresh_test.dart` covering version label and refresh action.

## Notable Output (truncated)
```
00:03 +45: All tests passed!
```
## Summary (Run 56 — Public analytics endpoints optional auth header)
- Command: `flutter test`
- Result: All tests passed
- Total: 44 tests
- Duration: ~3s

## Context
- Verified documentation alignment: analytics ingestion endpoints are public; Authorization header is optional.
- No Flutter code changes required; `AnalyticsService.flush()` includes `Authorization` only when a token is present.
- Debug logs continue to show tracked events and baseline behaviors in tests.

## Notable Output (truncated)
```
00:03 +44: All tests passed!
📊 Tracked: tap (component=x, page=null, scope=public, ...)
📊 Tracked: pageEnter / pageExit events in EnhancedPageBuilder
```

## Summary (Run 53 — Bottom navigation analytics tracking)
- Command: `flutter test`
- Result: All tests passed
- Total: 44 tests
- Duration: ~3s

## Context
- Implemented automatic tracking for bottom navigation taps via a one-time `CupertinoTabController` listener in `lib/app.dart`.
- Events use `TrackingEventType.routeChange` (mapped to `navigate`) and include stable `componentId` and `pageId`.
- No visual changes; analytics now records nav selections reliably.

## Notable Output (truncated)
```
00:03 +44: All tests passed!
```

## Summary (Run 52 — Local port normalization)
- Command: `flutter test`
- Result: All tests passed
- Total: 44 tests
- Duration: ~3s

## Context
- Implemented defensive normalization for local development:
  - Map `http://localhost:8082` → `http://localhost:8081` in `main.dart`.
  - Normalize analytics `backendUrl` to ensure `/events` path and port `8081` for localhost.
- Purpose: prevent misconfigured `.env` values from breaking backend connectivity without changing environment files.

## Notable Output (truncated)
```
00:03 +44: All tests passed!
```

## Summary (Run 50 — Routine verification and coverage)
- Command: `flutter test --coverage`
- Result: All tests passed
- Total: 44 tests
- Duration: ~5s

## Context
- Routine regression run to verify analytics-related tests and overall stability.
- Confirmed behavior: when `backendUrl` is not configured, analytics flush defers and keeps events in memory (debug logs present).
- Coverage artifact written to `coverage/lcov.info` for CI aggregation.

## Notable Output (truncated)
```
00:05 +44: All tests passed!
📊 Tracked: tap (component=x, page=null, scope=public, ...)
⚠️ No backendUrl configured; keeping 1 events in memory
📊 Tracked: pageEnter / pageExit events in EnhancedPageBuilder
```

## Summary (Run 65 — Spacing parsing and Row builder verification)
- Command: `flutter test`
- Result: All tests passed
- Total: 46 tests
- Duration: ~3s

- Context
  - Added diagnostics in `component_factory.dart` to log `spacing` and child count for `row` and `grid` builders.
  - Added widget test `test/widgets/row_spacing_test.dart` asserting `SizedBox` separators with the expected width are inserted between `Row` children.
  - Confirms `EnhancedComponentConfig.spacing` is parsed via `ParsingUtils.safeToDouble` and applied by `_applySpacing` in `Row`.

- Notable Output (truncated)
```
[diag][row] spacing=12 children=3
00:03 +46: All tests passed!
```

## Summary (Run 49 — Debug auto-login for analytics auth + baseline flush)
- Command: `flutter test`
- Result: All tests passed
- Total: 44 tests
- Duration: ~3s

## Context
- Implemented debug-only auto-login in `app.dart` using `.env` keys `DEBUG_AUTO_LOGIN`, `DEBUG_EMAIL`, and `DEBUG_PASSWORD` to obtain a JWT at startup in debug builds.
- This, combined with the previously added Authorization header, ensures analytics flushes include JWT in debug sessions.
- Kept the 2-second delayed baseline flush in debug to quickly verify ingestion.

## Notable Output (truncated)
```
00:03 +44: All tests passed!
📊 Tracked: pageEnter (component=null, page=page1, scope=public, ...)
📊 Tracked: tap (component=btn1, page=page1, scope=public, ...)
```

## Summary (Run 48 — Analytics auth header + debug baseline flush)
- Command: `flutter test`
- Result: All tests passed
- Total: 44 tests
- Duration: ~3s

## Context
- Added Authorization header to analytics `flush()` and `flushPublicBaseline()` when `authToken` exists in global state.
- Added a debug-only delayed baseline flush on app startup to send initial public events (e.g., `landing_page_viewed`) for quick verification.
- No UI changes; behavior only affects analytics network calls in debug.

## Notable Output (truncated)
```
00:03 +44: All tests passed!
📊 Tracked: pageEnter (component=null, page=page1, scope=public, ...)
📊 Tracked: tap (component=btn1, page=page1, scope=public, ...)
```

## Summary (Run 25)
- Command: `flutter test`
- Result: All tests passed
- Total: 39 tests
- Duration: ~3s

## Context
- Normalized endpoint alias keys in `EndpointConfig.fromJson`:
  - `authRequired`/`requiresAuth` → `auth`
  - `params` → `queryParams`
  - `retry` → `retryPolicy`
- Added unit tests validating alias handling: `test/models/endpoint_config_aliases_test.dart`.
- No UI changes; parser behavior is more robust and consistent.

## Notable Output (truncated)
```
00:03 +39: All tests passed!
```

## Summary (Run 40 — Button text color precedence)
- Command: `flutter test`
- Result: All tests passed
- Total: 39 tests
- Duration: ~3s

## Context
- Button component updated to prioritize `style.color` for text, then `style.foregroundColor`, with token fallbacks to `${theme.onPrimary}` and `${theme.onSurface}` based on background.
- Documentation updated in `docs/style-tokens-and-overrides.md` under “Button Color Precedence”.

## Notable Output (truncated)
```
00:03 +39: All tests passed!
```

## Summary (Run 27 — Theming token parsing alignment, system→light mapping)
- Command: `flutter test`
- Result: All tests passed
- Total: 39 tests
- Duration: ~2s

## Context
- Color parsing updated to avoid forced blue fallback:
  - `ComponentStyleUtils._parseColor` and `IconComponent` now use `ParsingUtils.parseColorOrNull`.
  - Factory `_parseColor` also switched to `parseColorOrNull` after resolving tokens.
- App theme alignment:
  - When global `theme=system`, use `light` token map by default.
- Documentation updated:
  - `docs/style-tokens-and-overrides.md` clarifies nullable color fallback and system→light mapping.

## Notable Output (truncated)
```
00:03 +39: All tests passed!
```

## Summary (Run 41 — Grid static itemBuilder support)
- Command: `flutter test`
- Result: All tests passed
- Total: 40 tests
- Duration: ~3s

## Context
- Grid component updated to render static data via `dataSource.type: "static"` with `items` and `itemBuilder`.
- Added widget test `test/widgets/grid_static_itembuilder_test.dart` verifying `${item.title}` resolves and renders.

## Notable Output (truncated)
```
00:03 +40: All tests passed!
```

## Summary (Run 45 — Map cast hardening and robustness tests)
- Command: `flutter test`
- Result: All tests passed
- Total: 44 tests
- Duration: ~3s

## Context
- Hardened parsing across the app to avoid `String is not a subtype of Map<String, dynamic>` exceptions.
- Changes include:
  - Guard `ApiService` response schema properties with `is Map<String, dynamic>` checks.
  - Guard `TrackingEvent.fromJson` `data` and `context` fields against non-map values.
  - Guard `EventsActionsConfig.fromJson` `actions` mapping with `is Map` checks.
  - Fixed `AssetsConfig.fromJson` icons mapping syntax and safe extraction.
- Added unit tests:
  - `test/models/pages_ui_config_parsing_test.dart` (non-map `routes`/`pages`).
  - `test/services/tracking_event_parsing_test.dart` (non-map `data`/`context`).
  - `test/models/events_actions_config_parsing_test.dart` (non-map `actions`).

## Notable Output (truncated)
```
00:03 +44: All tests passed!
```

## Summary (Run 46 — UI polish: spacing and duration binding fix)
- Command: `flutter test`
- Result: All tests passed
- Total: 44 tests
- Duration: ~3s

## Context
- Canonical contract updates focused on visual polish and safe bindings:
  - Music page: added page padding, item margins, surface background, rounded corners.
  - Fixed invalid string interpolation for duration by introducing `durationText` in static data (e.g., `3:45`).
  - Podcasts page: added page padding and grid gap for consistent spacing.
  - Audiobooks page: added page padding for consistent insets.
- No parser changes; UI renders cleaner and avoids text overflow.

## Notable Output (truncated)
```
00:03 +44: All tests passed!
```

## Summary (Run 47 — Songs Row Overflow Fix)
- Command: `flutter test`
- Result: All tests passed
- Total: 44 tests
- Duration: ~3s

## Context
- Canonical contract updated to prevent row overflow in Songs list:
  - `title` and `subtitle` set `maxLines: 1` and `overflow: "ellipsis"`.
  - `durationText` set `maxLines: 1`.
  - Play `icon` size reduced from `32` → `24`.
- Backend verified to serve updated contract (`/contracts/public/canonical`).
- Parser unchanged; UI renders cleaner with stable truncation.

## Notable Output (truncated)
```
00:03 +44: All tests passed!
```

## Summary (Run 17)
- Command: `flutter test`
- Result: Some tests failed
- Total: 31 tests
- Duration: ~3s

## Context
- Implemented token-aware page background parsing in `enhanced_page_builder.dart` using factory resolver and `ParsingUtils.parseColor`.
- Disabled pagination footer for static lists by honoring `dataSource.pagination.enabled` in `EnhancedListWidget`.
- These changes target UI rendering only; provider/service logic is untouched.

## Notable Output (truncated)
```

## Summary (Run 19)
- Command: `flutter test`
- Result: All tests passed
- Total: 33 tests
- Duration: ~2s

## Context
- Implemented service name aliasing in `CanonicalContract.fromJson` to expose lowercase aliases for keys ending with `Service` or `Api` without overriding explicit mappings.
- Added unit tests validating alias creation (`AuthService` -> `auth`) and non-override behavior.

## Notable Output (truncated)
```
00:02 +33: All tests passed!
```
00:03 +30 -1: Some tests failed.
Failing: /test/providers/contract_provider_test.dart: ContractProvider refreshContract routes to personalized when auth state present
```

## Summary (Run 18)
- Command: `flutter test -r expanded`
- Result: Some tests failed
- Total: 31 tests
- Duration: ~1–2s

## Notable Output (truncated)
```
00:01 +29 -1: /test/providers/contract_provider_test.dart: ContractProvider refreshContract routes to personalized when auth state present
⚠️ No backendUrl configured; keeping 1 events in memory
00:01 +30 -1: Some tests failed.
```

## Summary (Run 15)
- Command: `flutter test`
- Result: All tests passed
- Total: 31 tests
- Duration: ~3s

## Notable Output (truncated)
```
00:03 +31: All tests passed!
```

## Summary (Run 2)
- Command: `flutter test`
- Result: All tests passed
- Total: 17 tests
- Duration: ~2s

## Notable Output (truncated)
```

## Summary (Run 14)
- Command: `flutter test -r expanded`
- Result: All tests passed
- Total: 31 tests
- Duration: ~1s

## Context
- Added unit tests for `ContractService` and `ContractProvider`, covering canonical/user contract flows, fallbacks, debouncing, idempotency, and auth error handling.
- `ContractService` tests validate primary vs fallback endpoints, wrapped JSON payloads, malformed JSON errors, and `401/404` semantics.
- `ContractProvider` tests validate canonical load, personalized load, `AuthenticationException` handling, `refreshContract` debounce/idempotency, and `canRefresh` guards.

## Notable Output (truncated)
```
00:01 +31: All tests passed!
```

## Summary (Run 16)
- Command: `flutter test -r expanded`
- Result: Some tests failed
- Total: 31 tests
- Duration: ~1–3s

## Context
- Introduced UI Diagnostic Scanner and debug-only logging in `component_factory.dart` and `enhanced_page_builder.dart`.
- Invoked the scanner in `app.dart` after contract application (debug-only).
- These changes do not affect release behavior; diagnostics are printed only in debug mode.

## Notable Output (truncated)
```
📊 Tracked: input (component=field1, page=null, scope=public, tag=rapid_repeat, contractType=unknown, version=unknown, personalized=false, user=null)
00:01 +30 -1: Some tests failed.
Failing: /test/providers/contract_provider_test.dart: ContractProvider refreshContract routes to personalized when auth state present
```

## Notes
- The failing test appears unrelated to the diagnostic scanner changes and concerns routing behavior under authenticated refresh.
- Follow-up action: investigate `ContractProvider.refreshContract` routing logic and auth-linked switching when backend responses are mocked.

## Summary (Run 8)
- Command: `flutter test`
- Result: All tests passed
- Total: 17 tests
- Duration: ~1s

## Context
- ContractService now exposes two methods: `fetchCanonicalContract` and `fetchUserContract`, both returning `ContractResult`.
- Canonical fetch wraps payload with `source=canonical`; user fetch adds JWT header, throws on `401`, and falls back to canonical on `404`.
- `ContractProvider` updated to store `result.contract` when loading canonical; boot flow in `main.dart` adjusted accordingly.
- Static analysis clean for modified files; project-level infos/warnings unchanged.

## Notable Output (truncated)
```
00:01 +17: All tests passed!
```

## Summary (Run 9)
- Command: `flutter test`
- Result: All tests passed
- Total: 17 tests
- Duration: ~1s

## Context
- ContractProvider refactored to store `ContractResult` with auth fields (`_authUserId`, `_jwtToken`).
- New getters added: `contract` (raw map), `contractResult`, `contractSource`, `isPersonalized`, `contractVersion`.
- Added `loadCanonicalContract()` and updated app bootstrap to call it; refresh now delegates to canonical load.
- Analyzer shows only minor infos/warnings; no errors.

## Notable Output (truncated)
```
00:01 +17: All tests passed!
```

## Summary (Run 10)
- Command: `flutter test`
- Result: All tests passed
- Total: 17 tests
- Duration: ~1s

## Context
- Added `loadUserContract(userId, jwtToken)` with input validation and robust error handling.
- Implemented `refreshContract()` that routes to canonical or user fetch based on auth state and debounces rapid attempts.
- Updated `canRefresh` to require non-localhost absolute backend URL and to disable when loading or on error.
- Analyzer shows no errors; only pre-existing minor infos/warnings remain.

## Notable Output (truncated)
```
00:01 +17: All tests passed!
```

## Summary (Run 4)
- Command: `flutter test`
- Result: All tests passed
- Total: 17 tests
- Duration: ~1s

## Context
- Analytics backend URL extracted from contract on startup with env var resolution in `main.dart`.
- Debug-only "Send Test Analytics" button added under refresh banner in `app.dart`.
- Configuration logs when backend URL is missing and does not crash (analytics disabled scenario).

## Notable Output (truncated)
```
00:01 +17: All tests passed!
⚠️ No backendUrl configured; keeping 1 events in memory
```
00:02 +17: All tests passed!
```

## Summary (Run 12)
- Command: `flutter test -r json`
- Result: All tests passed
- Total: 17 tests
- Duration: ~2s

## Context
- AuthService now calls `ContractProvider.loadUserContract(userId, jwtToken)` right after successful login to switch to a personalized contract.
- On logout, AuthService invokes `ContractProvider.loadCanonicalContract()` before clearing auth state to revert UI to the public contract.
- `MyApp` wires `ContractProvider` into `AuthService` during post-contract initialization to enable these flows.
- Optional navigation to the login screen is attempted via `NavigationBridge.switchTo('/login')` if configured.

## Notable Output (truncated)
```
00:01 +17: All tests passed!
```

## Summary (Run 6)
- Command: `flutter test`
- Result: All tests passed
- Total: 17 tests
- Duration: ~2s

## Context
- ContractService updated to remove local asset fallback; backend-only sourcing enforced.
- Error handling now logs failures and throws to callers; no `rootBundle` references remain.
- New `OfflineScreen` widget added (`lib/screens/offline_screen.dart`) to present an offline state with Retry.
- Static analysis: 6 remaining issues unrelated to these changes (pre-existing); modified files are clean.

## Notable Output (truncated)
```
00:02 +17: All tests passed!
```

## Summary (Run 27 — UI polish: icons, colors, lists, images)
- Command: `flutter test -r compact`
- Result: All tests passed
- Total: 39 tests
- Duration: ~3s

## Context
- Extended `ParsingUtils.parseIcon` to support `music`, `podcast(s)`, and `audiobook(s)` icon names used by bottom navigation.
- Introduced `ParsingUtils.parseColorOrNull` and updated `ButtonComponent` to use it for `backgroundColor` and `foregroundColor`, avoiding unintended blue text fallback and allowing Cupertino defaults.
- Added default horizontal padding to non-virtual `EnhancedListWidget` lists (`16px`) while honoring explicit `style.padding` when provided.
- Implemented empty `src` guard and `errorBuilder` fallback in `NetworkOrAssetImage` to prevent asset-not-found errors and render a neutral placeholder.

## Notable Output (truncated)
```
00:03 +39: All tests passed!
```
 
## Summary (Run 7)
- Command: `flutter test`
- Result: All tests passed
- Total: 17 tests
- Duration: ~1–2s

## Context
- Added `lib/models/contract_result.dart` containing `ContractResult` and `ContractSource`.
- Model provides factory `fromBackendResponse`, helpers (`isCanonical`, `isPersonalized`), `copyWith`, and JSON serialization.
- Static analysis reports no warnings in the new file; project-level warnings unchanged.

## Notable Output (truncated)
```
00:01 +17: All tests passed!
```
## Summary (Run 5)
- Command: `flutter test`
- Result: All tests passed
- Total: 17 tests
- Duration: ~5s

## Context
- Phase 1: Removed local asset dependency (`assets/canonical_contract.json` deleted).
- Manifest updated to remove asset reference; `.env` and other assets remain.
- Verified via `flutter analyze`, `flutter clean`, and `flutter build apk --debug` (iOS build blocked by CocoaPods; Android debug build succeeded).
- Build artifacts confirm the asset is not bundled (`AssetManifest.json` lists `.env` and `assets/contracts/canonical.json` only).

## Notable Output (truncated)
```
00:05 +17: All tests passed!
```

## Notes
- Analytics tests log tracked events; these logs are expected and indicate correct behavior.
- Startup integration: `main.dart` now blocks on canonical contract fetch and configures analytics; existing tests remain green without modification.
- Add follow-up integration tests to cover `ContractService` fallbacks and `MyApp(initialContractMap)` boot path.

## Summary (Run 3)
- Command: `flutter test`
- Result: All tests passed
- Total: 17 tests
- Duration: ~2s

## Context
- Contract refresh provider integrated at app root via `ChangeNotifierProvider`.
- Pull-to-refresh implemented using `CupertinoSliverRefreshControl` on main pages.
- Refresh enabled only when backend URL is configured (`ContractProvider.canRefresh`).
- `MyApp` listens to provider updates and applies new contracts when version changes.

## Notable Output (truncated)
```
## Summary (Run 11)
- Command: `flutter test -r json`
- Result: All tests passed
- Total: 17 tests
- Duration: ~2s

## Context
- `main.dart` restructured to resolve `API_URL`, instantiate `ContractService`, and set up `MultiProvider` without blocking on network.
- `MyApp` (stateful) now defers `loadCanonicalContract()` using post-frame callback and configures `AnalyticsService` after contract load.
- Overlay usage fixed via `navigatorKey` in `CupertinoApp` to enable toasts after initial build.

## Notable Output (truncated)
```
📊 Tracked: pageEnter (component=null, page=page1, tag=null)
📊 Tracked: tap (component=btn1, page=page1, tag=null)
00:01 +17: All tests passed!
```
00:02 +17: All tests passed!
```

## Summary (Run 13)
- Command: `flutter test -r expanded`
- Result: All tests passed
- Total: 17 tests
- Duration: ~1s

## Context
- AnalyticsService now attaches contract/auth context and formats events with `contractType`, `contractVersion`, `isPersonalized`, and `userId` during flush.
- In-place mutation of event data was removed to maintain const map safety; enrichment occurs only at formatting time.
- Flush validates contract metadata presence; when `backendUrl` is missing, events remain queued; on `401` responses, authenticated events are cleared and flush stops.

## Notable Output (truncated)
```
📊 Tracked: error (component=formA, page=null, tag=null, contractType=unknown, version=unknown, personalized=false, user=null)
📊 Tracked: tap (component=x, page=null, tag=null, contractType=unknown, version=unknown, personalized=false, user=null)
📊 Tracked: pageEnter (component=null, page=page1, tag=null, contractType=unknown, version=unknown, personalized=false, user=null)
📊 Tracked: tap (component=btn1, page=page1, tag=null, contractType=unknown, version=unknown, personalized=false, user=null)
📊 Tracked: pageExit (component=null, page=page1, tag=null, contractType=unknown, version=unknown, personalized=false, user=null)
00:00 +17: All tests passed!
```

## Summary (Run 15)
- Command: `flutter test --reporter expanded`
- Result: All tests passed
- Total: 31 tests
- Duration: ~1s

## Context
- Frontend base URL resolution updated in `lib/main.dart` to prefer `.env` variables (`API_BASE_URL`/`API_URL`) before compile-time flags.
- Ensures the app reads contracts from the configured backend without requiring rebuilds when changing `.env`.
- No behavioral changes to provider/service logic; validation and debounce remained intact.

## Summary (Run 16)
- Date: 2025-11-02
- Command: `flutter test`
- Result: All tests passed
- Total: 44 tests
- Duration: ~3s

## Context
- Event enrichment fields (`pageScope`, `contractType`, `contractVersion`, `isPersonalized`, `userId`) confirmed across analytics tests.
- EnhancedPageBuilder emits diagnostics for page/component creation in debug runs; no release impact.
- Flush behavior: retains events when `backendUrl` is not configured (by design).

## Notable Output (truncated)
```
[diag][page] enter id=page1 layout=column components=2 bg=-
📊 Tracked: tap (component=btn1, page=page1, scope=public, ...)
📊 Tracked: pageExit (component=null, page=page1, scope=public, ...)
00:03 +44: All tests passed!
```

## Notable Output (truncated)
```
00:01 +31: All tests passed!
```

## Summary (Run 16)
- Command: `flutter test`
- Result: All tests passed
- Total: 31 tests
- Duration: ~3s

## Context
- Implemented contract-driven Cupertino theme in `lib/app.dart` using `themingAccessibility.tokens` and `typography`.
- Added default global `theme` in canonical contract to ensure token resolution selects `light` or `dark` predictably.
- Verified token parsing via `_parseColor` fallback and typography font weight mapping.

## Summary (Run 17)
- Command: `flutter test`
- Result: All tests passed
- Total: 31 tests
- Duration: ~3s

## Context
- Enhanced `EnhancedComponentFactory._resolveThemeTokens` to provide theme defaults:
  - `button.style.backgroundColor` defaults to `${theme.primary}` when omitted
  - `textButton.style.color` defaults to `${theme.primary}` when omitted
- Updated `docs/flutter-components_reference.md` to document these defaults.
- Confirmed no regressions in analytics and page builder tests.

## Notable Output (truncated)
```
00:03 +31: All tests passed!
```
## Summary (Run 16)
- Command: `flutter test`
- Result: All tests passed
- Total: 31 tests
- Duration: ~3s

## Context
- Parser now accepts style tokens in `StyleConfig.fromJson` (string) and stores them in `use`.
- Factory merges typography presets from contract (`themingAccessibility.typography`) with explicit overrides.
- Fixes crash when contracts provide `"style": "largeTitle"` or similar typography names.
 
## Summary (Run 17)
- Command: `flutter test`
- Result: All tests passed
- Total: 31 tests
- Duration: ~3s

## Context
- Bottom navigation items now support `route`/`label` in addition to `pageId`/`title`; tabs resolve pages via `routes` when `pageId` is omitted.
- Components accept a generic `action` field, mapped to `onTap` for interactive widgets (buttons, text, icons), aligning with the canonical contract.
- `NavigationBridge.routeToIndex` adds route indices directly when items specify `route`, improving tab switching.

## Notable Output (truncated)
```
00:03 +31: All tests passed!
```

## Notable Output (truncated)
```
00:03 +31: All tests passed!
```
## Test Run: Scanner fix and binding checks
- Command: `flutter test -r expanded`
- Result: All tests passed
- Total: 31 tests
- Duration: ~1s
- Notable logs:
  - `[diag][page] enter id=page1 layout=column components=2 bg=-`
  - `📊 Tracked: pageEnter` and `pageExit` events emitted
  - Analytics flush behavior correctly retains events when `backendUrl` missing
  - ContractProvider routing tests passed with auth state present
## Summary (Run 21)
- Command: `flutter test`
- Result: All tests passed
- Total: 33 tests
- Duration: ~3s

## Context
- Added deep state path resolution in `EnhancedStateManager.getState` to support `${state.user.username}`.
- Updated `TextComponent` to resolve `${state.*}` and `${item.*}` templates and subscribe to root state keys for rebuilds.
- Implemented static list support via `EnhancedDataSourceConfig.type='static'` and `items`, and updated `EnhancedListWidget` to render static items.

## Notable Output (truncated)
```
00:02 +29: /test/widgets/enhanced_page_builder_test.dart: EnhancedPageBuilder wraps tracked components and emits tap
[diag][component] Create type=textButton id=btn1
[diag][component] Create type=text id=txt1
00:03 +33: All tests passed!
```
## Summary (Run 23)
- Command: `flutter test`
- Result: All tests passed
- Total: 37 tests
- Duration: ~3s

## Context
- Parser updated to accept field name strings in `DataModel.fields` lists and `name:type` shorthand.
- Added unit tests covering `FieldConfig` type string/list shorthand, `DataModel` fields list handling, relationships string shorthand, and index string shorthand.

## Notable Output (truncated)
```
00:03 +37: All tests passed!
```
## Summary (Run 24)
- Command: `flutter test`
- Result: All tests passed
- Total: 37 tests
- Duration: ~3s

## Context
- Docs cleanup: added `docs/flutter-building_contracts_guide.md` as the single canonical guide for authoring and delivering contracts; linked from README.
- No code changes affecting runtime behavior.

## Notable Output (truncated)
```
00:03 +37: All tests passed!
```
## Test Run - 2025-11-02

- Command: `flutter test`
- Outcome: All tests passed
- Duration: ~3 seconds

Highlights:
- AnalyticsService events tracked for taps and pageEnter/pageExit.
- ComponentFactory and PageBuilder tests succeeded (`+39` tests reported).

Relevant Logs (truncated):

```
📊 Tracked: pageEnter (component=null, page=page1, scope=public, tag=null, contractType=unknown, version=unknown, personalized=false, user=null)
📊 Tracked: tap (component=btn1, page=page1, scope=public, tag=null, contractType=unknown, version=unknown, personalized=false, user=null)
📊 Tracked: pageExit (component=null, page=page1, scope=public, tag=null, contractType=unknown, version=unknown, personalized=false, user=null)
00:03 +39: All tests passed!
```
## Summary (Run 51 — DTO alignment for backend ingestion)
- Command: `flutter test --coverage`
- Result: All tests passed
- Total: 44 tests
- Duration: ~4–5s

## Context
- Updated `AnalyticsService` to produce NestJS-compatible payloads:
  - Wrap body in `{events: [...]}`
  - Use ISO timestamps
  - Map `TrackingEventType` to allowed values
  - Move metadata under `data`; only include valid `sessionId`
- Manual `curl` post to `/events` returned `{ inserted: 1 }`.
- Aggregate stats for `page=debug` reflected the inserted event.

## Notable Output (truncated)
```
00:04 +44: All tests passed!
```
## Summary (Run 54 — Immediate flush on bottom nav changes)
- Command: `flutter test`
- Result: All tests passed
- Total: 44 tests
- Duration: ~3s

## Context
- Added immediate `AnalyticsService().flush()` call after tracking `routeChange` in the `CupertinoTabController` listener within `lib/app.dart`.
- Ensures bottom navigation taps trigger an API call without delay; backend receives `eventType: 'navigate'` with stable `componentId` and `pageId`.
- No visual changes; behavior affects analytics network calls only.

## Notable Output (truncated)
```
00:03 +44: All tests passed!
```
## Run 2025-11-03

- Tests: 45 passed, 45 total
- Time: 00:04
- Notes: analytics events logged during tests; no failures.
## Run 2025-11-03 (post bottom-nav gating fix)

- Tests: 45 passed, 45 total
- Time: 00:04
- Notes: bottom navigation auth gating updated; existing widget tests unaffected.
## Run 2025-11-03 (post logout navigation root fix)

- Tests: 45 passed, 45 total
- Time: 00:04
- Notes: root navigator used for logout routing; no regressions observed.

## Run 2025-11-03 (Analytics DTO alignment: remove top-level id)

- Command: `flutter test`
- Outcome: All tests passed
- Total: 45 tests
- Duration: ~4 seconds

- Highlights:
- Updated `AnalyticsService` to remove invalid top-level `id` and include `userId` for event-level attribution.
- Tagging (rage_click, rapid_repeat) and form submit error linking validated.

- Logs excerpt (truncated):
```
00:04 +45: All tests passed!
📊 Tracked: tap (component=btn1, page=null, scope=public, ...)
⚠️ No backendUrl configured; keeping 1 events in memory
```

## Run 2025-11-04 (canonical spacing and typography polish)

- Command: `flutter test`
- Outcome: All tests passed
- Total: 45 tests
- Duration: ~3–4 seconds

Highlights:
- Spacing and hierarchy improvements applied to canonical `pagesUI`:
  - Replaced `grid.style.gap` with `grid.spacing` in Podcasts to enable proper gaps.
  - Added `row.spacing` and `column.spacing` in Music and Audiobooks item builders for consistent space-x/space-y.
  - Applied typography tokens via `style.use` (`largeTitle`, `title1`, `body`, `caption`) for clear title/subtitle hierarchy.
- Verified token resolution and spacing behavior via `EnhancedComponentFactory` and helpers (`_applySpacing`).
- No test changes required; analytics and page builder suites remain green.

Logs excerpt (truncated):
```
00:03 +45: All tests passed!
📊 Tracked: input (component=field1, page=null, scope=public, ...)
⚠️ No backendUrl configured; keeping 1 events in memory
```

## Summary (Run 66 — Page-level Grid Support)
- Command: `flutter test`
- Result: All tests passed
- Total: 47 tests
- Duration: ~4s

- Context
  - Added page-level grid properties to `EnhancedPageConfig`: `columns` and `spacing`.
  - Updated `EnhancedPageBuilder` to render a grid when `layout` is `grid`, or when `layout` is `scroll` and page-level `columns`/`spacing` are provided.
  - Added widget test `test/widgets/page_grid_layout_test.dart` asserting `GridView.count` is used with correct `crossAxisCount` and spacing values.

- Notable Output (truncated)
```
[diag][pageGrid] page=home columns=3 spacing=12.0 children=3
00:04 +47: All tests passed!
```
## Summary (Run 78 — Contract source switching & startup refresh)
- Command: `flutter test`
- Result: All tests passed
- Total: 48 tests
- Duration: ~4–5s

- Context
  - Updated `lib/app.dart` to apply UI updates when `ContractSource` changes (canonical → personalized) even if `meta.version` stays the same.
  - Added startup attempt to load a personalized contract when a persisted `authToken` and `user.id` exist, preventing the app from sticking to canonical post-relaunch.

- Notable Output (truncated)
```
00:04 +48: All tests passed!
[diag][page] enter id=home layout=scroll components=3 bg=-
📊 Tracked: pageEnter (component=null, page=home, scope=public, ...)
⚠️ No backendUrl configured; keeping 1 events in memory
```
## Summary (Run 79 — Boot user-first, fallback canonical)
- Command: `flutter test`
- Result: All tests passed
- Total: 48 tests
- Duration: ~3–4s

- Context
  - Startup contract selection now attempts to load the personalized user contract first when persisted `authToken` and `user.id` are found; falls back to canonical otherwise.
  - Reads persisted values from secure storage and shared preferences for robustness.

- Notable Output (truncated)
```
00:03 +48: All tests passed!
[diag][page] enter id=home layout=scroll components=3 bg=-
📊 Tracked: pageEnter (component=null, page=home, scope=public, ...)
```

## Summary (Run 80 — JSON decode helper fix)
- Command: `flutter test`
- Result: All tests passed
- Total: 48 tests
- Duration: ~3–4s

- Context
  - Replaced undefined `ParsingUtils.tryDecodeJson` calls with `jsonDecode` from `dart:convert`; added the import.
  - Affects boot-time parsing of persisted `state:global:user` when stored as a JSON string.

- Notable Output (truncated)
```
00:03 +48: All tests passed!
[diag][page] enter id=home layout=scroll components=1 bg=#FFFFFF
```