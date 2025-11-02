Project: demo_json_parser (Flutter)
# Test Results — 2025-11-02
Latest run: see `docs/history/flutter-test-results-run55.md` for details.

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