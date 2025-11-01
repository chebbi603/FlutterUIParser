import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform, kDebugMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart' show MyApp;
import 'package:provider/provider.dart';
import 'providers/contract_provider.dart';
import 'services/contract_service.dart';
import 'analytics/services/analytics_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // If no .env file, continue with defaults
  }

  // Resolve backend base URL from compile-time define with sensible defaults
  String baseUrl = const String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8081');
  baseUrl = baseUrl.trim().isEmpty ? 'http://localhost:8081' : baseUrl.trim();
  // Android emulator requires 10.0.2.2 for host machine
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && baseUrl == 'http://localhost:8081') {
    baseUrl = 'http://10.0.2.2:8081';
  }

  // Fetch canonical contract before booting the app
  final contractService = ContractService(baseUrl: baseUrl);
  final contractMap = await contractService.fetchCanonicalContract();

  // Configure analytics from loaded contract map (if present)
  final backendUrl = _extractAnalyticsBackendUrl(contractMap);
  AnalyticsService().configure(backendUrl: backendUrl);
  // Helpful dev log to confirm analytics setup or disabled state
  // ignore: avoid_print
  if (backendUrl != null && backendUrl.isNotEmpty) {
    print('Analytics configured: $backendUrl');
  } else {
    print('Analytics disabled: no backendUrl in contract');
  }

  runApp(
    ChangeNotifierProvider<ContractProvider>(
      create: (_) {
        final provider = ContractProvider(service: contractService);
        // Kick off initial load so future refreshes have consistent pathway
        // (MyApp will boot from contractMap passed below).
        provider.loadContract();
        return provider;
      },
      child: MyApp(initialContractMap: contractMap),
    ),
  );
}

/// Extract analytics backend URL from the raw contract JSON with env var resolution
String? _extractAnalyticsBackendUrl(Map<String, dynamic> contractMap) {
  final analytics = contractMap['analytics'];
  final raw = (analytics is Map<String, dynamic>) ? (analytics['backendUrl'] as String?) : null;
  return _resolveEnvVarsInUrl(raw);
}

/// Resolve ${VAR} placeholders using dotenv and validate absolute URL for logging
String? _resolveEnvVarsInUrl(String? s) {
  if (s == null || s.trim().isEmpty) return null;
  final regex = RegExp(r'\$\{([^}]+)\}');
  String resolved = s.replaceAllMapped(regex, (m) {
    final key = m.group(1)!;
    final val = dotenv.isInitialized ? dotenv.env[key] : null;
    return (val != null && val.isNotEmpty) ? val : '';
  }).trim();
  if (resolved.isEmpty) return null;
  final uri = Uri.tryParse(resolved);
  if (uri == null || !(uri.hasScheme && uri.host.isNotEmpty)) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('⚠️ Analytics backendUrl may be invalid or not absolute: $resolved');
    }
  }
  return resolved;
}