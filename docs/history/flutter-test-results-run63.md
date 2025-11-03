Project: demo_json_parser (Flutter)

Run 63 — Optional field validation for response properties

- Date: 2025-11-03
- Command: `flutter test`
- Outcome: All tests passed
- Total: 45 tests
- Duration: ~3s

Highlights
- Updated API response validation:
  - Only validates properties present in the response object.
  - Skips null values for optional fields in `_validateValueAgainstSchema`.
  - Avoids `ApiException: Field "_id" must be string` when `_id` is not returned by `/auth/login`.
- Contract alignment:
  - Backend canonical contract `AuthService.login` now includes `userId` and marks `accessToken`/`refreshToken` as required.

Selected Logs (truncated)
```
00:03 +45: All tests passed!
```