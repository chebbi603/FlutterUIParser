import 'package:flutter/foundation.dart';
import '../services/contract_service.dart';
import '../models/config_models.dart';

/// ContractProvider manages fetching and refreshing the canonical contract.
/// It exposes loading and error states for UI feedback.
class ContractProvider extends ChangeNotifier {
  final ContractService _service;

  Map<String, dynamic>? _contract;
  bool _loading = false;
  String? _error;

  ContractProvider({required ContractService service}) : _service = service;

  // Read-only getters
  Map<String, dynamic>? get contractMap => _contract;
  CanonicalContract? get contract =>
      _contract != null ? CanonicalContract.fromJson(_contract!) : null;
  bool get loading => _loading;
  String? get error => _error;

  /// Basic heuristic to allow refresh only when a plausible network endpoint exists.
  bool get canRefresh {
    final base = _service.baseUrl.trim();
    return !_loading && base.isNotEmpty && (base.startsWith('http://') || base.startsWith('https://'));
  }

  /// Load canonical contract via ContractService.
  Future<void> loadContract() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final map = await _service.fetchCanonicalContract();
      _contract = map;
    } catch (e) {
      _error = 'Failed to load contract: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Refresh handler for pull-to-refresh.
  Future<void> refresh() async {
    return loadContract();
  }
}