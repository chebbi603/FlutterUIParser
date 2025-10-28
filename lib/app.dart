import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models/config_models.dart';
// import 'validation/contract_validator.dart';
import 'widgets/component_factory.dart';
import 'widgets/enhanced_page_builder.dart';
import 'state/state_manager.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'permissions/permission_manager.dart';
import 'navigation/navigation_bridge.dart';
import 'utils/parsing_utils.dart';

import 'analytics/services/analytics_service.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  CanonicalContract? contract;
  bool isLoading = true;
  String? errorMessage;
  List<String>? errorDetails;

  final EnhancedStateManager stateManager = EnhancedStateManager();
  final ContractApiService apiService = ContractApiService();
  final PermissionManager permissionManager = PermissionManager();
  CupertinoTabController? _tabController;
  Set<String> _trackedIds = {};

  @override
  void initState() {
    super.initState();
    _loadContract();
  }

  Future<void> _loadContract() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/canonical_contract.json',
      );
      final dynamic raw = json.decode(response);
      // Ensure the root of the JSON is an object
      if (raw is! Map) {
        setState(() {
          isLoading = false;
          errorMessage = 'Canonical contract validation failed';
          errorDetails = [
            'Root JSON must be an object, got ${raw.runtimeType}',
          ];
        });
        return;
      }
      final Map<String, dynamic> data = Map<String, dynamic>.from(raw);

      // Validation removed; proceed to construct contract directly
      final loadedContract = CanonicalContract.fromJson(data);

      // Initialize all services with the contract
      await stateManager.initialize(loadedContract.state);
      apiService.initialize(loadedContract);
      permissionManager.initialize(loadedContract.permissionsFlags);
      EnhancedComponentFactory.initialize(loadedContract);

      // Attach auth service and restore persisted tokens
      final authService = AuthService(stateManager, apiService);
      apiService.attachAuthService(authService);
      final persistedAccess = stateManager.getGlobalState<String>('authToken');
      if (persistedAccess != null && persistedAccess.isNotEmpty) {
        apiService.setAuthToken(persistedAccess);
      }

      // Configure analytics with env override and simple validation
      final envBackend = (dotenv.isInitialized ? dotenv.env['ANALYTICS_BACKEND_URL'] : null)?.trim();
      final mockEnv = dotenv.isInitialized ? dotenv.env['ANALYTICS_MOCK_MODE'] : null;
      final mockMode = ((mockEnv ?? 'false').toLowerCase() == 'true');
      final configuredBackend = (envBackend != null && envBackend.isNotEmpty)
          ? envBackend
          : loadedContract.analytics?.backendUrl;
      final batchSize = int.tryParse(((dotenv.isInitialized ? dotenv.env['ANALYTICS_BATCH_SIZE'] : null) ?? '').trim());
      final flushInterval = int.tryParse(((dotenv.isInitialized ? dotenv.env['ANALYTICS_FLUSH_INTERVAL_MS'] : null) ?? '').trim());
      final wsUrl = (dotenv.isInitialized ? dotenv.env['WS_URL'] : null)?.trim();
      AnalyticsService().configure(
        backendUrl: configuredBackend,
        wsUrl: wsUrl,
        batchSize: batchSize,
        flushIntervalMs: flushInterval,
      );
      _trackedIds = loadedContract.analytics?.trackedComponents.toSet() ?? {};

      // Execute app start events
      if (loadedContract.eventsActions.onAppStart != null) {
        for (final action in loadedContract.eventsActions.onAppStart!) {
          // Execute startup actions (simplified)
          debugPrint('Executing startup action: ${action.action}');
        }
      }

      // If analytics backend missing and not in mock mode, show a clear message
      if ((configuredBackend == null || configuredBackend.isEmpty) && !mockMode) {
        setState(() {
          contract = loadedContract;
          isLoading = false;
          errorMessage = 'Missing analytics backend URL. Set ANALYTICS_BACKEND_URL in .env or provide analytics.backendUrl in contract.';
          errorDetails = null;
        });
      } else {
        setState(() {
          contract = loadedContract;
          isLoading = false;
          errorMessage = null;
          errorDetails = null;
        });
      }
    } catch (e, st) {
      // Capture stack trace to aid debugging
      final lines = st.toString().split('\n');
      final top = lines.take(12).toList();
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading canonical contract: $e';
        errorDetails = top;
      });
      debugPrint('Error loading contract: $e');
      debugPrint('Stack trace (top): ${top.join("\\n")}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(child: CupertinoActivityIndicator()),
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    if (errorMessage != null) {
      return CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 48,
                  color: CupertinoColors.destructiveRed,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to Load App',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ),
                if (errorDetails != null && errorDetails!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: errorDetails!.length,
                        itemBuilder: (_, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '• ${errorDetails![index]}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                CupertinoButton(
                  onPressed: () {
                    setState(() {
                      isLoading = true;
                      errorMessage = null;
                      errorDetails = null;
                    });
                    _loadContract();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    if (contract == null) {
      return const CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(child: Text('No contract loaded')),
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    return ChangeNotifierProvider.value(
      value: stateManager,
      child: CupertinoApp(
        title: contract!.meta.appName,
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: _buildHome(),
        onGenerateRoute: _generateRoute,
      ),
    );
  }

  CupertinoThemeData _buildTheme() {
    // For now, use default Cupertino theme
    // In a full implementation, you'd use the theme tokens from the contract
    return const CupertinoThemeData(brightness: Brightness.light);
  }

  Widget _buildHome() {
    final pagesUI = contract!.pagesUI;

    // Check if bottom navigation is enabled
    if (pagesUI.bottomNavigation?.enabled == true) {
      return _buildTabbedHome();
    }

    // Find home route
    final homeRoute = pagesUI.routes['/'];
    if (homeRoute != null) {
      final page = pagesUI.pages[homeRoute.pageId];
      if (page != null) {
        return EnhancedPageBuilder(config: page, trackedIds: _trackedIds);
      }
    }

    // Fallback to first page
    if (pagesUI.pages.isNotEmpty) {
      final firstPage = pagesUI.pages.values.first;
      return EnhancedPageBuilder(config: firstPage, trackedIds: _trackedIds);
    }

    return const CupertinoPageScaffold(
      child: Center(child: Text('No pages configured')),
    );
  }

  Widget _buildTabbedHome() {
    final bottomNav = contract!.pagesUI.bottomNavigation!;
    final pages = contract!.pagesUI.pages;
    _tabController ??= CupertinoTabController(
      initialIndex: bottomNav.initialIndex,
    );

    // Resolve tab pages
    final tabPages =
        bottomNav.items.map((item) {
          final page = pages[item.pageId];
          return page ?? pages.values.first;
        }).toList();

    // Map routes to tab indices for quick switching
    final Map<String, int> routeToIndex = {};
    for (var i = 0; i < bottomNav.items.length; i++) {
      final item = bottomNav.items[i];
      contract!.pagesUI.routes.forEach((routeName, routeConfig) {
        if (routeConfig.pageId == item.pageId) {
          routeToIndex[routeName] = i;
        }
      });
    }

    // Expose controller and route map via bridge
    NavigationBridge.tabController = _tabController;
    NavigationBridge.routeToIndex = routeToIndex;

    return CupertinoTabScaffold(
      controller: _tabController,
      tabBar: CupertinoTabBar(
        currentIndex: bottomNav.initialIndex,
        backgroundColor:
            _parseColor(bottomNav.style?.backgroundColor) ??
            CupertinoColors.systemBackground,
        activeColor:
            _parseColor(bottomNav.style?.foregroundColor) ??
            CupertinoColors.activeBlue,
        inactiveColor:
            _parseColor(bottomNav.style?.color) ?? CupertinoColors.inactiveGray,
        items:
            bottomNav.items.map((item) {
              // Resolve icon via contract mapping or fallback
              final mapped = contract!.assets.icons[item.icon];
              final iconData = ParsingUtils.parseIcon(mapped ?? item.icon);
              return BottomNavigationBarItem(
                icon: Icon(iconData),
                label: item.title,
              );
            }).toList(),
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (_) => EnhancedPageBuilder(config: tabPages[index], trackedIds: _trackedIds),
          onGenerateRoute: _generateRoute,
        );
      },
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    final routeName = settings.name ?? '/';

    final routeConfig = contract!.pagesUI.routes[routeName];

    if (routeConfig == null) {
      return CupertinoPageRoute(
        builder:
            (_) => const CupertinoPageScaffold(
              child: Center(child: Text('Page not found')),
            ),
      );
    }

    // Check authentication
    if (routeConfig.auth == true) {
      final authToken = stateManager.getGlobalState<String>('authToken');
      if (authToken == null || authToken.isEmpty) {
        // Redirect to login page if configured
        final loginRoute = contract!.pagesUI.routes['/login'];
        if (loginRoute != null) {
          final page = contract!.pagesUI.pages[loginRoute.pageId];
          if (page != null) {
            return CupertinoPageRoute(
              builder: (_) => EnhancedPageBuilder(config: page, trackedIds: _trackedIds),
            );
          }
        }
        return CupertinoPageRoute(
          builder:
              (_) => const CupertinoPageScaffold(
                child: Center(child: Text('Please log in')),
              ),
        );
      }
    }

    final page = contract!.pagesUI.pages[routeConfig.pageId];
    if (page == null) {
      return CupertinoPageRoute(
        builder:
            (_) => const CupertinoPageScaffold(
              child: Center(child: Text('Page configuration not found')),
            ),
      );
    }

    return CupertinoPageRoute(
      builder: (_) => EnhancedPageBuilder(config: page, trackedIds: _trackedIds),
      settings: settings,
    );
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;

    // Handle theme tokens
    if (colorString.startsWith('\${theme.') && colorString.endsWith('}')) {
      final tokenName = colorString.substring(8, colorString.length - 1);
      final themeMode = stateManager.getGlobalState<String>('theme') ?? 'light';
      final themeTokens = contract!.themingAccessibility.tokens[themeMode];
      final tokenValue = themeTokens?[tokenName];
      if (tokenValue != null) {
        return _parseHexColor(tokenValue);
      }
    }

    return _parseHexColor(colorString);
  }

  Color? _parseHexColor(String colorString) {
    if (colorString.startsWith('#')) {
      final hex = colorString.substring(1);
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    }
    return null;
  }
}
