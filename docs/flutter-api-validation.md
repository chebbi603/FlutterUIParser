Title: Flutter API Response Validation Guide

Overview
- The client validates API responses against the canonical contract.
- Validation supports object schemas, arrays, required fields, and data model references via `$ref`.
- String coercion accepts common ObjectId-like map shapes: `$oid`, `oid`, `id`, `value`, `string`, `hex`, `hexString`.

Optional Fields
- Object-level `required` controls presence; properties not listed are optional.
- For optional properties:
  - If a property is absent in the response, it is not validated.
  - If present but `null`, validation is skipped.
- This prevents errors like `ApiException: Field "_id" must be string` when the server does not include `_id`.

Behavior Details
- `ApiService._validateResponseSchema` validates only keys present in the response object.
- `ApiService._validateValueAgainstSchema` returns early when `value == null`.
- `_coerceStringLike` handles Mongo-style identifiers embedded in objects.

Auth Login Response
- Backend returns: `accessToken`, `refreshToken`, `userId`, `role`.
- Contract updated to include `userId` and require `accessToken`/`refreshToken`.
- Client no longer requires `_id`; if present, it is validated as a string or coercible map.

Developer Notes
- Keep contract response schemas tightly aligned with backend payloads.
- Use `required` arrays to enforce presence only for fields that must exist.
- Prefer consistent identifier keys (`userId` or `id`), and include aliases when necessary for compatibility.