Project: demo_json_parser (Flutter)
# Test Results — Run 79 (2025-11-08)

## Command
`flutter test`

## Result
- Status: All tests passed
- Total: 48 tests
- Duration: ~3–4s

## Context
- Changed app startup flow to load the personalized user contract first when persisted `authToken` and `user.id` are available; falls back to canonical when absent or on error.
- Boot logic reads persisted values from secure storage and shared preferences (`state:global:authToken`, `state:global:user`).
- Ensures that the user contract is parsed and applied as the main contract on boot for logged-in users.

## Output (truncated)
```
00:03 +48: All tests passed!
[diag][page] enter id=home layout=scroll components=3 bg=-
📊 Tracked: pageEnter (component=null, page=home, scope=public, ...)
```