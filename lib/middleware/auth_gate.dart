import 'package:flutter/foundation.dart';
import '../state/state_manager.dart';
import '../persistence/state_persistence.dart';
import '../providers/contract_provider.dart';

/// Auth gate middleware to evaluate authentication status and route access.
///
/// Responsibilities:
/// - Determine if the user is authenticated by checking a persisted token
///   and the presence of a valid `user` object in global state.
/// - Provide an initial route based on authentication status.
/// - Guard protected routes by requiring authentication.
class AuthGate {
  final EnhancedStateManager stateManager;
  final SecureStoragePersistence secureStorage;
  ContractProvider? _contractProvider;

  AuthGate({
    required this.stateManager,
    SecureStoragePersistence? secureStorage,
  }) : secureStorage = secureStorage ?? SecureStoragePersistence();

  void attachContractProvider(ContractProvider provider) {
    _contractProvider = provider;
  }

  /// Initialize underlying secure storage (no-op if already initialized).
  Future<void> init() async {
    try {
      await secureStorage.init();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthGate.init error: $e');
      }
    }
  }

  /// Read the persisted auth token directly from secure storage.
  /// Uses the EnhancedStateManager keying convention: 'state:global:authToken'.
  Future<String?> _readPersistedToken() async {
    final raw = await secureStorage.read('state:global:authToken');
    if (raw == null) return null;
    final str = raw.toString();
    return str.isEmpty ? null : str;
  }

  /// Determine if the app has a valid authenticated session.
  /// Conditions:
  /// - `authToken` exists in secure storage
  /// - `user` object exists in global state and has a non-empty `id`
  Future<bool> isAuthenticated() async {
    final token = await _readPersistedToken();
    final user = stateManager.getGlobalState<Map<String, dynamic>>('user');
    final hasUserId = user != null && (user['id']?.toString().isNotEmpty ?? false);
    final hasToken = token != null && token.isNotEmpty;
    return hasToken && hasUserId;
  }

  /// Determine the first route to show based on authentication status.
  /// - Authenticated: '/home'
  /// - Unauthenticated: '/'
  Future<String> getInitialRoute() async {
    final authenticated = await isAuthenticated();
    return authenticated ? '/home' : '/';
  }

  /// Returns true if the route requires authentication.
  bool isRouteProtected(String routePath) {
    // Normalize routePath (strip query/hash if present)
    final path = routePath.split('?').first.split('#').first;
    // Prefer dynamic check from contract routes when available
    try {
      final map = _contractProvider?.contract;
      if (map is Map<String, dynamic>) {
        final pagesUi = map['pagesUI'] as Map<String, dynamic>?;
        final routes = pagesUi != null ? pagesUi['routes'] as Map<String, dynamic>? : null;
        final entry = routes != null ? routes[path] : null;
        if (entry is Map<String, dynamic>) {
          final authVal = entry['auth'];
          if (authVal == true) return true;
          if (authVal is String) {
            final v = authVal.toLowerCase();
            if (v == 'required' || v == 'true' || v == 'auth' || v == 'authenticated') {
              return true;
            }
          }
          // Explicit false → public
          if (authVal == false) return false;
        }
      }
    } catch (_) {}
    // Fallback: protect common content routes by prefix
    if (path.startsWith('/content/')) return true;
    return false;
  }

  /// Evaluate if the current user can access the given route.
  /// Public routes always allow; protected routes require authentication.
  Future<bool> canAccessRoute(String routePath) async {
    if (!isRouteProtected(routePath)) return true;
    return await isAuthenticated();
  }
}