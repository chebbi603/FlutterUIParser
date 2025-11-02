# Flutter Test Results — Run 58

- Date: 2025-11-02
- Command: `flutter test`
- Exit code: 0
- Duration: ~3s
- Passed: 45
- Failed: 0

## Changes Under Test
- `AnalyticsService._formatEventForBackend` now includes a top-level `id` when a valid 24-hex user id exists in global state (`state.user.id`).
- This ensures backend attribution uses per-event aliases (`id`/`_id`/`userId`) and avoids the fallback to `000000000000000000000000`.
- Client continues to mirror `data.userId` for analytics segmentation; no visual/UI changes.

## Key Log Excerpts (truncated)
```
00:03 +45: All tests passed!
```

## Notes
- Widget/unit tests do not perform live HTTP calls; they validate event formatting and analytics queue behavior.
- For runtime verification, run the app with `flutter run` and inspect backend logs for `POST /events` with top-level `id` present.