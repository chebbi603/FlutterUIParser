Project: demo_json_parser (Flutter)
# Contract Audit Report

Target: `assets/canonical_contract.json`
Date: 2025-10-19

## Summary
The contract aligns with the documented DSL and framework structure. It defines `meta`, `dataModels`, `services`, `pagesUI`, `state`, `eventsActions`, `themingAccessibility`, `assets`, `validations`, `permissionsFlags`, and `pagination`. Rendering flows, component types, actions, and state bindings match the guides.

## Passes (Good)
- Components: `text`, `textField`, `button`, `textButton`, `icon`, `image`, `switch`, `slider`, `chip`, `hero`, `row`, `column`, `form` in use and documented
- Layout: `scroll`, `column`, `row`, `hero` match system overview
- Actions: uses `navigate`, `openUrl`, `showDialog`, `updateState`, `submitForm` with proper `params`
- State: `global` with bindings `${state.welcomeMessage}`; correct defaults
- Theming: tokens `${theme.primary}`, `${theme.surface}`, `${theme.onSurface}`; typography and accessibility sections present
- Permissions/flags: roles and `featureFlags` present
- Pagination: defaults, sorting, filtering provided

## Warnings & Recommendations
1. `services.demo.endpoints.listPosts.responseSchema`
   - Current: `{ "data": "array" }`
   - Recommendation: use JSON Schema style referencing the `post` model:
   ```json
   {
     "type": "object",
     "properties": {
       "data": { "type": "array", "items": { "$ref": "#/dataModels/post" } }
     },
     "required": ["data"]
   }
   ```

2. `pagesUI.bottomNavigation.items[2].icon = "doc_text"`
   - Mapping not present in `assets.icons.mapping`
   - Recommendation: add `"doc_text": "CupertinoIcons.doc_text"` to `assets.icons.mapping` or choose an existing mapped icon (e.g., `gear`).

3. `image` component uses `text` as the URL
   - Recommendation: prefer `src` or `url` for clarity; update factory if adopting the new property.

4. `validations.rules.nonEmpty` uses `notEmpty`
   - Recommendation: either use `required: true` where applicable or define a `pattern` rule:
   ```json
   { "pattern": "^.+$", "message": "Field cannot be empty" }
   ```

5. `submitForm.params.formId = "form"`
   - Ensure the form container has `id: "form"` or use `pageId: "form"` for clarity.

6. `state.global.theme`
   - Recommendation: if you want persistence across restarts, add `"persistence": "local"`.

## Optional Improvements
- Add `auth` flags to routes that require authentication
- Extend `themingAccessibility.tokens` with semantic pairs (`onPrimary`, `background`) for completeness
- Provide `indexes` in `dataModels.post` where applicable (e.g., unique title)

## Next Steps
- Patch `responseSchema` for `listPosts` (non-UI change)
- Decide on icon mapping vs. switching to an existing icon (UI change)
- Consider `image.src` adoption and update the factory accordingly (UI change)
- Adjust validations and persistence to match desired behavior

If you want, I can implement the non-UI fixes now and propose a PR-ready patch for UI changes.