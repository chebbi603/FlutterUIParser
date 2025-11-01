Project: demo_json_parser (Flutter)
# Test Results — Run 23 (2025-11-01)

## Command
- `flutter test`

## Outcome
- Result: All tests passed
- Total: 33 tests
- Duration: ~3s

## Changes Covered
- Image component: token resolution for `src` now supports `${state.*}` and `${item.*}`; subscribes to state changes.
- AuthService: persists `state.user.username` and `state.user.name` from `/auth/login` response alongside `id` and `role`.
- Docs: updated `flutter-components_reference.md` (Image templates) and `flutter-backend_frontend_communication.md` (auth mapping and example).

## Logs (truncated)
```
00:03 +33: All tests passed!
📊 Tracked: tap (component=btn1, page=page1, scope=public, contractType=unknown, ...)
📊 Tracked: pageEnter/pageExit continue emitting with enriched context
```

## Notes
- No test additions were required; existing widget and analytics tests continue to pass.
- Follow-up: consider adding dedicated tests for Image `src` template resolution using a minimal contract stub.