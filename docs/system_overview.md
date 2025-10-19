# System Overview

This project is a JSON‑driven UI Kit built on Flutter’s Cupertino widgets. It renders screens from a JSON config without hardcoding widget trees, making it fast to iterate on UI and layout.

## Architecture

- `assets/config.json`: The UI definition. Describes page layout, navigation bar, and a tree of components.
- `lib/models/config_models.dart`: Data models:
  - `PageConfig`: page type, layout, navigation bar, children.
  - `NavigationBarConfig`: title.
  - `ComponentConfig`: a single UI element with content, behavior, and style.
- `lib/widgets/page_builder.dart`: Loads a `PageConfig` and builds the page using `ComponentFactory.createComponent`.
- `lib/widgets/component_factory.dart`: Maps `ComponentConfig.type` to concrete Flutter widgets and applies styling.
- `lib/utils/parsing_utils.dart`: Helpers to parse colors, alignments, text align, keyboard types, edge insets, and icons.

## Rendering Flow

1. Load `assets/config.json`.
2. Parse into `PageConfig` and nested `ComponentConfig` trees.
3. `PageBuilder` chooses a layout (scroll, list, column, etc.).
4. For each node, `ComponentFactory.createComponent` builds the widget and wraps it in the style container.

## Supported Components

- Content: `text`, `card`, `list_item`/`list_tile`, `divider`, `spacer`
- Inputs: `textfield`/`text_field`, `button`, `switch`, `slider`, `segmented_control`, `dropdown`
- Layout: `container`, `row`, `column`, `flex`, `stack`
- Aliases: `text_field` → `textfield`, `list_tile` → `list_item`

## Layout System

- `row` and `column`: Basic linear layouts. Support `spacing`, `mainAxisAlignment`, `crossAxisAlignment`.
- `flex`: General layout with:
  - `direction`: `row` or `column`
  - `spacing`: inserts `SizedBox` between children
  - `wrap`: uses `Wrap` with `spacing`/`runSpacing`
  - `scrollable`: wraps with `SingleChildScrollView`
  - `mainAxisAlignment`, `crossAxisAlignment`
- `stack`: Stacks children. Current version does not position children; see pain points.

## Styling (UI Kit)

Every component can specify style fields interpreted in a Flutter‑native way by `_withStyle`:

- `padding`: object or number (supports `left`, `top`, `right`, `bottom`, `all`, `horizontal`, `vertical`)
- `margin`: number (applied via outer `Padding`)
- `backgroundColor`
- `borderColor`, `borderWidth`, `borderRadius`
- `shadowColor`, `elevation` (adds `BoxShadow`)
- `opacity`
- `alignment`
- `width`, `height`

These map to `Container`, `BoxDecoration`, `Padding`, `Opacity`, and `Align`, which is idiomatic in Flutter.

## Interaction

- Local state for interactive controls via `StatefulBuilder`:
  - `switch`: toggles update immediately
  - `slider`: thumb/value update on drag
  - `segmented_control`: `groupValue` updates on tap
  - `dropdown`: opens `CupertinoPicker` in a modal and updates selection
- Dropdown config supports either `options`/`selectedValue` or `items`/`selectedItem`.

If you need persistence or side effects, wire `onChanged` to your app state and add IDs/events to `ComponentConfig`.

## JSON Examples

### Flex Row with Spacing

```json
{
  "type": "flex",
  "direction": "row",
  "spacing": 8,
  "children": [
    { "type": "button", "text": "A" },
    { "type": "button", "text": "B" }
  ]
}
```

### Styled Container (CSS‑like)

```json
{
  "type": "container",
  "padding": { "all": 12 },
  "margin": 8,
  "backgroundColor": "#F7F7F7",
  "borderColor": "#E5E5EA",
  "borderWidth": 1,
  "borderRadius": 12,
  "children": [ { "type": "text", "text": "Hello" } ]
}
```

### Dropdown Config Compatibility

```json
{ "type": "dropdown", "label": "Choose", "items": ["A","B","C"], "selectedItem": "B" }
```

or

```json
{ "type": "dropdown", "label": "Choose", "options": ["A","B","C"], "selectedValue": "B" }
```

## Strengths

- Flutter‑native styling and layout; no custom rendering hacks
- JSON‑driven UI enables fast iteration without changing code
- Consistent style wrapper simplifies padding/margin/background/border/shadow across components
- `flex` handles common row/column + spacing, wrap, and scroll cases
- Interactive controls feel responsive out of the box
- Aliases improve compatibility with different JSON schemas

## Pain Points / Limitations

- Local state is ephemeral; values are not persisted or propagated to a global state/store
- No built‑in form validation, submission, or error states
- Theming (light/dark, brand colors) is basic; no global theme config yet
- `stack` lacks child positioning (`Positioned` from JSON not supported yet)
- Limited icon set; `ParsingUtils.parseIcon` maps a small subset
- Color parsing is permissive but defaults may surprise (e.g., unnamed → blue)
- `margin` currently supports a single number; per‑edge margins not implemented
- Performance can degrade with very large trees using many `StatefulBuilder`s
- Accessibility/semantics not explicitly modeled in the JSON

## Extending the System

1. Add new types in `ComponentFactory.createComponent` and implement a builder method.
2. Extend `ComponentConfig` and update `fromJson` to parse new properties.
3. Use `_withStyle` so styling remains consistent.
4. Consider adding `id` and `onChanged`/`events` if the component is interactive.

## Development Tips

- Use hot reload while editing `assets/config.json`.
- Keep layouts shallow where possible; prefer `flex` with `spacing` over many nested containers.
- If adding persistence, centralize state in a provider or BLoC and pass callbacks to builders.