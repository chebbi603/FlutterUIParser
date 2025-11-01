Project: demo_json_parser (Flutter)
# Test Results — 2025-11-01

## Summary (Run 2)
- Command: `flutter test`
- Result: All tests passed
- Total: 17 tests
- Duration: ~2s

## Notable Output (truncated)
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
00:02 +17: All tests passed!
```