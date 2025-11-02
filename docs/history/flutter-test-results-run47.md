Project: demo_json_parser (Flutter)
# Test Results — Run 47 (2025-11-02)

- Command: `flutter test`
- Result: All tests passed
- Total: 44 tests
- Duration: ~3s

## Context
- Canonical contract updated to prevent Songs row overflow:
  - `title` and `subtitle` use `maxLines: 1` + `overflow: "ellipsis"`.
  - `durationText` uses `maxLines: 1`.
  - Trailing play `icon` size reduced from `32` to `24`.
- Backend verified serving updated contract at `/contracts/public/canonical`.
- Parser unchanged; this was a contract-only refinement.

## Output (truncated)
```
00:03 +44: All tests passed!
```