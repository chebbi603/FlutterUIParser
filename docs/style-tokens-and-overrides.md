# Style Tokens and Overrides

This document explains how component `style` can be authored in the contract and how the Flutter parser and factory resolve typography tokens and apply explicit overrides.

## Overview

- The `style` field for any component now accepts either:
  - A string token name (e.g., `"largeTitle"`) that maps to a typography preset in `themingAccessibility.typography`.
  - An object with explicit style properties (e.g., `{ "fontSize": 18, "fontWeight": "medium", "color": "#333333" }`).
- Object styles can optionally include `"use"` to reference a typography preset while still overriding specific keys.
- Resolution order:
  1. Load typography by token from `contract.themingAccessibility.typography[style.use or style as string]`.
  2. Apply explicit overrides from the `style` object. Explicit overrides always win.
  3. Resolve theme color tokens like `${theme.primary}` against the currently selected theme in `contract.themingAccessibility.tokens[theme]`.

## Supported Style Keys

- `fontSize`: number (supports numeric strings; safely parsed)
- `fontWeight`: string (e.g., `"bold"`, `"semibold"`, `"medium"`, `"regular"`)
- `color`: string (hex like `"#RRGGBB"`, or `${theme.*}` token)
- `backgroundColor`: string (hex or `${theme.*}`)
- `foregroundColor`: string (hex or `${theme.*}`)
- `textAlign`: string (`"left"`, `"center"`, `"right"`, `"justify"`)
- `width`, `height`, `maxWidth`: number
- `borderRadius`: number
- `elevation`: number
- `padding`, `margin`: number or object with `all`, `horizontal`, `vertical`, `top`, `bottom`, `left`, `right`
- `use`: string — typography token name to merge (e.g., `"largeTitle"`)

Note: Typography presets currently map `fontSize` and `fontWeight`. `lineHeight` is available in the contract’s typography, but its application to `TextStyle.height` is not implemented yet.

## Authoring Examples

### 1) Pure token style

```json
{
  "type": "text",
  "text": "Welcome",
  "style": "largeTitle"
}
```

### 2) Token with explicit override

```json
{
  "type": "text",
  "text": "Hello",
  "style": { "use": "title", "fontWeight": "bold" }
}
```

### 3) Fully explicit style object

```json
{
  "type": "text",
  "text": "Label",
  "style": {
    "fontSize": 16,
    "fontWeight": "medium",
    "color": "#333333",
    "padding": { "horizontal": 12, "vertical": 8 }
  }
}
```

### 4) Theme color tokens

```json
{
  "type": "button",
  "text": "Submit",
  "style": {
    "color": "${theme.onPrimary}",
    "backgroundColor": "${theme.primary}",
    "borderRadius": 8
  }
}
```

## Merging Behavior

- If `style` is a string: it is treated as `use` of a typography token.
- If `style` is an object:
  - If `style.use` is present, load typography values for that token.
  - Apply explicit `style` keys on top; `fontSize` and `fontWeight` override typography.
  - Resolve `${theme.*}` color tokens using the selected theme map.

## Fallbacks and Errors

- Unknown `style` token: logged once to the console; explicit overrides still apply.
- Unknown `${theme.*}` token: resolved as `null` and ignored; affected colors now fall back to platform defaults (no forced blue) unless explicit values are provided.
- Numeric fields provided as strings (e.g., `"size": "3"`): safely parsed via `ParsingUtils`; avoids runtime type errors.
- Missing or malformed `style`: ignored gracefully; defaults apply.

## Contract Requirements

- Ensure typography presets exist under `themingAccessibility.typography`:

```json
"themingAccessibility": {
  "typography": {
    "largeTitle": { "fontSize": 34, "fontWeight": "bold", "lineHeight": 1.2 },
    "title": { "fontSize": 22, "fontWeight": "semibold", "lineHeight": 1.3 }
  },
  "tokens": {
    "light": { "primary": "#0066CC", "onPrimary": "#FFFFFF", "surface": "#F7F7F7" },
    "dark": { "primary": "#66B2FF", "onPrimary": "#000000", "surface": "#111111" }
  }
}
```

## Implementation Notes

- Parser: `StyleConfig.fromJson` accepts strings and objects; strings populate `use`.
- Factory: typography token resolution merges `fontSize` and `fontWeight`; theme tokens resolved for colors.
- Numeric safety: `EnhancedComponentConfig.fromJson` uses `ParsingUtils.safeToInt`/`safeToDouble` for robust conversions.
- Page backgrounds: `EnhancedPageBuilder` resolves `${theme.*}` and named/hex/rgb colors via the factory’s token resolver and `ParsingUtils.parseColorOrNull`, ensuring pages use the same color parsing pipeline as components and avoid unintended blue fallback.

## Button Color Precedence

- Filled buttons (`CupertinoButton` with `backgroundColor`) resolve text color using this order:
  - `style.color` — primary text color key across components.
  - `style.foregroundColor` — explicit text color for filled buttons.
  - If `backgroundColor` is `${theme.primary}`, fallback to `${theme.onPrimary}` when available.
  - If `backgroundColor` is `${theme.surface}`, fallback to `${theme.onSurface}` when available.
  - Otherwise, no explicit text color is set and the platform’s default contrasting color applies.
- Text buttons use `style.color`, falling back to `${theme.primary}` when not provided.
- All `${theme.*}` tokens are resolved against the current theme and parsed via the shared color pipeline to avoid unintended blue defaults.

## Testing

- All tests pass: see `docs/flutter-test-results.md` latest entry.
- Recommended to add contract samples using `style` as string, object with `use`, and explicit overrides to validate rendering.

## Text Truncation & Overflow

- Use `maxLines` to cap text length; set to `1` for list rows and compact UI.
- Use `overflow: "ellipsis"` to indicate truncated text gracefully.
- Recommended defaults for list items:
  - Title: `maxLines: 1`, `overflow: "ellipsis"`
  - Subtitle: `maxLines: 1`, `overflow: "ellipsis"`
  - Ancillary fields (e.g., `durationText`): `maxLines: 1`
- Keep trailing icons small to avoid horizontal overflow; prefer `size: 20–24`.
- Combine padding/margin with truncation to prevent layout overflows.

### Example (Songs list row)

```json
{
  "type": "list",
  "dataSource": { "type": "static", "items": [ { "title": "Star Review", "subtitle": "By Artist", "durationText": "3:45" } ] },
  "itemBuilder": {
    "type": "row",
    "children": [
      { "type": "image", "src": "${item.thumbnail}", "style": { "width": 56, "height": 56, "borderRadius": 8 } },
      { "type": "column", "children": [
        { "type": "text", "text": "${item.title}", "style": { "maxLines": 1, "overflow": "ellipsis" } },
        { "type": "text", "text": "${item.subtitle}", "style": { "maxLines": 1, "overflow": "ellipsis" } },
        { "type": "text", "text": "${item.durationText}", "style": { "maxLines": 1 } }
      ]},
      { "type": "icon", "name": "play", "style": { "size": 24 } }
    ],
    "style": { "padding": { "horizontal": 12, "vertical": 8 }, "margin": { "bottom": 8 }, "backgroundColor": "${theme.surface}", "borderRadius": 8 }
  }
}
```

### Pitfalls

- Avoid string interpolation expressions like `${(${item.duration} % 60).toString()...}` inside contract text fields; precompute strings in data (e.g., `durationText`).
- Large trailing icons (`size >= 32`) often cause right-side overflow in constrained rows.
- Missing padding/margins can cause `RenderFlex` overflow when content is tight; add spacing.

## App Theme Mapping

- The app’s `CupertinoThemeData` is built from `contract.themingAccessibility.tokens[theme]` where `theme` is the global state key (`state.global.theme`). When `theme=system`, it maps to `light` by default.
- `primaryColor` ← `${theme.primary}`; `barBackgroundColor` ← `${theme.surface}`; `scaffoldBackgroundColor` ← `${theme.background}`; text color defaults to `${theme.onSurface}`.
- Typography presets (e.g., `body`, `title1`) feed the `CupertinoTextThemeData` weights and sizes; font weight strings are mapped to Flutter `FontWeight`.
- Default selection: `theme=light` unless user changes it via global state or OS setting.