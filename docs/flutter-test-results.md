Project: demo_json_parser (Flutter)
# Test Results — 2025-11-01

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