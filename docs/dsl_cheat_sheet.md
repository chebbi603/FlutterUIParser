# DSL Cheat Sheet

This parser implements a stable, comprehensive DSL. Author your `canonical_contract.json` to match the vocabulary below.

## Components
- Supported `type` values:
  - text, textField (alias: text_field), button, textButton, iconButton, icon, image, card, list, grid, row, column, center, hero, form, searchBar, filterChips, chip, progressIndicator, switch, slider, audio, video, webview
- Common props:
  - `text`, `label`, `placeholder`, `style`, `children`
  - `binding`: use `"${state.<key>}"` to render a state value
  - `onTap`, `onChanged`, `onSubmit`: action objects (see Actions)
- onChanged behavior:
  - Widgets forward `{'value': <newValue>}` to the action
  - `searchBar` supports optional debounce via `onChanged.debounceMs`

## Actions
- Allowed `action` values:
  - navigate, pop, openUrl, apiCall, updateState, showError, showSuccess, submitForm, refreshData, showBottomSheet, showDialog, clearCache
- `apiCall`:
  - Provide `service` and `endpoint`; `params` and the forwarded `additionalData` merge into the request body
  - `${state.<key>}` templates inside action params are resolved to current state values
- `submitForm`:
  - Collects all page state for the given form/page id (`params.formId` | `params.pageId` | `key`)
  - If `service` and `endpoint` are provided, posts the collected payload to the backend
- `updateState`:
  - Use `key` and `value` or rely on forwarded `{'value': ...}`; optional `scope: 'global'`

## State
- Structure:
  - `state.global`: map of fields
  - `state.pages`: map of pageId -> fields
- Field attributes:
  - `type`: string | number | boolean | object | array (consumer casts common types)
  - `default`: initial value
  - `persistence`: optional, one of `local`, `device`, `secure`, `session`, `memory`
    - If omitted or set to `session`/`memory`, values are not persisted across app restarts

## Services
- Define `services.<name>.baseUrl` and `endpoints.<name> { path, method }`
- The request body for POST/PUT/PATCH is built from the action-provided map
- Basic environment substitution is applied to base URL; state templates are resolved in action payloads

## Events
- `eventsActions.onAppStart|onLogin|onLogout`: arrays of action objects from the allowed set

## Validation
- The runtime validates:
  - Top-level sections are objects
  - Component `type` and action `action` values are supported
  - `state.*.persistence` is one of the allowed policies

Author contracts within these boundaries to ensure the parser behaves consistently and predictably.