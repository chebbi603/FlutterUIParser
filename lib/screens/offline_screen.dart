import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

/// OfflineScreen
///
/// Displays a centered offline state when the backend is unreachable.
///
/// - Shows a network-unavailable icon
/// - Primary and secondary explanatory texts
/// - Retry button invoking the provided callback
/// - Optional error message shown in non-release builds
class OfflineScreen extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? errorMessage;
  final bool? isConnected;

  const OfflineScreen({
    super.key,
    this.onRetry,
    this.errorMessage,
    this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final textTheme = theme.textTheme;
    final showDetails = !kReleaseMode && (errorMessage != null && errorMessage!.trim().isNotEmpty);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Offline'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.wifi_slash,
                  size: 72,
                  color: CupertinoColors.systemGrey,
                ),
                const SizedBox(height: 16),
                Text(
                  'Unable to connect to server',
                  textAlign: TextAlign.center,
                  style: textTheme.navTitleTextStyle,
                ),
                const SizedBox(height: 12),
                Text(
                  'Please check your connection and try again',
                  textAlign: TextAlign.center,
                  style: textTheme.textStyle,
                ),
                if (isConnected != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    isConnected! ? 'Connection: Online' : 'Connection: Offline',
                    style: textTheme.textStyle.copyWith(color: CupertinoColors.systemGrey),
                  ),
                ],
                if (showDetails) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: textTheme.textStyle.copyWith(color: CupertinoColors.systemRed),
                  ),
                ],
                const SizedBox(height: 24),
                CupertinoButton.filled(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}