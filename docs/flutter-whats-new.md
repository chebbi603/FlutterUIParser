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
- Controlled by `ContractProvider.canRefresh` and `.env` backend url configuration.
- More: see `docs/flutter-flutter_project_status.md` and `docs/flutter-backend_contract_service.md`.

## Backend URL Resolution
- `.env` `API_BASE_URL` (or `API_URL`) preferred; read via `flutter_dotenv` in `lib/main.dart`.
- Allows changing backend without rebuilds.
- More: `docs/flutter-backend_contract_service.md`.

## Image Token Templates
- `image.src` supports `${state.*}` and `${item.*}` templates.
- Typical use: user avatar URLs.
- More: `docs/flutter-backend_frontend_communication.md`.

## Notes
- The historic runtime validator was removed; docs were updated to reflect current behavior without runtime validation.
- Tests: see `docs/flutter-test-results.md` for latest outcomes.