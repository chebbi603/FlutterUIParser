import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
// Dotenv is no longer needed in app initialization; environment resolution happens in main.dart
import 'models/config_models.dart';
import 'widgets/enhanced_page_builder.dart';
import 'state/state_manager.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'permissions/permission_manager.dart';
import 'navigation/navigation_bridge.dart';
import 'utils/parsing_utils.dart';
import 'widgets/component_factory.dart';
import 'providers/contract_provider.dart';
import 'screens/offline_screen.dart';
import 'analytics/services/analytics_service.dart';
import 'analytics/models/tracking_event.dart';

// Note: AnalyticsService configuration now happens when contract loads inside MyApp.

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  CanonicalContract? contract;

  final EnhancedStateManager stateManager = EnhancedStateManager();
  final ContractApiService apiService = ContractApiService();
  final PermissionManager permissionManager = PermissionManager();
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  CupertinoTabController? _tabController;
  Set<String> _trackedIds = {};
  OverlayEntry? _toastEntry;
  String? _currentVersion;
  String? _lastAuthToken;
  String? _lastUserId;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // React to auth token/user changes to refresh contract on login/logout
    stateManager.addListener(_onStateChanged);
    // Attach provider listener and defer initial canonical load until first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachProviderListener();
      try {
        final provider = Provider.of<ContractProvider>(context, listen: false);
        provider.loadCanonicalContract();
      } catch (_) {
        // Provider not yet available; try again next frame
        WidgetsBinding.instance.addPostFrameCallback((__) {
          if (!mounted) return;
          final provider = Provider.of<ContractProvider>(context, listen: false);
          provider.loadCanonicalContract();
        });
      }
    });
  }

  @override
  void dispose() {
    // Detach listeners and clean up controllers/overlays
    try {
      final provider = Provider.of<ContractProvider>(context, listen: false);
      provider.removeListener(_onProviderChanged);
    } catch (_) {}
    stateManager.removeListener(_onStateChanged);
    _toastEntry?.remove();
    _toastEntry = null;
    _tabController?.dispose();
    super.dispose();
  }

  void _attachProviderListener() {
    if (!mounted) return;
    try {
      final provider = Provider.of<ContractProvider>(context, listen: false);
      provider.addListener(_onProviderChanged);
    } catch (_) {
      // Provider not found yet; will try again on next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _attachProviderListener();
        }
      });
    }
  }

  void _onProviderChanged() {
    if (!mounted) return;
    final provider = Provider.of<ContractProvider>(context, listen: false);
    // Show refresh error if any
    final err = provider.error;
    if (err != null && err.isNotEmpty) {
      _showToast('Refresh failed: $err');
    }
    final updatedMap = provider.contract;
    if (updatedMap != null) {
      final updated = CanonicalContract.fromJson(updatedMap);
      final newVersion = updated.meta.version;
      // Apply on first load or version change
      if (_currentVersion == null || newVersion != _currentVersion) {
        unawaited(_applyUpdatedContract(updated));
      }
    }
  }

  Future<void> _initializeWithContract(CanonicalContract loadedContract, {bool initState = true}) async {
    if (initState) {
      await stateManager.initialize(loadedContract.state);
    }
    apiService.initialize(loadedContract);
    permissionManager.initialize(loadedContract.permissionsFlags);
    EnhancedComponentFactory.initialize(loadedContract);

    // Attach auth service and restore persisted tokens
    final authService = AuthService(stateManager, apiService);
    apiService.attachAuthService(authService);
    // Provide ContractProvider to AuthService for post-login/logout contract switching
    try {
      final provider = Provider.of<ContractProvider>(context, listen: false);
      authService.attachContractProvider(provider);
    } catch (_) {}
    final persistedAccess = stateManager.getGlobalState<String>('authToken');
    if (persistedAccess != null && persistedAccess.isNotEmpty) {
      apiService.setAuthToken(persistedAccess);
    }

    // Set tracked component ids for analytics widgets; actual AnalyticsService
    // configuration happens here once a contract is available.
    _trackedIds = loadedContract.analytics?.trackedComponents.toSet() ?? {};

    // Configure analytics backend if provided by contract
    final analyticsBackend = loadedContract.analytics?.backendUrl?.trim();
    if (analyticsBackend != null && analyticsBackend.isNotEmpty) {
      final analytics = AnalyticsService();
      analytics.configure(backendUrl: analyticsBackend);
      // Attach context providers for attribution
      try {
        final provider = Provider.of<ContractProvider>(context, listen: false);
        analytics.attachContractProvider(provider);
      } catch (_) {}
      analytics.attachStateManager(stateManager);
    }

    // Execute app start events (simplified logging)
    if (loadedContract.eventsActions.onAppStart != null) {
      for (final action in loadedContract.eventsActions.onAppStart!) {
        debugPrint('Executing startup action: ${action.action}');
      }
    }
  }

  Future<void> _attemptApiRefresh() async {
    if (_isRefreshing) return;
    final token = stateManager.getGlobalState<String>('authToken');
    final userObj = stateManager.getGlobalState<Map<String, dynamic>>('user');
    final userId = userObj?['id']?.toString();
    if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
      return;
    }

    _isRefreshing = true;
    try {
      final provider = Provider.of<ContractProvider>(context, listen: false);
      await provider.loadUserContract(userId: userId, jwtToken: token);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _applyUpdatedContract(CanonicalContract newContract) async {
    // Reinitialize API + permissions + factory (initialize state on first load)
    await _initializeWithContract(newContract, initState: contract == null);
    setState(() {
      contract = newContract;
      _currentVersion = newContract.meta.version;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showToast('UI updated from server');
    });
  }

  void _onStateChanged() {
    final token = stateManager.getGlobalState<String>('authToken') ?? '';
    final userObj = stateManager.getGlobalState<Map<String, dynamic>>('user');
    final userId = userObj?['id']?.toString();
    final changed = (token != _lastAuthToken) || (userId != _lastUserId);
    _lastAuthToken = token;
    _lastUserId = userId;
    if (token.isNotEmpty && userId != null && changed) {
      unawaited(_attemptApiRefresh());
    }
  }

  // Base URL resolution moved to main.dart; contract-specific services read directly from the contract.

  void _showToast(String message) {
    if (!mounted) return;
    final overlay = _navKey.currentState?.overlay;
    if (overlay == null) return;
    _toastEntry?.remove();
    _toastEntry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 80,
        left: 16,
        right: 16,
        child: CupertinoPopupSurface(
          isSurfacePainted: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: CupertinoColors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DefaultTextStyle(
              style: const TextStyle(color: CupertinoColors.white, fontSize: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.info, color: CupertinoColors.white, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_toastEntry!);
    Future.delayed(const Duration(seconds: 3), () {
      _toastEntry?.remove();
      _toastEntry = null;
    });
  }

  

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ContractProvider>(context);

    if (contract == null) {
      if (provider.loading) {
        return const CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(child: CupertinoActivityIndicator()),
          ),
          debugShowCheckedModeBanner: false,
        );
      }
      if (provider.error != null && provider.error!.trim().isNotEmpty) {
        return CupertinoApp(
          home: OfflineScreen(
            onRetry: () => Provider.of<ContractProvider>(context, listen: false).loadCanonicalContract(),
            errorMessage: provider.error,
          ),
          debugShowCheckedModeBanner: false,
        );
      }
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
        navigatorKey: _navKey,
        title: contract!.meta.appName,
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: _buildHome(),
        onGenerateRoute: _generateRoute,
      ),
    );
  }

  CupertinoThemeData _buildTheme() {
    return const CupertinoThemeData(brightness: Brightness.light);
  }

  Widget _buildHome() {
    final pagesUI = contract!.pagesUI;

    if (pagesUI.bottomNavigation?.enabled == true) {
      return _buildTabbedHome();
    }

    final homeRoute = pagesUI.routes['/'];
    if (homeRoute != null) {
      final page = pagesUI.pages[homeRoute.pageId];
      if (page != null) {
        return _wrapWithRefresh(EnhancedPageBuilder(config: page, trackedIds: _trackedIds));
      }
    }

    if (pagesUI.pages.isNotEmpty) {
      final firstPage = pagesUI.pages.values.first;
      return _wrapWithRefresh(EnhancedPageBuilder(config: firstPage, trackedIds: _trackedIds));
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

    final tabPages = bottomNav.items.map((item) {
      final page = pages[item.pageId];
      return page ?? pages.values.first;
    }).toList();

    final Map<String, int> routeToIndex = {};
    for (var i = 0; i < bottomNav.items.length; i++) {
      final item = bottomNav.items[i];
      contract!.pagesUI.routes.forEach((routeName, routeConfig) {
        if (routeConfig.pageId == item.pageId) {
          routeToIndex[routeName] = i;
        }
      });
    }

    NavigationBridge.tabController = _tabController;
    NavigationBridge.routeToIndex = routeToIndex;

    return CupertinoTabScaffold(
      controller: _tabController,
      tabBar: CupertinoTabBar(
        currentIndex: bottomNav.initialIndex,
        backgroundColor: _parseColor(bottomNav.style?.backgroundColor) ?? CupertinoColors.systemBackground,
        activeColor: _parseColor(bottomNav.style?.foregroundColor) ?? CupertinoColors.activeBlue,
        inactiveColor: _parseColor(bottomNav.style?.color) ?? CupertinoColors.inactiveGray,
        items: bottomNav.items.map((item) {
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
          builder: (_) => _wrapWithRefresh(EnhancedPageBuilder(config: tabPages[index], trackedIds: _trackedIds)),
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
        builder: (_) => const CupertinoPageScaffold(
          child: Center(child: Text('Page not found')),
        ),
      );
    }

    if (routeConfig.auth == true) {
      final authToken = stateManager.getGlobalState<String>('authToken');
      if (authToken == null || authToken.isEmpty) {
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
          builder: (_) => const CupertinoPageScaffold(
            child: Center(child: Text('Please log in')),
          ),
        );
      }
    }

    final page = contract!.pagesUI.pages[routeConfig.pageId];
    if (page == null) {
      return CupertinoPageRoute(
        builder: (_) => const CupertinoPageScaffold(
          child: Center(child: Text('Page configuration not found')),
        ),
      );
    }

    return CupertinoPageRoute(
      builder: (_) => EnhancedPageBuilder(config: page, trackedIds: _trackedIds),
      settings: settings,
    );
  }

  Widget _wrapWithRefresh(Widget child) {
    final provider = Provider.of<ContractProvider>(context);
    final hasError = provider.error != null;
    final errorBanner = hasError
        ? Container(
            color: CupertinoColors.destructiveRed.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(CupertinoIcons.exclamationmark_triangle, color: CupertinoColors.destructiveRed, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    provider.error!,
                    style: const TextStyle(color: CupertinoColors.destructiveRed, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  onPressed: provider.loading ? null : () => provider.refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    // Optional banner to indicate refresh disabled (e.g., offline or no backend URL)
    final refreshDisabledBanner = (!provider.canRefresh)
        ? Container(
            color: CupertinoColors.systemGrey6,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: const [
                Icon(CupertinoIcons.wifi_exclamationmark, color: CupertinoColors.inactiveGray, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pull-to-refresh unavailable (offline or no backend configured).',
                    style: TextStyle(color: CupertinoColors.secondaryLabel, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    // Debug-only analytics test trigger
    final devAnalyticsButton = kDebugMode
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: CupertinoColors.activeBlue,
              onPressed: () async {
                final svc = AnalyticsService();
                await svc.trackComponentInteraction(
                  componentId: 'test-button',
                  componentType: 'debug',
                  eventType: TrackingEventType.custom,
                  data: const {'tag': 'test'},
                );
                await svc.flush();
                // ignore: avoid_print
                print('Dev analytics: test event sent and flush requested');
              },
              child: const Text('Send Test Analytics'),
            ),
          )
        : const SizedBox.shrink();

    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: provider.canRefresh
              ? () => Provider.of<ContractProvider>(context, listen: false).refresh()
              : null,
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              errorBanner,
              refreshDisabledBanner,
              devAnalyticsButton,
              child,
            ],
          ),
        ),
      ],
    );
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;

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