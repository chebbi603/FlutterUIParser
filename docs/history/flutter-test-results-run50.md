# Flutter Test Results — Run 50

- Project: `demo_json_parser`
- Date: 2025-11-02
- Command: `flutter test --coverage`

## Summary
- Result: All tests passed
- Total: 44 tests
- Duration: ~5s
- Coverage: `coverage/lcov.info` generated

## Full Output (truncated to relevant sections)
```
00:04 +40: /Users/chebbimedayoub/Documents/Thesis work/demo_json_parser/test/analytics/analytics_service_test.dart: AnalyticsService tagging and linking links error to latest form submit within window
📊 Tracked: formSubmit (component=formA, page=null, scope=public, tag=null, contractType=unknown, version=unknown, personalized=false, user=null)
📊 Tracked: error (component=formA, page=null, scope=public, tag=null, contractType=unknown, version=unknown, personalized=false, user=null)
00:04 +41: /Users/chebbimedayoub/Documents/Thesis work/demo_json_parser/test/analytics/analytics_service_test.dart: AnalyticsService flush behavior flush keeps events when backendUrl is not configured
📊 Tracked: tap (component=x, page=null, scope=public, tag=null, contractType=unknown, version=unknown, personalized=false, user=null)
⚠️ No backendUrl configured; keeping 1 events in memory
00:05 +43: /Users/chebbimedayoub/Documents/Thesis work/demo_json_parser/test/widgets/enhanced_page_builder_test.dart: EnhancedPageBuilder wraps tracked components and emits tap
[diag][page] enter id=page1 layout=column components=2 bg=-
📊 Tracked: pageEnter (component=null, page=page1, scope=public, tag=null, contractType=unknown, version=unknown, personalized=false, user=null)
[diag][component] Create type=textButton id=btn1
[diag][component] page=page1 type=textButton id=btn1 bg=no binding=no
[diag][component] Create type=text id=txt1
[diag][component] page=page1 type=text id=txt1 bg=no binding=no
📊 Tracked: tap (component=btn1, page=page1, scope=public, tag=null, contractType=unknown, version=unknown, personalized=false, user=null)
📊 Tracked: pageExit (component=null, page=page1, scope=public, tag=null, contractType=unknown, version=unknown, personalized=false, user=null)
00:05 +44: All tests passed!
```

## Artifacts
- Coverage: `coverage/lcov.info`
- Logs: See above truncated output; full logs available via CI.

## Notes
- This run validates analytics behavior when `backendUrl` is absent, ensuring the client defers network calls and retains events in memory.