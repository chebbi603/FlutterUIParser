Project: demo_json_parser (Flutter)
# Test Results — Run 51 (DTO alignment)

- Command: `flutter test --coverage`
- Result: All tests passed
- Total: 44 tests
- Duration: ~4–5s
- Coverage artifact: `coverage/lcov.info`

## Changes verified
- AnalyticsService payload updated to match NestJS `CreateEventsBatchDto`:
  - Wrap body as `{ "events": [...] }`
  - Use ISO 8601 timestamps
  - Map `TrackingEventType` to allowed values `tap|view|input|navigate|error|form-fail`
  - Move extra metadata under `data` (contract info, pageScope, tags, result/error)
  - Only include `sessionId` when valid 24-hex ObjectId

## Observations
- Unit tests unaffected; existing analytics tests continue to pass.
- Manual verification: posting sample event to `/events` returned `{ inserted: 1 }`.
- Aggregate endpoint for `page=debug` shows correct counts and top components.

## Relevant logs (truncated)
```
00:04 +44: All tests passed!
📊 Tracked: tap (component=x, page=null, scope=public, ...)
⚠️ No backendUrl configured; keeping 1 events in memory
```