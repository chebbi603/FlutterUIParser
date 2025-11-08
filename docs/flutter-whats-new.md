Project: demo_json_parser (Flutter)
# What’s New

This document concisely captures the latest feature additions and behavior changes to reduce redundancy across other docs. Refer to the linked guides for deeper details.

## Event Enrichment (2025-11-01)
- Analytics events now include:
  - `pageScope` (`public` | `authenticated`)
  - `contractType` (`canonical` | `personalized` | `unknown`)
  - `contractVersion` (semver)
  - `isPersonalized` (boolean)
  - `userId` (optional)
- Purpose: Enable backend segmentation and funnel analysis.
- More: see `docs/flutter-backend_frontend_communication.md`.

## UI Diagnostic Scanner (Debug-only)
- Location: `lib/diagnostics/ui_scanner.dart`.
- Checks for unrecognized component types, unresolved bindings, missing page backgrounds, and design token mismatches.
- Invoked during debug builds after contract application and component factory init.
- More: see `docs/flutter-ui_diagnostic_scanner.md`.

## Navigation Auth Enforcement
- Wrappers add analytics around login/logout and respect `pagesUI.routes[*].auth`.
- Emits standardized events (`login_success`, `login_failed`, `logout`).
- Fix: Logout now reliably redirects to `/login` and clears the navigation stack, even when bottom navigation is disabled.
- More: see `docs/flutter-navigation_auth_enforcement.md`.

## Contract Refresh Flow
- ContractProvider drives refresh; canonical contract fetched at boot.
- Pull-to-refresh via `CupertinoSliverRefreshControl` on main pages.

## Contract Source Switching & Startup Refresh (2025-11-08)
- Applies UI updates when contract source changes (canonical → personalized), even if `meta.version` is unchanged.
- On app startup, attempts to load a personalized contract when persisted `authToken` and `state.user.id` exist.
- Outcome: avoids sticking to canonical after relaunch for logged-in users; ensures personalized pages and features render immediately.

## Page-Level Grid Layout (2025-11-02)
- Pages can render as a grid using `layout: "grid"` or by specifying `columns`/`spacing` with `layout: "scroll"`.
- Implementation uses `GridView.count` with `columns` mapped to `crossAxisCount` and `spacing` applied to both axes.
- Diagnostics include `[diag][pageGrid]` logs with page id, columns, spacing, and child count.
- More: see `docs/flutter-components_reference.md` (Page Layouts) and `docs/flutter-framework_implementation_summary.md`.

## Token-Only Auth Gating (2025-11-05)
- Protected routes and bottom navigation visibility now rely on a non-empty `authToken` only; `state.user.id` is no longer required.
- Purpose: support backends that issue access/refresh tokens without returning a user id in the login response.
- Impact: post-login navigation to `/home` succeeds when tokens are present, even if no `user.id` is provided.
- More: see `docs/flutter-navigation_auth_enforcement.md`.

## Debug Auto-Login Removed (2025-11-02)
- The previous debug-only auto-login behavior controlled via `.env` keys has been removed.
- Manual login is required to obtain an access token; analytics events continue to ingest without authentication.
- The client still attaches `Authorization: Bearer <JWT>` when a token exists, but this is optional for public endpoints.
- More: see `docs/flutter-analytics_backend_configuration.md`.
- Controlled by `ContractProvider.canRefresh` and `.env` backend url configuration.
- More: see `docs/flutter-flutter_project_status.md` and `docs/flutter-backend_contract_service.md`.

## Backend URL Resolution
- `.env` `API_BASE_URL` (or `API_URL`) preferred; read via `flutter_dotenv` in `lib/main.dart`.
- Allows changing backend without rebuilds.
- More: `docs/flutter-backend_contract_service.md`.

## Analytics URL Path Normalization (2025-11-05)
- The app now coerces common analytics backend URL variants to the canonical ingestion path `'/events'`.
- Inputs like `'/analytics'` or `'/analytics/events'` are normalized to `'/events'` to ensure clicks and flushes hit the correct endpoint consistently.
- More: see `docs/flutter-analytics_backend_configuration.md`.

## LLM Sanitization & Strict Schema (2025-11-08)
- Backend now sanitizes LLM-generated contracts before serving to the client, ensuring only Flutter-supported components appear.
- Aliases normalized: `progressBar` → `progressIndicator`, `text_field` → `textField`, `list.itemTemplate` → `list.itemBuilder`, `searchBar.action` → `searchBar.onChanged`, plus `keyboard` → `keyboardType`, `obscure` → `obscureText`.
- Public pages are excluded from generated contracts; generation flows produce authenticated-only pages.
- A suppression summary is prepended to `json.meta.optimizationExplanation` describing excluded public pages, dropped components, and normalizations; useful for diagnostics.
- Result: More stable UI application of contracts with fewer parse errors and predictable component rendering.
- More: see `docs/flutter-data_flow.md` and backend `docs/contracts-behavior.md`.

## Image Token Templates
- `image.src` supports `${state.*}` and `${item.*}` templates.
- Typical use: user avatar URLs.
- More: `docs/flutter-backend_frontend_communication.md`.

## Notes
- The historic runtime validator was removed; docs were updated to reflect current behavior without runtime validation.
- Tests: see `docs/flutter-test-results.md` for latest outcomes.