import '../state/state_manager.dart';
import 'api_service.dart';
import 'contract_loader.dart';
import '../providers/contract_provider.dart';
import '../navigation/navigation_bridge.dart';
import '../analytics/services/analytics_service.dart';
import '../analytics/models/tracking_event.dart';

class AuthService {
  final EnhancedStateManager _stateManager;
  final ContractApiService _apiService;
  ContractProvider? _contractProvider;

  AuthService(this._stateManager, this._apiService);

  void attachContractProvider(ContractProvider provider) {
    _contractProvider = provider;
  }

  Future<bool> login({required String email, required String password}) async {
    final response = await _apiService.call(
      service: 'auth',
      endpoint: 'login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final accessToken = response['accessToken'] as String?;
    final refreshToken = response['refreshToken'] as String?;
    if (accessToken == null || refreshToken == null) {
      return false;
    }

    _apiService.setAuthToken(accessToken);
    await _stateManager.setGlobalState('authToken', accessToken);
    await _stateManager.setGlobalState('refreshToken', refreshToken);

    // Optional: store minimal user info if present
    final userId = response['_id']?.toString();
    final role = response['role']?.toString();
    final username = response['username']?.toString();
    final name = response['name']?.toString();
    if (userId != null) {
      await _stateManager.setGlobalState('user', {
        'id': userId,
        if (role != null) 'role': role,
        if (username != null) 'username': username,
        if (name != null) 'name': name,
      });
    }

    // Post-login: attempt personalized contract fetch
    if (userId != null) {
      try {
        await _contractProvider?.loadUserContract(userId: userId, jwtToken: accessToken);
      } catch (e) {
        // Do not block login completion on contract errors
      }
    }
    // Analytics: log authentication success
    AnalyticsService().logAuthEvent('user_authenticated', {
      if (userId != null) 'userId': userId,
      'loginMethod': 'email',
    });
    return true;
  }

  Future<bool> tryRefresh() async {
    final refreshToken = _stateManager.getGlobalState<String>('refreshToken');
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }
    final analytics = AnalyticsService();
    analytics.logAuthEvent('token_refresh_attempt', {
      'hasRefreshToken': true,
    });
    try {
      final res = await _apiService.call(
        service: 'auth',
        endpoint: 'refresh',
        data: {
          'refreshToken': refreshToken,
        },
      );
      final newAccess = res['accessToken'] as String?;
      final newRefresh = res['refreshToken'] as String?;
      if (newAccess != null && newRefresh != null) {
        _apiService.setAuthToken(newAccess);
        await _stateManager.setGlobalState('authToken', newAccess);
        await _stateManager.setGlobalState('refreshToken', newRefresh);
        analytics.logAuthEvent('token_refresh_success', {});
        return true;
      }
    } catch (e) {
      analytics.logAuthEvent('token_refresh_failed', {
        'reason': e.toString(),
      });
    }
    await logout();
    return false;
  }

  Future<void> logout() async {
    final refreshToken = _stateManager.getGlobalState<String>('refreshToken');
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _apiService.call(
          service: 'auth',
          endpoint: 'logout',
          data: {
            'refreshToken': refreshToken,
          },
        );
      } catch (_) {}
    }

    // Pre-logout: revert contract to canonical
    try {
      await _contractProvider?.loadCanonicalContract();
    } catch (_) {}

    _apiService.clearAuthToken();
    await _stateManager.setGlobalState('authToken', null);
    await _stateManager.setGlobalState('refreshToken', null);
    await _stateManager.setGlobalState('user', null);
    // Clear locally cached contract on logout
    await ContractLoader.clearCache();
    // Clear all persisted state including page scope
    await _stateManager.clearAll();

    // Log analytics logout
    final analytics = AnalyticsService();
    analytics.logAuthEvent('logout', {
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Optional navigation to login route via tab bridge mapping
    NavigationBridge.switchTo('/login');
  }
}