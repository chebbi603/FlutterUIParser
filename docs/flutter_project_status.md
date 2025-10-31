# Project Status and Architecture Guide

This document provides a comprehensive overview of the project’s current status, architecture, directories, notable files, how they work, and known limitations. It serves as a living reference for contributors and reviewers to quickly understand health, behavior, and boundaries of the system.

## Current Status Summary

- Build: `flutter analyze` reports no issues.
- Tests: All current test suites pass.
 - Runtime: Designed to run with `flutter run` (iOS simulator available). No contract validation module is active in runtime. Canonical contract retrieval first calls `/contracts/canonical` (public), falls back to `/contracts/public/canonical` on `401`/`404`, and ultimately loads `assets/canonical_contract.json` when backend is unreachable.
- Coverage: `coverage/lcov.info` exists but may reference now-removed files; regenerate coverage to reflect the latest state.
- Documentation: Extensive docs exist; some legacy mentions of the removed validation module remain and are noted below.

## Quick Run and Build

- Install dependencies: `flutter pub get`
- Analyze code: `flutter analyze`
- Run tests: `flutter test`
- Launch app: `flutter run`
 - iOS emulator: Launch Simulator (`open -a Simulator`) then `flutter run` to deploy.

## Repository Structure Overview

Top-level directories and their roles:

- `android/`, `ios/`, `macos/`, `linux/`, `windows/`: Platform-specific Flutter scaffolding and build assets.
- `assets/`: JSON contract and its schema used by the app at runtime.
- `docs/`: Architecture, system guides, DSL references, and internal explanations.
- `lib/`: Application source code (logic, UI, services, analytics, etc.).
- `test/`: Unit and widget tests covering analytics, engine, utils, and UI builders.
- `tools/`: Utility scripts (currently empty after removing the validator CLI).
- `web/`: PWA assets and web-specific files.

Other root files:

- `README.md`: High-level project overview and setup steps.
- `CHANGELOG.md`: Version history and changes across releases.
- `analysis_options.yaml`: Lint rules and analyzer configuration.
- `pubspec.yaml` / `pubspec.lock`: Dependencies and resolved versions.
- `.env.example`: Example environment variables configuration.
- `coverage/lcov.info`: Code coverage report (stale after recent removals; regenerate as needed).

## Core App Flow

- Entry point: `lib/main.dart` initializes the Flutter app and constructs the root `App` widget.
- Application bootstrap: `lib/app.dart` loads the canonical JSON contract from `assets/canonical_contract.json`. It previously performed contract-wide validation; that logic has been removed, and the app now directly builds UI from the loaded contract.
- Page building: `lib/widgets/enhanced_page_builder.dart` takes parsed contract pages and composes the widget tree, augmenting it with analytics tracking and common behaviors.
- State/reactivity: `lib/engine/graph_engine.dart` manages a dependency graph between state keys and UI components, and `lib/widgets/graph_subscriber.dart` subscribes widgets to state changes for reactive updates.
- Actions and events: `lib/events/action_dispatcher.dart` executes actions defined in the contract (e.g., `navigate`, `apiCall`, `updateState`), optionally passing parameters. `lib/events/action_middleware.dart` can intercept and augment action lifecycles, and `lib/events/event_bus.dart` provides a lightweight pub/sub for app events.
- Navigation: `lib/navigation/navigation_bridge.dart` bridges contract-defined routes and `Navigator` behavior.
- Analytics: `lib/analytics/` contains models, services, and widgets for tracking component events (tap, input, form submit) and flushing them to a backend when configured.
- Services/API: `lib/services/api_service.dart` defines how contract-described service endpoints are invoked and how responses are matched against expected data models.
- Permissions: `lib/permissions/permission_manager.dart` centralizes permission checks that can gate actions or component availability.
- Persistence: `lib/persistence/state_persistence.dart` persists state to device storage according to contract rules.
- Utilities: `lib/utils/parsing_utils.dart` parses typed configuration values (e.g., keyboard types) and performs helper transforms.

## Modules and Files – Detailed Index

### Assets

- `assets/canonical_contract.json`
  - Role: The primary contract describing pages, components, routes, services, and state.
  - How it works: Loaded at app startup and used to drive UI and behavior.
  - Limitations: No active runtime-wide contract validation; malformed entries can lead to runtime errors.

- `assets/canonical_contract.schema.json`
  - Role: JSON Schema describing expected shape of the contract.
  - How it works: Used for tooling and reference; not enforced at runtime after validator removal.
  - Limitations: Must be manually synced with contract changes; not enforced by the app.

### Core (`lib/`)

- `lib/main.dart`
  - Role: Flutter entry point.
  - How it works: Calls `runApp` and constructs `App`.
  - Limitations: None beyond standard Flutter bootstrapping.

- `lib/app.dart`
  - Role: Loads canonical contract and initializes global app context.
  - How it works: Reads contract from `assets`, builds initial page structure using page builder.
  - Limitations: Contract validation is removed; relies on the contract being well-formed.

- `lib/engine/graph_engine.dart`
  - Role: Manages a reactive graph linking state keys to subscribed components.
  - How it works: Components register dependencies; when state updates, the engine notifies subscribers to rebuild.
  - Limitations: Complex interactions may require careful dependency management to avoid missed updates or redundant rebuilds.

- `lib/models/config_models.dart`
  - Role: Data models describing contract structures (pages, components, state, validations, etc.).
  - How it works: Provides typed classes/structs for parsed contract elements used throughout the app.
  - Limitations: Includes `ValidationsConfig` types though runtime validation is disabled; future removal or repurposing may be desirable.

- `lib/state/state_manager.dart`
  - Role: Central store for state keys and values.
  - How it works: Offers `getState`/`setState` APIs; triggers graph engine notifications.
  - Limitations: Persistence policy enforcement depends on `persistence/`; invalid keys/types are not guarded by a validator.

- `lib/utils/parsing_utils.dart`
  - Role: Helpers to parse and convert contract fields to Flutter-friendly values.
  - How it works: Maps configuration strings to enums, keyboard types, etc.
  - Limitations: Assumes valid input strings; invalid values may degrade UX.

- `lib/navigation/navigation_bridge.dart`
  - Role: Routing utilities that bridge contract routes with Flutter navigation.
  - How it works: Provides helpers to navigate based on `route`/`pageId` in actions.
  - Limitations: Relies on pages being present; no validator checks for unknown pages.

- `lib/permissions/permission_manager.dart`
  - Role: Centralized permission controls.
  - How it works: Evaluates whether a component/action is allowed based on current context and contract rules.
  - Limitations: Depends on contract consistency; errors in rules may cause unexpected gating.

- `lib/persistence/state_persistence.dart`
  - Role: Persist selected state values across app restarts.
  - How it works: Saves/loads according to contract persistence policies.
  - Limitations: Policies are not validated; incorrect settings can lead to undesired persistence.

- `lib/services/api_service.dart`
  - Role: Defines API call flow and response handling for contract-described services.
  - How it works: Matches responses to expected models, includes helpers like `_validateArrayItemsAgainstModel` and `_validateObjectAgainstModel`.
  - Limitations: Without global contract validation, model references (`$ref`) and schema correctness rely on contract authors; mismatch can cause runtime exceptions.

#### Widgets (`lib/widgets/`)

- `lib/widgets/component_factory.dart`
  - Role: Central factory that creates components based on contract `type`.
  - How it works: Uses a registry of builders to instantiate widgets; manages caches and theme context.
  - Limitations: No inline validator; assumes valid config for component creation.

- `lib/widgets/component_registry.dart`
  - Role: Registry mapping component `type` strings to builder functions.
  - How it works: Provides a lookup to construct the correct widget for a given contract component.
  - Limitations: A missing or misspelled type leads to unrendered components.

- `lib/widgets/enhanced_page_builder.dart`
  - Role: Builds page structures from contract definitions with analytics hooks.
  - How it works: Wraps components, subscribes to page lifecycle, and emits analytics events on entry/exit.
  - Limitations: Depends on valid page configs; missing routes/pages can cause navigation issues.

- `lib/widgets/graph_subscriber.dart`
  - Role: Widget to subscribe to state graph changes.
  - How it works: Rebuilds child when any of the listed dependencies change.
  - Limitations: Incorrect dependency lists can cause stale UI or redundant updates.

- `lib/widgets/media_widgets.dart`
  - Role: Helpers for media rendering (images, icons, videos if applicable).
  - How it works: Provides common media widget utilities compliant with contract references.
  - Limitations: Assets must be present and correctly referenced; no validator ensures asset mappings.

##### Components (`lib/widgets/components/`)

- `text_component.dart`
  - Role: Renders static or contract-driven text.
  - How it works: Builds a `Text` widget based on contract fields (e.g., `text`, `style`).
  - Limitations: Assumes valid content; formatting and localization depend on upstream config.

- `text_field_component.dart`
  - Role: Renders an editable text field with optional actions.
  - How it works: Uses `CupertinoTextField`, binds to `stateKey`, triggers `onChanged` actions via `ActionDispatcher`.
  - Limitations: Inline validation is disabled; `c.validation` rules are not enforced. Error label remains wired but will be empty unless provided externally.

### Events (`lib/events/`)

- `action_dispatcher.dart`
  - Role: Executes actions from component configs.
  - How it works: Interprets action dictionaries (`navigate`, `apiCall`, `updateState`, etc.) and performs side effects.
  - Limitations: Relies on correct config; no validator enforces required fields.

- `action_middleware.dart`
  - Role: Middleware pipeline for actions.
  - How it works: Allows pre/post processing of actions (e.g., analytics, permission checks).
  - Limitations: Middleware ordering and error handling need careful configuration to avoid conflicts.

- `event_bus.dart`
  - Role: Lightweight event bus.
  - How it works: Pub/sub for app-level events.
  - Limitations: No type safety; relies on conventions.

### Analytics (`lib/analytics/`)

- `models/`: Data types for tracked events and tags.
- `services/`: `AnalyticsService` to collect, tag, and flush events.
  - Limitations: Requires `backendUrl` to flush; otherwise events remain in memory (by design).
- `widgets/`: Wrappers and helpers to emit analytics during widget lifecycle.

### Documentation (`docs/`)

- `system_overview.md`: High-level system design and responsibilities.
- `canonical_framework_guide.md`: Concepts and best practices for the framework.
- `components_reference.md`: Catalog of supported components and their contract fields.
- `dsl_cheat_sheet.md`: Quick reference for the DSL used in contracts.
- `backend_frontend_communication.md`: How services and endpoints are described and consumed.
- `typesafe_contract_guide.md`: Strategies for keeping the contract type-safe.
- `analytics_system_guide.md`, `ANALYTICS_API_INTEGRATION.md`: Analytics design and backend integration.
- `framework_implementation_summary.md`: Summary of key modules; note it still references the historic validation module.
- `contract_audit_report.md`: Findings from contract audits (if populated); may reference validation.

Notes:

- The previous validation module (`lib/validation/`) and its tooling/docs were removed. Some docs still reference it historically; these will be updated incrementally.

### Tests (`test/`)

- `analytics/analytics_service_test.dart`: Verifies tagging, linking, and flush behavior of analytics events.
- `graph_engine_test.dart`: Ensures reactive graph behavior works as expected.
- `parsing_utils_test.dart`: Validates utility parsing logic.
- `widgets/component_tracker_test.dart`: Ensures component tracking emits correct analytics.
- `widgets/enhanced_page_builder_test.dart`: Validates building and lifecycle emissions for pages and components.
- `parser/`: Exists as a directory; validator-coupled parser tests were removed. Future parser-only tests can live here.
- `validation/`: Directory remains, but validator-linked tests were removed along with the module.

### Tools (`tools/`)

- Previously contained `validate_contract.dart` (CLI). It was removed alongside the validation module. The folder is kept for future utilities.

### Web (`web/`)

- `index.html`, `manifest.json`, `favicon.png`, `icons/`: PWA and web assets.
  - Limitations: These are standard Flutter web assets; customization may be needed for production branding.

## Known Limitations and Gaps

- No runtime contract validator:
  - Risks: Misconfigured components, routes, or service schemas can cause runtime errors or undefined behavior.
  - Mitigation: Add CI-time schema checks or reintroduce lightweight validation where most impactful.

- Inline field validation disabled:
  - `text_field_component.dart` does not enforce `c.validation` rules; UI error label remains but is unused unless populated externally.

- Service response schema assumptions:
  - `api_service.dart` helpers assume correct schema references. Invalid `$ref` or mismatched models will surface as runtime issues.

- Coverage report is stale:
  - `coverage/lcov.info` references removed files. Regenerate coverage after test runs.

- Historical docs:
  - Some documents (e.g., `framework_implementation_summary.md`) still mention the validation module. They are accurate historically but not reflective of current runtime.

- Internationalization and theming:
  - Text and style handling are basic. No i18n framework is integrated; theming relies on local helpers.

- Error handling and reporting:
  - Many modules rely on conventions and logs; structured error reporting may be limited.

## Status Signals and How to Check Them

- Static analysis: `flutter analyze` → should return “No issues found”.
- Tests: `flutter test` → expect all tests to pass.
- Runtime logs: Actions, analytics, and state updates log to console during tests and interactive runs.
- Environment: Configure values in `.env.example` as needed; ensure `backendUrl` for analytics flush.
- Contract shape: Keep `assets/canonical_contract.schema.json` aligned with `canonical_contract.json`; consider adding CI checks.

## Maintenance and Future Work

- Consider reintroducing lightweight validation for high-value checks (routes, action requirements, service `$ref`).
- Update remaining docs to remove or annotate validation references.
- Strengthen schema-driven tooling (pre-commit or CI) to catch contract errors early.
- Add tests for contract parsing without validator coupling (use `test/parser/`).
- Regenerate coverage and keep it part of CI artifacts.

---

This guide should be updated alongside code changes. If you remove or add modules, reflect them here to keep the status coherent and useful.