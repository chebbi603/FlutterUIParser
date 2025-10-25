# Contract Validator Usage

This project includes a comprehensive ContractValidator for validating JSON-driven UI contracts before serving them to the Flutter app.

## Validator APIs

- Instance API:
  - `ValidationResult ContractValidator().validateContract(Map<String, dynamic> contract)`
  - Returns structured results: `errors`, `warnings`, and `stats` (pages, components, actions).

- Static compatibility API:
  - `List<String> ContractValidator.validate(Map<String, dynamic> contract)`
  - Returns a simple list of error messages for existing code that expects strings.

## What It Validates

- Required sections: `meta`, `pagesUI.pages`
- Components: type support, bindings (`${state.*}`, `${item.*}`), inline validations
- Actions: supported types, required params (e.g., `apiCall.service` and `.endpoint`)
- Services: endpoint `responseSchema` format, JSON Schema-style `type`, `properties`, `items`, `$ref` to `#/dataModels/*`
- State: scope and persistence vocabulary, field types
- Cross-references: routes to existing pages, icon mapping presence

Supported features are auto-extracted from documentation when possible (dsl_cheat_sheet.md, components_reference.md), with robust fallbacks.

## CLI Tool

Validate any contract JSON file from the command line:

```
dart run tools/validate_contract.dart <path-to-contract.json>
```

Example:

```
dart run tools/validate_contract.dart assets/canonical_contract.json
```

Output:

- "✓ Valid" or "✗ Invalid"
- Error and warning lines (with paths)
- Stats summary

## Performance Expectations

- Validates 1000 simple components under ~150ms on typical development machines.

## Testing

- Run the test suite:

```
flutter test -r expanded
```

- Includes tests for components, actions, services schemas, state, routes, and a performance check.

## Integrating in Backend

- Use the static `ContractValidator.validate` method to quickly reject malformed contracts.
- For richer reporting, use `validateContract` and return `ValidationResult` to clients.

## Notes

- The validator aims for strictness on structure and vocabulary while being pragmatic on bindings and templates.
- If documentation changes (new components/actions/validations), the doc-driven extraction will automatically expand supported sets on next run.