Project: demo_json_parser (Flutter)
# NavigationBridge Auth Enforcement

## Overview
- `NavigationBridge.switchTo(route)` enforces contract route auth flags.
- Protected routes require an authenticated session (non-empty `authToken` in global state).
- Unauthorized attempts redirect to `/login` and emit a standardized analytics event.

## Contract Integration
- Reads `pagesUI.routes[route].auth` from the canonical contract to determine protection.
- Expects the login route to be public (`/login: { auth: false }`) and the home/content routes to be protected (`auth: true`).

## Behavior
- When `switchTo` is called:
  - If the route is public, switches tabs/navigates normally.
  - If the route is protected and the user is not authenticated:
    - Emits `logAuthEvent('login_page_viewed', { 'source': 'redirect_from_protected' })`.
    - Switches to `/login` using the tab controller mapping or falls back to navigator.
 - On explicit logout:
   - Client clears `authToken`, `refreshToken`, persisted state, and cached contract.
   - Navigation redirects to `/login` and clears the back stack to prevent returning to protected pages.

## Authentication Predicate
- The app wires `NavigationBridge` with two predicates:
  - `isRouteProtected(String route)`: reads the contract routes map.
  - `isAuthed()`: returns `true` when a non-empty `authToken` exists in `EnhancedStateManager`.

## Analytics Standardization
- Use `AnalyticsService.logAuthEvent(name, data)` for auth telemetry:
  - `login_page_viewed` with `source` values: `navigation`, `deep_link`, `redirect_from_protected`.
  - `user_authenticated` with optional `userId` and a `loginMethod`.
  - `login_failed` with `reason`: `missing_credentials` or `invalid_credentials`.
  - `logout` with an ISO timestamp.

## Implementation References
- Source: `lib/navigation/navigation_bridge.dart`, `lib/app.dart`, `lib/events/action_dispatcher.dart`, `lib/services/auth_service.dart`.
- Contract: `assets/contracts/canonical-contract-v1.json` (`pagesUI.routes`).

## Testing
- Run `flutter test` to verify analytics tagging and navigation wrappers.
- Test results are logged in `docs/flutter-test-results.md`.
## Bottom Navigation Visibility

- Bottom navigation is hidden when not authenticated.
- Contract flag `pagesUI.bottomNavigation.authRequired` controls gating; if omitted, the app defaults to requiring authentication.
- After logout, the app rebuilds using the canonical contract and hides the bottom navigation until the user logs in again.