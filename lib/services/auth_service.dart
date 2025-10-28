import '../state/state_manager.dart';
import 'api_service.dart';

class AuthService {
  final EnhancedStateManager _stateManager;
  final ContractApiService _apiService;

  AuthService(this._stateManager, this._apiService);

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
    if (userId != null) {
      await _stateManager.setGlobalState('user', {
        'id': userId,
        if (role != null) 'role': role,
      });
    }
    return true;
  }

  Future<bool> tryRefresh() async {
    final refreshToken = _stateManager.getGlobalState<String>('refreshToken');
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }
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
        return true;
      }
    } catch (_) {}
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
    _apiService.clearAuthToken();
    await _stateManager.setGlobalState('authToken', null);
    await _stateManager.setGlobalState('refreshToken', null);
    await _stateManager.setGlobalState('user', null);
  }
}