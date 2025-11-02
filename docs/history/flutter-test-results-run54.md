Project: demo_json_parser (Flutter)
Test Run: 54

Scope
- Implement immediate analytics flush when a bottom navigation tab changes.
- Ensure that `routeChange` events are sent to the backend without delay.

Code Changes
- File: `lib/app.dart`
  - In the `CupertinoTabController` listener, after calling `AnalyticsService().trackComponentInteraction(...)` for tab switches, call `AnalyticsService().flush()` to POST the event batch immediately.
  - This targets `TrackingEventType.routeChange` (backend `eventType: 'navigate'`) with stable `componentId` `bottom_nav_item_{index}_{key}` and `pageId` from the tab.

Behavior Notes
- `flush()` is a no-op when `backendUrl` is not configured or the queue is empty; otherwise it posts to `http://localhost:8081/events` (normalized default) or the contract’s configured analytics URL.
- Authorization header is attached automatically when an `authToken` is present in global state.

Command
- `flutter test`

Results
- All tests passed (44/44).
- Existing analytics tests validated tagging and flush behavior when `backendUrl` is missing.
- No regressions detected in `EnhancedPageBuilder`, contract loading, or state management.

Outcome
- Bottom navigation tab changes now trigger an immediate analytics API call via `flush()`, improving observability of navigation interactions.