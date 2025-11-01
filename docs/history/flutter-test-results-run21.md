# Flutter Test Results — Run 21 (2025-11-01)

## Command
`flutter test`

## Outcome
- Result: All tests passed
- Total: 33 tests
- Duration: ~3s

## Context
- Deep state path resolution added to `EnhancedStateManager.getState`.
- `TextComponent` now resolves `${state.*}` and `${item.*}` templates and subscribes to root state keys.
- Static data source support added to `EnhancedDataSourceConfig` (`type`, `items`) and `EnhancedListWidget` renders static items without API calls.

## Full Output (truncated)
```
📊 Tracked: tap (component=x, page=null, scope=public, tag=null, contractType=unknown, version=unknown, personalized=false, user=null)
00:02 +28: ... analytics_service_test.dart: AnalyticsService flush behavior
📊 Tracked: tap (component=x, page=null, scope=public, tag=null, contractType=unknown, version=unknown, personalized=false, user=null)
⚠️ No backendUrl configured; keeping 1 events in memory
00:02 +29: ... enhanced_page_builder_test.dart: EnhancedPageBuilder wraps tracked components and emits tap
[diag][page] enter id=page1 layout=column components=2 bg=-
📊 Tracked: pageEnter (component=null, page=page1, scope=public, tag=null, contractType=unknown, version=unknown, personalized=false, user=null)
[diag][component] Create type=textButton id=btn1
[diag][component] page=page1 type=textButton id=btn1 bg=no binding=no
[diag][component] Create type=text id=txt1
[diag][component] page=page1 type=text id=txt1 bg=no binding=no
00:02 +29: ... component_tracker_test.dart: ComponentTracker emits tap event to AnalyticsService
📊 Tracked: tap (component=comp1, page=null, scope=public, tag=null, contractType=unknown, version=unknown, personalized=false, user=null)
00:02 +30: ... enhanced_page_builder_test.dart: EnhancedPageBuilder wraps tracked components and emits tap
📊 Tracked: tap (component=btn1, page=page1, scope=public, tag=null, contractType=unknown, version=unknown, personalized=false, user=null)
📊 Tracked: pageExit (component=null, page=page1, scope=public, tag=null, contractType=unknown, version=unknown, personalized=false, user=null)
00:03 +33: All tests passed!
```