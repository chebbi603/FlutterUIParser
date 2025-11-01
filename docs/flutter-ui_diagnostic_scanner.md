Project: demo_json_parser (Flutter)
# UI Diagnostic Scanner

This document describes the UI Diagnostic Scanner added to the app. The scanner inspects the loaded UI contract and rendering pipeline to surface potential issues early, with structured logs suitable for debugging and CI diagnostics.

## Overview
- Location: `lib/diagnostics/ui_scanner.dart`
- Invocation (debug-only):
  - After contract application in `lib/app.dart` (`MyApp._applyUpdatedContract`) via `assert(() { ...; return true; }());`
  - After component factory initialization in `lib/widgets/component_factory.dart` (once a contract is available)
- Output: Printed to console with clear section headers and JSON snippets under `assert` (debug builds only)
- Scope: Contract schema and component render wiring; does not modify runtime behavior

## What It Checks
- Unrecognized component types: Components whose `type` is not supported by the factory
- Unresolved bindings:
  - Theme tokens that cannot be resolved (color/background/foreground tokens)
  - State bindings that cannot be resolved via `EnhancedStateManager.getState(path)`
- Page diagnostics:
  - Pages missing backgrounds or background bindings
  - Page background tokens resolved consistently with components; unresolved tokens are logged once with `[diag][page]` context
  - Empty pages and component counts per page
- Static list pagination:
  - Heuristics for overly long static lists lacking pagination or virtualization hints
- Theme references:
  - Cross-check of design tokens referenced by components versus those defined in the contract’s theme section

## Sample Output (truncated)
```
=== UI Diagnostic Scanner Report ===
source: canonical
version: 1.0.0

[critical]
- unrecognized_component_types: [ { page: "landing", id: "heroX", type: "unknown" } ]
- unresolved_state_bindings: [ { page: "home", component: "title1", path: "user.name" } ]

[warnings]
- missing_page_backgrounds: [ "podcasts" ]
- unresolved_theme_tokens: [ { page: "ebooks", component: "card1", token: "color.primary900" } ]
```

## How It Runs
1. On contract update, `MyApp` applies the new contract and then calls the scanner inside a debug-only `assert` block.
2. When the `EnhancedComponentFactory` initializes with the active contract, a debug-only scanner pass runs again to catch rendering-level issues.
3. `EnhancedPageBuilder` emits per-page debug logs that complement the scanner (component counts, background presence, binding checks).

## Enabling and Controlling Output
- Debug builds only: Scanner runs inside `assert(...)` gates; no output in release/profile.
- To see detailed logs:
  - Run `flutter run` and observe console output
  - Use Flutter DevTools to view logs in the `Logging` tab
- No configuration flags are required. The scanner is safe to leave enabled in debug builds.

## Notes and Limitations
- The scanner does not mutate state or contract data; it only reports diagnostics.
- Some checks use heuristics (e.g., static list pagination). Treat warnings as guidance.
- If the contract fails to load or an exception occurs during boot, scanner output may be truncated or absent. Fix boot errors first.

## Maintenance
- Extend `UIDiagnosticScanner` with new rules as the design system evolves.
- Keep component factory and page builder logs consistent: use `[diag]` prefixes and succinct context payloads.