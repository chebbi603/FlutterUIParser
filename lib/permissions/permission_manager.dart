import '../models/config_models.dart';

/// Permission manager for role-based access control
class PermissionManager {
  PermissionsFlagsConfig? _config;
  String? _currentUserRole;
  final Set<String> _userPermissions = {};

  /// Initialize with permissions configuration
  void initialize(PermissionsFlagsConfig config) {
    _config = config;
  }

  /// Set current user role
  void setUserRole(String role) {
    _currentUserRole = role;
    _updateUserPermissions();
  }

  /// Clear current user role
  void clearUserRole() {
    _currentUserRole = null;
    _userPermissions.clear();
  }

  void _updateUserPermissions() {
    _userPermissions.clear();

    if (_config == null || _currentUserRole == null) return;

    final roleConfig = _config!.roles[_currentUserRole!];
    if (roleConfig == null) return;

    // Add direct permissions
    _userPermissions.addAll(roleConfig.permissions);

    // Add inherited permissions
    if (roleConfig.inherits != null) {
      for (final inheritedRole in roleConfig.inherits!) {
        final inheritedConfig = _config!.roles[inheritedRole];
        if (inheritedConfig != null) {
          _userPermissions.addAll(inheritedConfig.permissions);

          // Recursively add inherited permissions
          _addInheritedPermissions(inheritedRole);
        }
      }
    }
  }

  void _addInheritedPermissions(String role) {
    final roleConfig = _config!.roles[role];
    if (roleConfig?.inherits != null) {
      for (final inheritedRole in roleConfig!.inherits!) {
        final inheritedConfig = _config!.roles[inheritedRole];
        if (inheritedConfig != null) {
          _userPermissions.addAll(inheritedConfig.permissions);
          _addInheritedPermissions(inheritedRole);
        }
      }
    }
  }

  /// Check if user has specific permission
  bool hasPermission(String permission) {
    return _userPermissions.contains(permission);
  }

  /// Check if user has any of the specified permissions
  bool hasAnyPermission(List<String> permissions) {
    return permissions.any(
      (permission) => _userPermissions.contains(permission),
    );
  }

  /// Check if user has all of the specified permissions
  bool hasAllPermissions(List<String> permissions) {
    return permissions.every(
      (permission) => _userPermissions.contains(permission),
    );
  }

  /// Check if feature flag is enabled for current user
  bool isFeatureEnabled(String featureName) {
    if (_config == null) return false;

    final featureFlag = _config!.featureFlags[featureName];
    if (featureFlag == null) return false;

    // Check if feature is globally enabled
    if (!featureFlag.enabled) return false;

    // Check rollout percentage (simplified - in real app you'd use user ID hash)
    if (featureFlag.rolloutPercentage < 100) {
      // For demo purposes, always enable if user has role
      if (_currentUserRole == null) return false;
    }

    // Check target roles
    if (featureFlag.targetRoles != null && _currentUserRole != null) {
      return featureFlag.targetRoles!.contains(_currentUserRole);
    }

    return true;
  }

  /// Get all user permissions
  Set<String> getUserPermissions() {
    return Set.from(_userPermissions);
  }

  /// Get current user role
  String? getCurrentUserRole() {
    return _currentUserRole;
  }

  /// Check if user has admin role
  bool isAdmin() {
    return _currentUserRole == 'admin';
  }

  /// Check if user has moderator role or higher
  bool isModerator() {
    return _currentUserRole == 'admin' || _currentUserRole == 'moderator';
  }
}
