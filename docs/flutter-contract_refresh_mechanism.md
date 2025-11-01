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
  - `ContractResult? _currentContract` (wrapped payload and metadata)
  - `String? _authUserId` (current authenticated user id)
  - `String? _jwtToken` (current JWT)
  - `bool _loading = false`
  - `String? _error`
- Public getters:
  - `Map<String, dynamic>? get contract` (raw map from `_currentContract`)
  - `ContractResult? get contractResult` (full wrapper)
  - `ContractSource? get contractSource`, `bool get isPersonalized`
  - `String get contractVersion` (defaults to `unknown`)
  - `bool get loading`, `String? get error`
  - `bool get canRefresh`: Returns true only when a non-empty absolute backend URL is configured and not pointing to localhost/127.0.0.1/10.0.2.2, and no load/error is in progress.
- Methods:
  - `Future<void> loadCanonicalContract()`: Idempotent canonical fetch; clears auth state; manages loading/error; notifies UI.
  - `Future<void> loadUserContract(userId, jwtToken)`: Loads personalized contract; stores auth state; handles 401 by clearing auth and 404 via canonical fallback.
  - `Future<void> refreshContract()`: Routes to user or canonical load based on auth state and debounces rapid attempts.
  - `Future<void> refresh()`: Backward-compatible alias delegating to `refreshContract()`.

## Boot and Provider Wiring
**File**: `lib/main.dart`
- Resolves `API_URL` (defaults to `http://localhost:8081`; uses `10.0.2.2` for Android emulator).
- Creates `ContractService(baseUrl)` and sets up `MultiProvider` without blocking on network:
  ```dart
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ContractProvider(service: contractService),
        ),
      ],
      child: const MyApp(),
    ),
  );
  ```

**File**: `lib/app.dart`
- `MyApp` is `StatefulWidget`; in `initState`, it defers `loadCanonicalContract()` until after the first frame:
  ```dart
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Provider.of<ContractProvider>(context, listen: false).loadCanonicalContract();
  });
  ```
- `MyApp` listens to `ContractProvider` changes. When a new contract arrives or its version changes, `MyApp` reinitializes services and applies the new UI contract.

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
- Analytics backend configuration now occurs when the contract loads inside `MyApp`.
- Optional future: integrate `ChangeNotifierProxyProvider<AuthProvider, ContractProvider>` to auto-switch between canonical and personalized contracts on auth changes.

## Auth-Driven Switching
- On successful login, `AuthService` calls `ContractProvider.loadUserContract(userId, jwtToken)` to fetch and apply the personalized contract.
- Errors during personalized fetch are caught and logged and do not block login completion; the UI remains authenticated and can fall back to canonical if needed.
- On logout, `AuthService` invokes `ContractProvider.loadCanonicalContract()` before clearing tokens to revert the UI to the public contract cleanly.
- `MyApp` provides `ContractProvider` to `AuthService` during initialization so these transitions can occur without `BuildContext` coupling.
- Optional navigation to the login screen may be triggered via `NavigationBridge.switchTo('/login')` when the route is tab-mapped.

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
- Backend‑only mode: There is no local asset fallback; ensure backend availability or mock HTTP in tests.