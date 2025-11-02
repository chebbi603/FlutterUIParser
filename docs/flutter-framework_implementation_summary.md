Project: demo_json_parser (Flutter)
# Framework Implementation Summary

This document summarizes key implementation details, algorithms, and file references across the canonical JSON-driven framework.

> See also: [Contract Validator Usage](contract_validator_usage.md) for validation APIs, scope, and CLI.

## Component Factory & Memoization

- File: `lib/widgets/component_factory.dart`
- Uses `_componentCache: Map<int, Widget>` to memoize pure components for reuse.
- `_createChip(EnhancedComponentConfig)` caches chips only when there’s no `binding`, `onTap`, or `onChanged` (i.e., pure visual chips).
- `_hashChipConfig(config)` computes a stable hash that ignores volatile fields; the built widget is stored under that hash in `_componentCache`.
- `createComponent` resolves theme tokens, validates permissions, and delegates to specific `_create*` methods per component type.

## Grid & ItemBuilder

- File: `lib/widgets/component_factory.dart`
- Behavior:
  - Supports two modes:
    - Static children grid: renders `children` directly.
    - Static data grid: when `dataSource.type` is `static` (or `dataSource.items` provided) and `itemBuilder` is set, it maps `items` to widgets using `itemBuilder`.
  - Template tokens inside `itemBuilder` (e.g., `${item.title}`, `${item.imageUrl}`) are resolved by the respective component builders (`TextComponent`, `ImageComponent`) using `config.boundData` passed from the grid.
  - Layout: uses `GridView.count` with `columns` mapped to `crossAxisCount` and `spacing` applied as both `crossAxisSpacing` and `mainAxisSpacing`.
- Limitations:
  - Only static data is supported for grids at present; remote/dynamic fetching and pagination are not implemented in Flutter.

## Graph Engine

- File: `lib/engine/graph_engine.dart`
- Implements a lightweight DAG with `NodeType` (`component`, `state`, `dataSource`, `action`) and `GraphNode`.
- `subscribe(sourceNodeId, componentId)` registers nodes, adds a dependency edge, and provisions a `ValueNotifier<int>` ticker for component rebuilds.
- Visibility-aware notifications: `setComponentVisible(id, true|false)` ensures only visible components are ticked.
- Change propagation:
  - `notifyStateChange(stateKeyPath)` and `notifyDataSourceChange(dataSourceId)` compute a topological order from the source and tick each visible component’s notifier.
  - Also calls `notifyListeners()` for global subscribers.
- Cycle detection via DFS in `_hasCycle()` rejects edges that would introduce cycles.

## Graph Subscriber

- File: `lib/widgets/graph_subscriber.dart`
- Wraps component builds and rebuilds using `ValueListenableBuilder` bound to the component’s ticker.
- Subscribes to declared `dependencies` in `initState`, marks the component visible in `didChangeDependencies`, and cleans up (`unsubscribe`, visibility reset) in `dispose`.

## State Manager

- File: `lib/state/state_manager.dart`
- Manages `global`, `page`, `session`, and `memory` scopes with optional persistence per field (`local` via shared prefs, `secure` via secure storage).
- Notifies `GraphEngine` on updates (e.g., `GraphEngine().notifyStateChange(key)`), triggering reactive rebuilds of subscribed components.
- Tracks undo/redo history per state path; writes persisted values based on configured policies.

## Action Dispatcher & Middleware

- File: `lib/events/action_dispatcher.dart`
- Central entry: `EnhancedActionDispatcher.execute(context, action, additionalData?)` supports actions: `navigate`, `pop`, `openUrl`, `apiCall`, `updateState`, `showError`, `showSuccess`, `submitForm`, `refreshData`, `showBottomSheet`, `showDialog`, `clearCache`.
- Middleware pipeline (`ActionMiddlewarePipeline`) allows hooks: `before`, `after`, `onError`.
- Emits lifecycle events via `EventBus` (`ActionStarted`, `ActionCompleted`, `ActionFailed`).
- Navigation uses `NavigationBridge` and `Navigator` for route changes.
- API calls merge `action.params` with forwarded `additionalData` (e.g., `{'value': newValue}` from `onChanged`), resolve `${state.<key>}` templates, support optimistic updates with rollback on failures.
- `clearCache` delegates to `_apiService.clearCache()`.

## API Service

- File: `lib/services/api_service.dart`
- Request deduplication via `_pending: Map<String, Future<ApiResponse<dynamic>>>` keyed by a dedup key; late joiners await the original future.
- Response caching via `_cache: Map<String, CachedResponse>` with TTL:
  - `_getFromCache(url)` returns non-expired entries and removes expired ones.
  - `_cacheResponse(url, data, headers, ttlSeconds)` stores with expiry.
  - `clearCache()` and `clearExpiredCache()` housekeeping helpers.
- Retry policy with configurable `maxAttempts` and `backoffMs` (exponential backoff).
- Response validation using JSON Schema-style checks (`type`, `properties`, `required`, `$ref` to `dataModels`).
- Query parameter validation for type, min/max values, minLength, and enum membership.
- `PaginatedResponse` and `ContractApiService` provide higher-level contract-driven workflows.

## Persistence

- File: `lib/persistence/state_persistence.dart`
- `SharedPrefsPersistence`: Stores primitives directly; uses `jsonEncode` for other objects. Supports prefix `readAll` and `clearAll`.
- `SecureStoragePersistence`: Stores strings; retrieves via `jsonDecode` with fallbacks to infer booleans/ints/doubles when decoding fails. Also supports prefix operations.

## Validation

- File: `lib/validation/validator.dart`
- `EnhancedValidator` methods:
  - `validateField(fieldId, value, rules)` for `required`, `email`, `minLength`, `maxLength`, `pattern`.
  - `validateWithRule(ruleName, value)` referencing `ValidationsConfig`.
  - `validateCrossField(fieldA, fieldB, rule)` for relational checks (equality, etc.).
  - `validateForm(formConfig)` to validate an entire form definition.
- `lib/validation/contract_validator.dart` validates overall contract structure and recognizes allowed actions (includes `clearCache`).

## Component Registry

- File: `lib/widgets/component_registry.dart`
- `ComponentRegistry.get(type)` returns `ComponentMetadata` with `requiredProps` and `defaults`.
- `validate(config)` returns missing required props for early feedback on component configuration.

## Component Behaviors

- `lib/widgets/components/icon_component.dart`: Renders icons and icon buttons; dispatches actions on press. Icon resolution via `ParsingUtils.parseIcon(config.icon ?? config.name ?? 'circle')` with sensible defaults.
- `lib/widgets/components/button_component.dart`: `CupertinoButton` that dispatches actions on `onPressed`; styling via `ComponentStyleUtils` and `ParsingUtils`.
- `lib/widgets/components/text_field_component.dart`: Subscribes to bound state via `GraphSubscriber`, updates `EnhancedStateManager`, validates with `EnhancedValidator`, and forwards `{'value': newValue}` on changes.
- `lib/widgets/components/switch_component.dart`: Normalizes current value across types, dispatches `onChanged`, and updates bound state; rebuilds via `GraphSubscriber`.
- `lib/widgets/components/slider_component.dart`: Subscribes to state, clamps value between `0.0` and `1.0`, dispatches `onChanged`, and updates state.
- `lib/widgets/components/text_component.dart`: Displays text from direct `text`, data `binding`, or `${state.*}`; rebuilds via `GraphSubscriber` and applies `ComponentStyleUtils`.

## Docs & DSL References

- `docs/dsl_cheat_sheet.md`: Supported components and actions, binding semantics, `onChanged` value forwarding and debounce.
- `docs/canonical_framework_guide.md`: End-to-end guide covering contract, UI system, state, services, performance, security, accessibility, testing.
- `docs/components_reference.md`: Component-specific props and behavior; links to implementation files.
- `README.md`: Project overview, directory layout, quick start, theming, and examples.

## Notable Patterns

- Caching/memoization: Pure visual components (e.g., `chip`) are cached in `_componentCache`; API responses cache with TTL.
- Visibility-aware rendering: `GraphEngine` only ticks visible components to reduce unnecessary rebuilds.
- Template resolution: Actions can embed `${state.<key>}` in params; resolved at dispatch time.
- Optimistic updates: Supported in API calls with rollback on failure for resilient UX.
## Analytics & Contract Logging Updates (2025-11-01)

- Analytics (`lib/analytics/services/analytics_service.dart`):
  - Adds `pageScope` classification (`public` | `authenticated`) derived from contract routes or heuristics (login/signup flows).
  - Enriches event payloads with `contractType`, `contractVersion`, and `isPersonalized` during `flush()`.
- Contract Service (`lib/services/contract_service.dart`):
  - Logs concise summaries on successful fetches (source, version, page/route counts).
  - Detects merge metadata (`mergeMetadata`, `isPartial`, `mergedPages`) and prints counts; `verboseMergeLogging` shows page IDs in debug builds.

## Parser Enhancements (2025-11-02)

- DataModel field parsing now supports flexible shorthand inputs:
  - Map entries: `{ "name": "id", "type": "string" }` or `{ "id": { "type": "string" } }`.
  - Bare field names in lists: `["title", "description"]` become `string` fields by default.
  - `name:type` list entries: `["priority:string", "rating:number"]`.
  - Enum shorthand lists: `["pending", "done"]` parsed as `type=string`, `enum=[...]`.
- Relationships accept string shorthand for model names (defaults to `hasOne`) or detailed maps.
- Index definitions accept string shorthand (e.g., `"unique:id"`, `"status"`) or detailed maps.
- Type normalization recognizes synonyms: `int/integer`, `bool/boolean`, `map/object`, `list/array`, `float/double -> number`.
- Defensive parsing and sensible defaults reduce the chances of type errors when contracts use compact forms.