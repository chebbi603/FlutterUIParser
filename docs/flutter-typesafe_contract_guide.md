Project: demo_json_parser (Flutter)
# Typesafe Canonical Contract Authoring Guide

This guide explains how to author a robust, typesafe JSON contract that drives your Flutter UI, services, state, actions, theming, and permissions. It consolidates conventions from the DSL cheat sheet and the canonical framework guide into one practical reference.

## Design Principles
- Single source of truth: one contract governs UI, services, state, validation, and permissions
- Type safety: use strict enums and structured schemas; avoid ambiguous shapes
- Extensibility: prefer composable primitives and optional sections over hardcoded behaviors
- Validation-first: include schemas and rules; validate contracts in CI

## Top-Level Structure
```jsonc
{
  "meta": { /* app info */ },
  "dataModels": { /* domain models */ },
  "services": { /* API definitions */ },
  "pagesUI": { /* routes, navigation, and pages */ },
  "state": { /* default values and persistence */ },
  "eventsActions": { /* lifecycle and custom events */ },
  "themingAccessibility": { /* tokens, typography, accessibility */ },
  "assets": { /* icons, images, fonts */ },
  "validations": { /* rules and cross-field logic */ },
  "permissionsFlags": { /* roles and feature flags */ },
  "pagination": { /* defaults for lists */ }
}
```

### `meta`
- `appName` (string), `version` (semver), `schemaVersion` (semver), `generatedAt` (ISO-8601)
- `authors` (string[]), optional `description` (string)

### `dataModels`
- Map of model → `{ fields, relationships?, indexes? }`
- Field: `{ type: "string"|"number"|"integer"|"boolean"|"datetime"|"object"|"array", required?: boolean, primaryKey?: boolean, enum?: any[] }`
- Relationship: `{ type: "hasOne"|"hasMany", model: "ModelName", foreignKey: "field" }`
- Index: `{ fields: ["field"], unique?: boolean }`

### `services`
- Service: `{ baseUrl: string|template, endpoints: { [name]: Endpoint } }`
- Endpoint: `{ path: string, method: "GET"|"POST"|"PUT"|"PATCH"|"DELETE", auth?: boolean, requestSchema?: JSONSchema, responseSchema?: JSONSchema, caching?: { enabled: boolean }, retryPolicy?: { maxAttempts: integer, backoffMs: integer } }`
- Prefer JSON Schema for request/response; use `$ref` to `#/dataModels/<ModelName>` where applicable

### `pagesUI`
- `routes`: `{ "/": { pageId }, ... }` with optional `auth` and route params
- `bottomNavigation`: `{ enabled, initialIndex?, items: [{ pageId, title, icon }] }`
- `pages`: map of page → `Page`
- Page: `{ id, title, layout: "scroll"|"column"|"row"|"center"|"grid"|"list"|"hero", navigationBar?: { title }, children: Component[] }`

### `state`
- `global`: key-value defaults; each field `{ type, default?, persistence? }`
- `pages`: map of pageId → key-value defaults
- `persistence`: enum `"memory"|"session"|"local"|"secure"`

### `eventsActions`
- `onAppStart|onLogin|onLogout`: arrays of `Action`

### `themingAccessibility`
- `tokens`: theme colors (light/dark) with semantic names
- `typography`: named text styles
- `accessibility`: touch targets, contrast, voice over, dynamic type, reduce motion

### `assets`
- `icons.mapping`: map of icon name → platform icon identifier (e.g., `CupertinoIcons.house`)
- Optional `images`, `fonts`, `lazyLoading`

### `validations`
- `rules`: declarative field-level rules
- `crossField`: multi-field constraints (e.g., password confirmation)

### `permissionsFlags`
- `roles`: named roles with `permissions[]` and optional `inherits[]`
- `featureFlags`: switches with rollout and targeting

### `pagination`
- `defaults`: page size, params, limits; `sorting` and `filtering` optional

## Component System

### Supported Component Types
- Layout: `row`, `column`, `flex`, `stack`, `center`, `scroll`, `grid`, `hero`, `list`, `card`
- Input: `textField`, `button`, `textButton`, `iconButton`, `switch`, `slider`, `searchBar`, `dropdown`, `segmentedControl`
- Display: `text`, `icon`, `image`, `chip`, `progressIndicator`
- Media: `audio`, `video`, `webview`

### Common Properties
- `id`: unique identifier in the page scope
- `type`: one of the supported types
- `text|label|placeholder`: user-visible strings
- `style`: see Styling below
- `children`: for container/layout components
- `binding`: path for data/state binding (e.g., `${state.user.name}`)
- `permissions`: array of required permission keys
- Events: `onTap`, `onChanged`, `onSubmit` each an `Action`

### Styling
- `padding`: number or object with `{ all|horizontal|vertical|left|top|right|bottom }`
- `margin`: number (or per-edge if supported)
- `backgroundColor`, `color`, `borderColor`, `borderWidth`, `borderRadius`
- `opacity`, `alignment`, `width`, `height`, `elevation`
- Prefer theme tokens: `${theme.primary}`, `${theme.surface}`

## Actions

### Allowed `action` values
- `navigate`, `pop`, `openUrl`, `apiCall`, `updateState`, `showError`, `showSuccess`, `submitForm`, `refreshData`, `showBottomSheet`, `showDialog`, `clearCache`

### Action Shapes
- `navigate`: `{ route: string, params?: object }`
- `apiCall`: `{ service: string, endpoint: string, params?: object, onSuccess?: Action, onError?: Action }`
- `updateState`: `{ key: string, value?: any }` or rely on forwarded `{ "value": ... }`
- `submitForm`: `{ formId?: string, pageId?: string }`
- Template resolution: `${state.<key>}` and `${theme.<token>}` are replaced at runtime

## Validation
- Field-level: `{ required?: true, email?: true, minLength?: number, maxLength?: number, pattern?: string, message?: string }`
- Cross-field: `{ ruleId: { fields: ["a","b"], rule: "equal"|"notEqual"|..., message } }`
- Service schemas: use JSON Schema for `requestSchema` and `responseSchema`

## Permissions & Feature Flags
- Roles example:
```json
{
  "permissionsFlags": {
    "roles": {
      "user": { "permissions": ["posts.read"] },
      "admin": { "inherits": ["user"], "permissions": ["posts.create","posts.delete"] }
    },
    "featureFlags": { "newDashboard": { "enabled": true, "rolloutPercentage": 50, "targetRoles": ["admin"] } }
  }
}
```

## Authoring Workflow
1. Start from the schema (see `assets/canonical_contract.schema.json`) and your components DSL
2. Define `meta`, then `pagesUI` routes/pages; keep layouts shallow
3. Add `state` defaults for UI bindings; choose appropriate `persistence`
4. Define `services` and schemas; prefer `$ref` to `dataModels`
5. Add `validations` and permissions; wire events/actions
6. Use theme tokens consistently; avoid raw hex except in tokens
7. Validate locally and in CI; load the app and smoke test

## Best Practices
- Increment `schemaVersion` on breaking changes; keep `version` for release level
- Provide defaults for user-facing state to avoid null rendering
- Use enums for component types, action types, persistence, and layout
- Prefer composable layouts (`flex`/`row`/`column`) over deep nesting
- Keep routes stable; avoid renaming page IDs unless migrating state
- Avoid business logic in components; prefer actions and services

## Common Mistakes
- Inconsistent property names (`image.text` instead of `image.src`)
- Ambiguous response schemas (e.g., `{ "data": "array" }` instead of a JSON Schema)
- Missing icon mappings for navigation or `icon` components
- Unpersisted critical state (theme, auth) causing resets on restart

## Example: Service Response Schema
```json
{
  "services": {
    "demo": {
      "baseUrl": "https://api.example.com",
      "endpoints": {
        "listPosts": {
          "path": "/posts",
          "method": "GET",
          "responseSchema": {
            "type": "object",
            "properties": {
              "data": { "type": "array", "items": { "$ref": "#/dataModels/post" } }
            },
            "required": ["data"]
          }
        }
      }
    }
  }
}
```

## Example: Page Layout
```json
{
  "pagesUI": {
    "pages": {
      "home": {
        "id": "home",
        "title": "Home",
        "layout": "scroll",
        "navigationBar": { "title": "Demo Home" },
        "children": [
          { "type": "text", "text": "Welcome" },
          { "type": "button", "text": "Go", "onTap": { "action": "navigate", "route": "/profile" } }
        ]
      }
    }
  }
}
```

## CI Validation Tips
- Validate JSON schema with a CLI (e.g., Ajv) or Dart JSON schema validator
- Add unit tests for critical pages/state keys
- Run contract validator as part of pre-commit and CI

---
This guide is designed to be living documentation. Extend it as your DSL evolves, and keep schema and examples in sync with the implementation.

## Contract Result Wrapper

- Path: `lib/models/contract_result.dart`
- Purpose: Provide a typed wrapper for a contract payload with metadata describing origin and version for analytics and state management.
- Types:
  - `ContractSource` enum with values `canonical` and `personalized` (serializes to lowercase via `toString()`).
  - `ContractResult` immutable model: `{ contract: Map<String,dynamic>, source: ContractSource, version: String, userId?: String }`.
- Helpers:
  - `isCanonical`, `isPersonalized` getters.
  - `copyWith` for immutable updates.
  - `factory ContractResult.fromBackendResponse(Map)` extracts `json` payload and common metadata keys: `source`, `version`, `userId` (supports `meta`, `metadata`, and inline fields).
  - `toJson()` for logging/debug and analytics serialization.
- Usage example:
```dart
final result = ContractResult.fromBackendResponse(responseMap);
if (result.isPersonalized) {
  analytics.track('contract_loaded', result.toJson());
}
```