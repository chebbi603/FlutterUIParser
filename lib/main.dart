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

  // Resolve backend base URL from compile-time define with sensible defaults
  String baseUrl = const String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8081');
  baseUrl = baseUrl.trim().isEmpty ? 'http://localhost:8081' : baseUrl.trim();
  // Android emulator requires 10.0.2.2 for host machine
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && baseUrl == 'http://localhost:8081') {
    baseUrl = 'http://10.0.2.2:8081';
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