# Flutter App — Data Flow and Analytics Integration

This document details how the Flutter client captures UI interactions, shapes tracking events, and flushes them to the NestJS backend. It also notes where contracts and state providers connect to analytics for richer context.

## Overview

- Tech: Flutter + Dart, modularized under `lib/`.
- Focus areas:
  - Component-level tracking via a wrapper widget.
  - Central `AnalyticsService` coordinating buffering, tagging, and flushing.
  - Rich `TrackingEvent` model prepared for downstream LLM analysis.
  - Contract-aware tagging based on providers/state managers.

## Key Analytics Modules

- `lib/analytics/component_tracker.dart`
  - Wrapper widget to auto-track child interactions (e.g., tap gestures).
  - Creates `TrackingEvent` objects with component/page context and forwards them to `AnalyticsService`.
  - Intended usage: wrap interactive widgets to get tracking without manual boilerplate.

- `lib/analytics/analytics_service.dart`
  - Singleton service; in-memory buffer of events.
  - Attaches context from `ContractProvider` and `EnhancedStateManager` when available.
  - Applies local tagging (e.g., rage-click detection, thresholds, repeated failures) before flush.
  - Flushes in batches to backend (`/events` or `/events/tracking-event`), including a special branch for public-scope events.
  - Implements retry/backoff and lightweight dedup where feasible.

- `lib/analytics/tracking_event.dart`
  - Defines `TrackingEventType` enum and `TrackingEvent` class.
  - Captures: `id`, `type`, timestamp, page/component IDs, session/user IDs, and a structured `payload`.
  - Converts to an LLM-friendly format that preserves high-signal fields.

## Event Lifecycle

1. UI Interaction: User taps or interacts with a tracked widget.
2. `ComponentTracker` builds a `TrackingEvent` with granular metadata (component id/name, page id, timestamp, payload).
3. `AnalyticsService` buffers the event, enriches with contract/state context, and performs local tagging.
4. Flush:
   - Batched payload → `POST /events` with `{ userId?, events: [...] }`.
   - Single payload (fallback or immediate) → `POST /events/tracking-event`.
   - `userId` resolution mirrors backend defaults if not provided.

## Contracts and Context

- `ContractProvider` supplies active contract rules to analytics for tagging.
- `EnhancedStateManager` contributes session/page/component context useful for deducing pain points.
- Combined, they enable smart local annotations (e.g., component marked as "blocked" or "high-risk" under certain rules).

## Contracts: Backend Guarantees (2025-11-08)

- Sanitization: The backend sanitizes LLM-generated contracts before persistence and serving. Only Flutter-supported components are retained; unsupported types are dropped.
- Alias normalization: Known synonyms are normalized by the backend to the Flutter parser’s expectations:
  - `progressBar` → `progressIndicator`
  - `text_field` → `textField`
  - `list.itemTemplate` → `list.itemBuilder` (normalized recursively)
  - `searchBar.action` → `searchBar.onChanged`
  - `keyboard` → `keyboardType`, `obscure` → `obscureText`
- Scope enforcement: Public pages are excluded from generated contracts; only authenticated pages are served to the client in generation flows.
- Suppression summary: The backend prepends a suppression note to `json.meta.optimizationExplanation` describing excluded public pages, removed components, and normalizations. Clients may surface this note in diagnostics.
- Parser expectations: Client parsers remain robust — unknown types are not expected from generation flows. If encountered (e.g., legacy disk contracts), log warnings and skip rendering.

## Data Model Guarantees

- Timestamps are ISO strings for transport.
- `payload` is JSON-safe and avoids runtime types.
- IDs are strings; backend validates `ObjectId` when relevant.

## Running and Testing

- Run the app: from the project directory, execute `flutter run` (no flags). It opens automatically in an iOS simulator per workspace convention.
- Unit tests: `flutter test` exercises models, analytics, and parsing utilities under `test/`.
- Test results are tracked in `docs/flutter-test-results.md`.

## Extension Ideas

- Introduce batching strategies adaptive to network conditions.
- Capture additional gestures (long-press, drag) and navigation events for deeper funnels.
- Store local summaries and only transmit deltas to reduce bandwidth.