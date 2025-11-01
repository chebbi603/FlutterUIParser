import 'package:flutter/foundation.dart';
import '../services/contract_service.dart';
import '../models/contract_result.dart';
import '../services/auth_service.dart';
import '../state/state_manager.dart';

/// ContractProvider manages fetching and refreshing the canonical contract.
/// It exposes loading and error states for UI feedback.
class ContractProvider extends ChangeNotifier {
  final ContractService _service;
  AuthService? _authService;

  ContractResult? _currentContract;
  String? _authUserId;
  String? _jwtToken;
  bool _loading = false;
  String? _error;
  DateTime? _lastRefreshAt;

  ContractProvider({required ContractService service}) : _service = service;

  void attachAuthService(AuthService authService) {
    _authService = authService;
  }

  // Read-only getters
  Map<String, dynamic>? get contract => _currentContract?.contract;
  ContractResult? get contractResult => _currentContract;
  ContractSource? get contractSource => _currentContract?.source;
  bool get isPersonalized => _currentContract?.source == ContractSource.personalized;
  String get contractVersion => _currentContract?.version ?? 'unknown';
  bool get loading => _loading;
  String? get error => _error;

  /// Indicates whether refresh is currently allowed.
  /// - Requires a non-empty, absolute backend URL not pointing to localhost/127.0.0.1/10.0.2.2
  /// - Disallows refresh while loading or when a previous load error exists
  bool get canRefresh {
    if (_loading) return false;
    if (_error != null) return false;
    final base = _service.baseUrl.trim().toLowerCase();
    if (base.isEmpty) return false;
    if (!(base.startsWith('http://') || base.startsWith('https://'))) return false;
    final uri = Uri.tryParse(base);
    final host = uri?.host;
    if (host == null) return false;
    if (host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2') return false;
    return true;
  }

  /// Load canonical contract via ContractService.
  /// Idempotent: safe to call multiple times; if already loaded (canonical), it returns immediately.
  Future<void> loadCanonicalContract() async {
    if (_loading) return;
    if (_currentContract != null && _currentContract!.source == ContractSource.canonical) {
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _service.fetchCanonicalContract();
      _currentContract = result;
      _authUserId = null;
      _jwtToken = null;
    } catch (e) {
      _currentContract = null;
      _error = 'Failed to load canonical contract: $e';
      debugPrint('[ContractProvider.loadCanonicalContract] error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Load a personalized user-specific contract using JWT authentication.
  Future<void> loadUserContract({required String userId, required String jwtToken}) async {
    // Validate inputs
    final uid = userId.trim();
    final token = jwtToken.trim();
    if (uid.isEmpty || token.isEmpty) {
      _error = 'Invalid auth parameters';
      debugPrint('[ContractProvider.loadUserContract] invalid parameters: userId/jwtToken empty');
      notifyListeners();
      return;
    }
    // Short-circuit if already loaded personalized for same user
    if (_loading) return;
    if (_currentContract?.source == ContractSource.personalized && _authUserId == uid) {
      return;
    }

    _loading = true;
    _error = null;
    _authUserId = uid; // track active user attempting load
    _jwtToken = token; // store for future refreshes
    notifyListeners();
    try {
      final result = await _service.fetchUserContract(userId: uid, jwtToken: token);
      _currentContract = result; // may be personalized or canonical (404 fallback handled by service)
    } on AuthenticationException catch (e) {
      // Attempt token refresh via AuthService; on success retry, else state is cleared
      debugPrint('[ContractProvider.loadUserContract] auth error: $e');
      final refreshed = await (_authService?.tryRefresh() ?? Future.value(false));
      if (refreshed) {
        final newToken = EnhancedStateManager().getGlobalState<String>('authToken') ?? '';
        if (newToken.isNotEmpty) {
          try {
            final retry = await _service.fetchUserContract(userId: uid, jwtToken: newToken);
            _currentContract = retry;
            _error = null;
          } catch (err) {
            _currentContract = null;
            _error = 'Failed to load user contract after refresh: $err';
          }
        } else {
          _currentContract = null;
          _error = 'Authentication error: missing refreshed token';
        }
      } else {
        // Clear tracked auth state in provider; AuthService.logout may also navigate
        _currentContract = null; // signal offline/invalid state
        _authUserId = null;
        _jwtToken = null;
        _error = 'Authentication error: ${e.message}';
      }
    } catch (e) {
      // Preserve auth state on transient errors
      _currentContract = null;
      _error = 'Failed to load user contract: $e';
      debugPrint('[ContractProvider.loadUserContract] error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Refresh handler for pull-to-refresh.
  /// Routes based on authentication state and debounces rapid attempts.
  Future<void> refreshContract() async {
    // Debounce: skip if last refresh within 1.5s
    final now = DateTime.now();
    if (_lastRefreshAt != null && now.difference(_lastRefreshAt!).inMilliseconds < 1500) {
      return;
    }
    _lastRefreshAt = now;
    if (_authUserId != null && _jwtToken != null) {
      return loadUserContract(userId: _authUserId!, jwtToken: _jwtToken!);
    }
    return loadCanonicalContract();
  }

  /// Backward-compatible alias used by existing UI refresh gesture.
  Future<void> refresh() => refreshContract();
}