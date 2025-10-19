# Enhanced Components Reference

This document lists every component type rendered by `EnhancedComponentFactory` and how to configure them via `EnhancedComponentConfig`. It also explains common patterns: binding, events, validation, styling, permissions, and theming tokens.

## Common Patterns

- **Binding**
  - `binding` to item data: inside lists/grids/cards, use a field from each item’s `boundData` (e.g., `"binding": "title"`).
  - `binding` to state: use `"${state.<key>}"` to read from global/page/session/memory state.
- **Events**
  - `onTap` and `onChanged` take `ActionConfig` and dispatch through the Enhanced Action Dispatcher.
  - `onChanged` commonly passes `{"value": ...}` to actions; supports `debounceMs` on search bars.
- **Validation**
  - Inline `validation` for fields: `required`, `email`, `minLength`, `maxLength`, `pattern`, `message`.
  - Global rules: `validations.rules` and `validations.crossField` in the contract. Cross-field example rule: `equal`.
- **Permissions**
  - `permissions: ["permA", "permB"]` shows a component if the user has any of these. Inherited role permissions are supported.
- **Themes & Tokens**
  - `style.color`, `style.backgroundColor`, `style.foregroundColor` can reference tokens like `${theme.primary}`.
  - Tokens resolve against `themingAccessibility.tokens` using the active theme (`light`, `dark`, or `system` resolved to `light` in demo).
- **Styling**
  - `style`: `fontSize`, `fontWeight` (`bold`, `w100`-`w900`), `color`, `backgroundColor`, `foregroundColor`, `textAlign` (`left`, `center`, `right`, `justify`, `start`, `end`), `width`, `height`, `maxWidth`, `borderRadius`, `elevation`, `padding`, `margin`.
- **Colors**
  - Named: `red`, `blue`, `green`, `orange`, `yellow`, `purple`, `pink`, `teal`, `indigo`, `gray/grey`, `black`, `white`, `transparent`.
  - Hex: `#RGB`, `#RRGGBB` (auto `FF` alpha), `#AARRGGBB`.
  - `rgb(r,g,b)` and `rgba(r,g,b,a)`.
- **Icons**
  - Use `icon` or `name`. If mapped in `assets.icons` to `CupertinoIcons.<name>`, that mapping wins.
  - Built-ins include: `house`, `doc_text`, `person_circle`, `gear`, `plus`, `ellipsis`, `chart_bar`, `exclamationmark_triangle`; fallback `circle`.

## Components

### Text (`type: "text"`)
- Props: `text`, `binding` (item or `${state.key}`), `maxLines`, `overflow` (`visible`, `ellipsis`, `fade`, `clip`), `style`.
- Example:
```json
{ "type": "text", "text": "Hello", "style": { "color": "${theme.onSurface}" } }
```

### Text Field (`type: "textField"` or "text_field")
- Props: `label`, `placeholder`, `keyboardType` (`number`, `email`, `phone`, `url`, `multiline`, `datetime`), `obscureText`, `maxLines`, `validation`.
- Behavior: Validates on change; dispatches `onChanged` with `{ "value": "..." }`.
- Example:
```json
{ "type": "textField", "label": "Email", "placeholder": "you@example.com", "keyboardType": "email", "validation": { "required": true, "email": true } }
```

### Button (`type: "button"`)
- Props: `text`, `style.backgroundColor`, `style.foregroundColor`, `style.borderRadius`, `style.padding`.
- Events: `onTap`.
- Example:
```json
{ "type": "button", "text": "Save", "style": { "backgroundColor": "${theme.primary}", "foregroundColor": "white" }, "onTap": { "action": "navigate", "route": "/success" } }
```

### Text Button (`type: "textButton"`)
- Props: `text`, `style.color`, `style.fontSize`, `style.fontWeight`, `style.textAlign`, `style.padding`.
- Events: `onTap`.

### Icon Button (`type: "iconButton"`)
- Props: `icon`, `size`, `style.color`.
- Events: `onTap`.

### Icon (`type: "icon"`)
- Props: `icon` or `name`, `size`, `style.color`.
- Example:
```json
{ "type": "icon", "icon": "gear", "size": 24, "style": { "color": "${theme.primary}" } }
```

### Image (`type: "image"`)
- Props: `text` as `src`, or `binding` via `boundData`; `style.width`, `style.height`.
- Example:
```json
{ "type": "image", "text": "https://example.com/banner.png", "style": { "width": 320, "height": 180 } }
```

### Card (`type: "card"`)
- Purpose: Styled container; propagates `boundData` to children.
- Props: `children`, `style.padding`, `style.backgroundColor`, `style.borderRadius`, `style.elevation`.
- Example:
```json
{ "type": "card", "style": { "padding": { "all": 16 }, "backgroundColor": "${theme.surface}" }, "children": [ { "type": "text", "binding": "title" } ] }
```

### List (`type: "list"`)
- Data: `dataSource` (`service`, `endpoint`, `params`, `listPath` default `data`).
- Rendering: `itemBuilder` is a component template; receives each item as `boundData`.
- States: Optional `loadingState`, `emptyState`, `errorState` as components.
- Example:
```json
{
  "type": "list",
  "dataSource": { "service": "products", "endpoint": "/list", "params": { "q": "phones" }, "listPath": "data.items" },
  "itemBuilder": { "type": "card", "children": [ { "type": "text", "binding": "name" }, { "type": "text", "binding": "price" } ] },
  "emptyState": { "type": "text", "text": "No items" }
}
```

### Grid (`type: "grid"`)
- Props: `children`, `columns` (default 2), `spacing`.

### Row (`type: "row"`) and Column (`type: "column"`)
- Props: `children`, `spacing`, `mainAxisAlignment` (`start`, `center`, `end`, `spaceBetween`, `spaceAround`, `spaceEvenly`), `crossAxisAlignment` (`start`, `center`, `end`, `stretch`, `baseline`).

### Center (`type: "center"`)
- Behavior: Centers first child of `children`.

### Hero (`type: "hero"`)
- Props: `children`, `style.padding`, `style.backgroundColor`, `style.borderRadius`.

### Form (`type: "form"`)
- Purpose: Visual container for inputs; children render inside.
- Props: `children`, `style.padding`, `style.backgroundColor`, `style.borderRadius`.
- Submission: Use an action (e.g., a button with `onTap: { "action": "submitForm" }`) to collect state and optionally call an API.

### Search Bar (`type: "searchBar"`)
- Props: `placeholder`.
- Behavior: Calls `onChanged` with `{ "value": ... }`. Supports `debounceMs` on the action.

### Filter Chips (`type: "filterChips"`)
- Note: Placeholder UI; selection logic not implemented.

### Chip (`type: "chip"`)
- Props: `text`, `style.backgroundColor`, `style.foregroundColor`.

### Progress Indicator (`type: "progressIndicator"`)
- Renders: `CupertinoActivityIndicator`.

### Switch (`type: "switch"`)
- State: Reads key from `binding` (supports `${state.key}`) or `onChanged.params.key`.
- Behavior: Reads current value; on change, dispatches `onChanged` and persists to state.
- Example:
```json
{ "type": "switch", "binding": "${state.notificationsEnabled}", "onChanged": { "action": "updateState", "params": { "key": "notificationsEnabled" } } }
```

### Slider (`type: "slider"`)
- State: Same binding logic as `switch`.
- Behavior: Numeric/string values parsed and clamped to `[0.0, 1.0]`; updates state on change.
- Example:
```json
{ "type": "slider", "binding": "${state.volume}", "onChanged": { "action": "updateState", "params": { "key": "volume" } } }
```

### Audio (`type: "audio"`)
- Props: `text` as source URL.

### Video (`type: "video"`)
- Props: `text` as source URL.

### WebView (`type: "webview"`)
- Props: `text` as URL; `style.height` (default 300).

## Actions Overview

Supported actions include:
- `navigate`, `pop`, `openUrl`, `apiCall` (with `service`, `endpoint`, `data`),
- `updateState` (`key`, `value`, `scope`), `showError`, `showSuccess`,
- `submitForm`, `refreshData`, `showBottomSheet`, `showDialog`, `clearCache`.
Many support nested `onSuccess`/`onError` and template variables `${state.<key>}` in params.

## Permissions Overview

- Role permissions can inherit from other roles; visibility check uses "has any" of the component’s `permissions`.
- Feature flags support global enable, rollout percentage (simplified in demo), and `targetRoles`.

## See Also

- `docs/system_overview.md` — Rendering flow and architecture
- `docs/dsl_cheat_sheet.md` — Quick syntax guide for config JSON
- `lib/models/config_models.dart` — Strongly typed config models
- `lib/widgets/component_factory.dart` — Rendering implementation
- `lib/utils/parsing_utils.dart` — Parsing helpers (colors, keyboard types, icons)