import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart' show MyApp;
import 'package:provider/provider.dart';
import 'providers/contract_provider.dart';
import 'services/contract_service.dart';
// Analytics is configured after contract load inside MyApp

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // If no .env file, continue with defaults
  }

  // Resolve backend base URL from compile-time or .env with sensible defaults
  // Priority: compile-time (API_BASE_URL, API_URL) → .env (API_BASE_URL, API_URL) → default
  String baseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: '');
  if (baseUrl.trim().isEmpty) {
    baseUrl = const String.fromEnvironment('API_URL', defaultValue: '');
  }
  if (baseUrl.trim().isEmpty && dotenv.isInitialized) {
    baseUrl = (dotenv.env['API_BASE_URL'] ?? dotenv.env['API_URL'] ?? '').trim();
  }
  if (baseUrl.trim().isEmpty) {
    baseUrl = 'http://localhost:8081';
  }
  baseUrl = baseUrl.trim();
  // Normalize localhost port to 8081 when misconfigured to 8082
  try {
    final uri = Uri.tryParse(baseUrl);
    if (uri != null) {
      final isLocalHost = uri.host == 'localhost' || uri.host == '127.0.0.1';
      if (isLocalHost && uri.port == 8082) {
        baseUrl = Uri(
          scheme: uri.scheme.isNotEmpty ? uri.scheme : 'http',
          host: uri.host,
          port: 8081,
        ).toString();
      }
    }
  } catch (_) {}
  // Android emulator requires 10.0.2.2 for host machine
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final normalizedLocal = baseUrl.replaceAll('127.0.0.1', 'localhost');
    if (normalizedLocal.startsWith('http://localhost:')) {
      final uri = Uri.tryParse(normalizedLocal);
      final port = uri?.port ?? 8081;
      baseUrl = 'http://10.0.2.2:$port';
    }
  }

  // Initialize core services before provider creation
  final contractService = ContractService(baseUrl: baseUrl);

  // Set up provider hierarchy without blocking on network fetch
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ContractProvider>(
          create: (_) => ContractProvider(service: contractService),
        ),
        // Add AuthProvider here in future if needed
      ],
      child: const MyApp(),
    ),
  );
}