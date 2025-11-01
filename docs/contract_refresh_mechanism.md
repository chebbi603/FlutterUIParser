Project: demo_json_parser (Flutter)
# Contract Refresh Mechanism

This document describes the Contract Refresh feature added to the app, including provider-based state management, UI integration for pull-to-refresh, and runtime update behavior.

## Overview
- Pattern: `ChangeNotifier` with `Provider` integration
- Provider: `lib/providers/contract_provider.dart`
- UI integration: Pull-to-refresh via `CupertinoSliverRefreshControl` and an error/disabled banner
- Boot flow: `lib/main.dart` wraps the app with `ChangeNotifierProvider` and kicks off the initial load

## Provider Design
**File**: `lib/providers/contract_provider.dart`
- Private state:
  - `Map<String, dynamic>? _contract`
  - `bool _loading = false`
  - `String? _error`
- Public getters:
  - `Map<String, dynamic>? get contractMap`
  - `CanonicalContract? get contract`
  - `bool get loading`
  - `String? get error`
  - `bool get canRefresh`: Heuristic to enable refresh only when a plausible backend URL exists and a refresh isn’t currently running.
- Methods:
  - `Future<void> loadContract()`: Fetches the canonical contract with loading/error state and `notifyListeners()` for reactive updates.
  - `Future<void> refresh()`: Calls `loadContract()` to reuse the same logic for pull-to-refresh.

## Boot and Provider Wiring
**File**: `lib/main.dart`
- Resolves `API_URL` (defaults to `http://localhost:8081`; uses `10.0.2.2` for Android emulator).
- Fetches the canonical contract once via `ContractService` before boot.
- Wraps `MyApp` with `ChangeNotifierProvider<ContractProvider>`:
  ```dart
  runApp(
    ChangeNotifierProvider<ContractProvider>(
      create: (_) {
        final provider = ContractProvider(service: contractService);
        provider.loadContract();
        return provider;
      },
      child: MyApp(initialContractMap: contractMap),
    ),
  );
  ```

## UI Integration (Pull-to-Refresh)
**File**: `lib/app.dart`
- The main screen and tabs are wrapped with a refresh-enabled `CustomScrollView`:
  ```dart
  CupertinoSliverRefreshControl(
    onRefresh: provider.canRefresh
      ? () => Provider.of<ContractProvider>(context, listen: false).refresh()
      : null,
  )
  ```
- Error banner: displayed when `provider.error` is non-null with a `Retry` button that invokes `provider.refresh()`.
- Disabled banner: shown when `!provider.canRefresh` (e.g., offline or no backend URL) to prevent confusing behavior.

## Contract Update Flow
- `MyApp` listens to provider changes. When a refreshed contract differs by version, `MyApp` applies the updated contract immediately without restart.
- Background polling and optional update dialog are handled via `ContractLoader` (user can accept or defer updates).

## Success Metrics
- Pull-to-refresh triggers contract reload from the backend when available.
- Visible loading indicator at the top during refresh (`CupertinoSliverRefreshControl`).
- UI updates immediately after refresh completes; new contract version is applied.
- Errors are shown clearly with a banner and retry option.

## How to Validate
- Run tests: `flutter test` → expect `+17: All tests passed!` (current suite remains green).
- Launch on iOS: `open -a Simulator` then `flutter run`.
- Observe logs: startup contract fetch, analytics configuration, and any errors from the provider.
- Pull down to refresh on any main page; if backend is reachable, contract updates are applied.

## Troubleshooting
- Refresh disabled: Ensure `API_URL` is set to a reachable HTTP(S) base URL; otherwise `canRefresh` disables the gesture.
- Backend errors: Check console logs from `ContractService`; error details surface in the banner via `ContractProvider.error`.
- Asset fallback: The app boots using `assets/canonical_contract.json` when the backend is unavailable.