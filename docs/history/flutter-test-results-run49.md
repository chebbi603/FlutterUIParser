# Flutter Test Results — Run 49

- Date: 2025-11-02
- Command: `flutter test`
- Exit code: 0
- Duration: ~3s
- Passed: 44
- Failed: 0

## Changes Under Test
- Implemented debug-only auto-login in `lib/app.dart` using `.env` keys:
  - `DEBUG_AUTO_LOGIN=true`
  - `DEBUG_EMAIL=test@example.com`
  - `DEBUG_PASSWORD=password123`
- Ensures analytics flushes include `Authorization: Bearer <JWT>` when auto-login succeeds.
- Maintains the debug baseline flush after a 2-second delay to quickly verify event ingestion.

## Key Log Excerpts (truncated)
```
00:03 +44: All tests passed!
[diag][page] enter id=page1 layout=column components=2 bg=-
📊 Tracked: pageEnter (component=null, page=page1, scope=public, ...)
[diag][component] Create type=textButton id=btn1
📊 Tracked: tap (component=btn1, page=page1, scope=public, ...)
📊 Tracked: pageExit (component=null, page=page1, scope=public, ...)
```

## Notes
- Tests are unit/widget and do not require a live backend.
- End-to-end verification of JWT-protected analytics endpoints should be performed by running NestJS (`MONGO_URL` configured) and launching the Flutter app (`flutter run`).
- See `docs/flutter-analytics_backend_configuration.md` for the auth header behavior, debug auto-login setup, and baseline flush details.