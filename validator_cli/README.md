# Contract Validator CLI

A standalone Dart CLI to validate canonical JSON contracts used by the Flutter parser framework.

## Install / Setup

This project is local-only. From the `validator_cli` directory:

- `dart pub get`

## Usage

Run against a contract (and optionally a schema):

- `dart run bin/validate_contract.dart --contract ../assets/canonical_contract.json`
- `dart run bin/validate_contract.dart --contract ../assets/canonical_contract.json --schema ../assets/canonical_contract.schema.json`

If you later publish or add an entrypoint, you can run:

- `dart run contract_validator:validate_contract --contract <path> [--schema <path>]`

## Output

- Prints warnings and errors with their JSON path and message.
- Exits with code `0` on success, `1` on validation failure, `2` for usage/file errors.

## What it validates

Rule-based checks for key areas:
- `meta`: required fields and basic types.
- `services`: baseUrl, endpoints, HTTP method, and responseSchema presence.
- `pagesUI`: pages, layouts, components, routes, and icon mapping.
- `components`: type support, structure, event actions.
- `state`: field types and persistence mode.
- `themingAccessibility`: light/dark tokens sanity.
- `validations` and `permissionsFlags`: basic structure checks.

Note: JSON Schema evaluation is not performed; when a schema is provided a warning is emitted. You can extend the validator to integrate a JSON Schema engine.

## Extend

- Add stronger validation rules in `lib/contract_validator.dart`.
- Integrate JSON Schema evaluation by plugging a schema validator library.
- Improve CLI arg parsing by adding the `args` package.