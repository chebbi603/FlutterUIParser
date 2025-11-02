Project: demo_json_parser (Flutter)
# Detailed Test Results — Run 48

- Date: 2025-11-02
- Command: `flutter test`
- Exit code: 0
- Duration: ~3s
- Passed: 44
- Failed: 0

### Changes under test
- Analytics flush now attaches `Authorization: Bearer <token>` when a token is present in global state.
- App startup triggers a small debug-only baseline flush after 2 seconds to send public-scope events.

### Logs (key excerpts)
```
📊 Tracked: pageEnter (component=null, page=page1, scope=public, tag=null, contractType=unknown, version=unknown, personalized=false, user=null)
📊 Tracked: tap (component=btn1, page=page1, scope=public, tag=null, contractType=unknown, version=unknown, personalized=false, user=null)
00:03 +44: All tests passed!
```

### Notes
- Tests are headless and do not perform live HTTP calls; analytics queue behavior and formatting remain unchanged.
- Network behavior (Authorization header on flush) is covered by runtime integration, not unit tests.