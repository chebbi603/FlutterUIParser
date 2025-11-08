Project: demo_json_parser (Flutter)
# Test Results — Run 80 (2025-11-08)

## Command
`flutter test`

## Result
- Status: All tests passed
- Total: 48 tests
- Duration: ~3–4s

## Context
- Fixed startup JSON decoding by replacing undefined `ParsingUtils.tryDecodeJson` with `dart:convert` `jsonDecode` and adding the import in `lib/app.dart`.
- Applies when reading persisted `state:global:user` values stored as JSON strings.

## Output (truncated)
```
00:03 +48: All tests passed!
[diag][page] enter id=home layout=scroll components=1 bg=#FFFFFF
```