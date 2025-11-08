import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
// Environment resolution now happens in main.dart; no dotenv import needed here
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
import 'models/contract_result.dart' show ContractSource;
import 'persistence/state_persistence.dart';
import 'screens/offline_screen.dart';
import 'analytics/services/analytics_service.dart';
import 'analytics/models/tracking_event.dart';
import 'middleware/auth_gate.dart';
// Removed UI diagnostic scanner import; no dev-only overlays in production UI

// Note: AnalyticsService configuration now happens when contract loads inside MyApp.

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  CanonicalContract? contract;

  final EnhancedStateManager stateManager = EnhancedStateManager();
  final ContractApiService apiService = ContractApiService();
  final PermissionManager permissionManager = PermissionManager();
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  CupertinoTabController? _tabController;
  Set<String> _trackedIds = {};
  OverlayEntry? _toastEntry;
  String? _currentVersion;
  ContractSource? _currentSource;
  String? _lastAuthToken;
  String? _lastUserId;
  bool _isRefreshing = false;
  AuthGate? _authGate;
  bool _tabTrackingAttached = false;

  @override
  void initState() {
    super.initState();
    // Observe app lifecycle to flush analytics on background/foreground transitions
    WidgetsBinding.instance.addObserver(this);
    // React to auth token/user changes to refresh contract on login/logout
    stateManager.addListener(_onStateChanged);
    // Attach provider listener and decide initial contract (user first, fallback canonical)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachProviderListener();
      unawaited(_bootLoadInitialContract());
    });
  }

  @override
  void dispose() {
    // Detach listeners and clean up controllers/overlays
    WidgetsBinding.instance.removeObserver(this);
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final analytics = AnalyticsService();
    switch (state) {
      case AppLifecycleState.resumed:
        analytics.trackPageNavigation(
          pageId: 'app',
          eventType: TrackingEventType.appForeground,
        );
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        analytics.trackPageNavigation(
          pageId: 'app',
          eventType: TrackingEventType.appBackground,
        );
        analytics.flush();
        break;
      case AppLifecycleState.detached:
        // No-op
        break;
    }
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
      final newSource = provider.contractSource;
      // Apply on first load or version change
      final shouldApply = (_currentVersion == null || newVersion != _currentVersion) ||
          (newSource != null && newSource != _currentSource);
      if (shouldApply) {
        unawaited(_applyUpdatedContract(updated));
        // Track latest source after applying
        _currentSource = newSource;
      }
    }
  }

  /// Boot-time contract selection: try personalized first, fallback to canonical.
  Future<void> _bootLoadInitialContract() async {
    if (!mounted) return;
    try {
      final provider = Provider.of<ContractProvider>(context, listen: false);
      // Read persisted auth token and user from secure storage first
      final secure = SecureStoragePersistence();
      await secure.init();
      final dynamic tokenRaw = await secure.read('state:global:authToken');
      String? authToken;
      if (tokenRaw is String) {
        authToken = tokenRaw;
      } else if (tokenRaw != null) {
        authToken = tokenRaw.toString();
      }
      final dynamic userRaw = await secure.read('state:global:user');
      String? userId;
      if (userRaw is Map<String, dynamic>) {
        userId = userRaw['id']?.toString();
      } else if (userRaw is String && userRaw.isNotEmpty) {
        try {
          final parsed = jsonDecode(userRaw);
          if (parsed is Map<String, dynamic>) {
            userId = parsed['id']?.toString();
          }
        } catch (_) {}
      }

      // Fallback to shared preferences if secure storage did not have values
      if (authToken == null || authToken.isEmpty || userId == null || userId.isEmpty) {
        final prefs = SharedPrefsPersistence();
        await prefs.init();
        final dynamic tokenLocal = await prefs.read('state:global:authToken');
        if ((authToken == null || authToken.isEmpty) && tokenLocal is String) {
          authToken = tokenLocal;
        }
        final dynamic userLocal = await prefs.read('state:global:user');
        if (userLocal is Map<String, dynamic>) {
          userId = userLocal['id']?.toString();
        } else if (userLocal is String && userLocal.isNotEmpty) {
          try {
            final parsed = jsonDecode(userLocal);
            if (parsed is Map<String, dynamic>) {
              userId = parsed['id']?.toString();
            }
          } catch (_) {}
        }
      }

      if (authToken != null && authToken.isNotEmpty && userId != null && userId.isNotEmpty) {
        await provider.loadUserContract(userId: userId!, jwtToken: authToken!);
      } else {
        await provider.loadCanonicalContract();
      }
    } catch (_) {
      if (!mounted) return;
      try {
        final provider = Provider.of<ContractProvider>(context, listen: false);
        await provider.loadCanonicalContract();
      } catch (_) {}
    }
  }

  Future<void> _initializeWithContract(CanonicalContract loadedContract, {bool initState = true}) async {
    if (initState) {
      await stateManager.initialize(loadedContract.state);
    }
    // Ensure sessionId exists for analytics grouping
    final existingSessionId = stateManager.getGlobalState<String>('sessionId');
    if (existingSessionId == null || existingSessionId.isEmpty) {
      final sid = _generateSessionId();
      await stateManager.setGlobalState('sessionId', sid);
    }
    apiService.initialize(loadedContract);
    permissionManager.initialize(loadedContract.permissionsFlags);
    EnhancedComponentFactory.initialize(loadedContract);

    _authGate = AuthGate(stateManager: stateManager);
    await _authGate!.init();

    // Attach auth service and restore persisted tokens
    final authService = AuthService(stateManager, apiService);
    apiService.attachAuthService(authService);
    // Provide ContractProvider to AuthService for post-login/logout contract switching
    try {
      final provider = Provider.of<ContractProvider>(context, listen: false);
      authService.attachContractProvider(provider);
      // Provide ContractProvider to AuthGate for dynamic route protection
      _authGate?.attachContractProvider(provider);
      // Allow ContractProvider to attempt token refresh on 401 via AuthService
      provider.attachAuthService(authService);
    } catch (_) {}
    final persistedAccess = stateManager.getGlobalState<String>('authToken');
    // Attempt to load a personalized contract at startup when persisted login exists.
    // Only trigger if current provider source is canonical or unset to avoid redundant loops.
    try {
      final provider = Provider.of<ContractProvider>(context, listen: false);
      final persistedUser = stateManager.getGlobalState<Map<String, dynamic>>('user');
      final persistedUserId = persistedUser?['id']?.toString();
      final source = provider.contractSource;
      if ((source == null || source == ContractSource.canonical) &&
          persistedAccess != null && persistedAccess.isNotEmpty &&
          persistedUserId != null && persistedUserId.isNotEmpty) {
        unawaited(_attemptApiRefresh());
      }
    } catch (_) {}
    if (persistedAccess != null && persistedAccess.isNotEmpty) {
      apiService.setAuthToken(persistedAccess);
    }

    // Removed debug auto-login behavior to prevent unintended authentication on startup

    // Set tracked component ids for analytics widgets; actual AnalyticsService
    // configuration happens here once a contract is available.
    _trackedIds = loadedContract.analytics?.trackedComponents.toSet() ?? {};

    // Configure analytics backend if provided by contract, with safe normalization
    var analyticsBackend = loadedContract.analytics?.backendUrl?.trim();
    // Normalize localhost port to 8081 if misconfigured and ensure canonical /events path
    if (analyticsBackend != null && analyticsBackend.isNotEmpty) {
      final parsed = Uri.tryParse(analyticsBackend);
      if (parsed != null) {
        final isLocalHost = parsed.host == 'localhost' || parsed.host == '127.0.0.1';
        final needsPortFix = isLocalHost && parsed.port == 8082; // backend runs on 8081
        // Coerce common misconfigurations to canonical '/events'
        final path = parsed.path;
        final needsPathFix =
            path.isEmpty ||
            path == '/' ||
            path == '/analytics' ||
            path == '/analytics/' ||
            path.endsWith('/analytics/events');
        if (needsPortFix || needsPathFix) {
          final fixed = Uri(
            scheme: parsed.scheme.isNotEmpty ? parsed.scheme : 'http',
            host: parsed.host,
            port: needsPortFix ? 8081 : (parsed.hasPort ? parsed.port : 8081),
            path: '/events',
          );
          analyticsBackend = fixed.toString();
        }
      }
    }
    // Safe default when contract omits analytics backend
    analyticsBackend ??= 'http://localhost:8081/events';
    if (analyticsBackend.isNotEmpty) {
      final analytics = AnalyticsService();
      analytics.configure(backendUrl: analyticsBackend);
      // Attach context providers for attribution
      try {
        final provider = Provider.of<ContractProvider>(context, listen: false);
        analytics.attachContractProvider(provider);
      } catch (_) {}
      analytics.attachStateManager(stateManager);
      if (kDebugMode) {
        // Allow initial page events (e.g., landing_page_viewed) to be tracked
        // then flush a small baseline batch so ingestion can be verified.
        Future.delayed(const Duration(seconds: 2), () {
          analytics.flushPublicBaseline();
        });
      }
    }

    // Execute app start events (simplified logging)
    if (loadedContract.eventsActions.onAppStart != null) {
      for (final action in loadedContract.eventsActions.onAppStart!) {
        debugPrint('Executing startup action: ${action.action}');
      }
    }
  }

  String _generateSessionId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rnd = (ts ^ (ts >> 3)) & 0xFFFF;
    return 'sess_${ts}_$rnd';
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

  bool _isAuthed() {
    try {
      final token = stateManager.getGlobalState<String>('authToken');
      // Consider user authenticated when a non-empty auth token exists.
      // Some backends may not return a user id on login; gating should be token-based.
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _logAuthCheck(String routeName, bool allowed) {
    final analytics = AnalyticsService();
    analytics.logAuthEvent('auth_check', {
      'route': routeName,
      'allowed': allowed,
    });
  }

  Widget _buildLoginPageWidget() {
    final loginRoute = contract!.pagesUI.routes['/login'];
    if (loginRoute != null) {
      final page = contract!.pagesUI.pages[loginRoute.pageId];
      if (page != null) {
        // Analytics: login page viewed
        AnalyticsService().logAuthEvent('login_page_viewed', {
          'source': 'navigation',
        });
        return _wrapWithRefresh(EnhancedPageBuilder(config: page, trackedIds: _trackedIds));
      }
    }
    return const CupertinoPageScaffold(
      child: Center(child: Text('Please log in')),
    );
  }

  Route<dynamic> _buildLoginRoute(RouteSettings? settings) {
    final widget = _buildLoginPageWidget();
    return CupertinoPageRoute(builder: (_) => widget, settings: settings);
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
    final themeMode = stateManager.getGlobalState<String>('theme') ?? 'light';
    // Align 'system' to 'light' for now to avoid null maps
    final selectedMode = themeMode.toLowerCase() == 'system' ? 'light' : themeMode;
    final isDark = selectedMode.toLowerCase() == 'dark';

    final tokens = contract!.themingAccessibility.tokens[selectedMode] ?? {};
    final primary = _parseHexColor(tokens['primary'] ?? (isDark ? '#0A84FF' : '#007AFF'));
    final surface = _parseHexColor(tokens['surface'] ?? (isDark ? '#1C1C1E' : '#FFFFFF'));
    final background = _parseHexColor(tokens['background'] ?? (isDark ? '#000000' : '#F8F9FA'));
    final onSurface = _parseHexColor(tokens['onSurface'] ?? (isDark ? '#FFFFFF' : '#121212'));

    final typo = contract!.themingAccessibility.typography;
    TextStyle baseText = const TextStyle(fontSize: 17, fontWeight: FontWeight.w400);
    if (typo.containsKey('body')) {
      final body = typo['body']!;
      baseText = baseText.copyWith(
        fontSize: (body.fontSize ?? 17).toDouble(),
        fontWeight: _mapFontWeight(body.fontWeight),
        color: onSurface,
      );
    } else {
      baseText = baseText.copyWith(color: onSurface);
    }

    final title1 = typo['title1'];
    final navTitle = (title1 != null)
        ? baseText.copyWith(
            fontSize: (title1.fontSize ?? 28).toDouble(),
            fontWeight: _mapFontWeight(title1.fontWeight),
          )
        : baseText.copyWith(fontSize: 28, fontWeight: FontWeight.w600);

    final textTheme = CupertinoTextThemeData(
      textStyle: baseText,
      actionTextStyle: baseText.copyWith(color: primary),
      tabLabelTextStyle: baseText.copyWith(fontSize: 12),
      navTitleTextStyle: navTitle,
    );

    return CupertinoThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: primary ?? (isDark ? CupertinoColors.systemBlue : CupertinoColors.activeBlue),
      barBackgroundColor: surface ?? (isDark ? CupertinoColors.darkBackgroundGray : CupertinoColors.systemBackground),
      scaffoldBackgroundColor: background ?? (isDark ? CupertinoColors.black : CupertinoColors.systemGroupedBackground),
      textTheme: textTheme,
    );
  }

  FontWeight _mapFontWeight(String? fw) {
    switch (fw?.toLowerCase()) {
      case 'thin':
        return FontWeight.w100;
      case 'extralight':
      case 'ultralight':
        return FontWeight.w200;
      case 'light':
        return FontWeight.w300;
      case 'regular':
      case 'normal':
        return FontWeight.w400;
      case 'medium':
        return FontWeight.w500;
      case 'semibold':
      case 'demibold':
        return FontWeight.w600;
      case 'bold':
        return FontWeight.w700;
      case 'extrabold':
      case 'heavy':
        return FontWeight.w800;
      case 'black':
        return FontWeight.w900;
      default:
        return FontWeight.w400;
    }
  }

  Widget _buildHome() {
    final pagesUI = contract!.pagesUI;

    if (pagesUI.bottomNavigation?.enabled == true) {
      // Bottom navigation should only be visible when inside the app.
      // Prefer explicit contract flag; default to requiring auth.
      final bottomNav = pagesUI.bottomNavigation!;
      final requiresAuth = bottomNav.authRequired ?? true;
      final allowed = !requiresAuth || _isAuthed();
      _logAuthCheck('bottomNavigation', allowed);
      if (!allowed) {
        return _buildLoginPageWidget();
      }
      return _buildTabbedHome();
    }

    final homeRoute = pagesUI.routes['/'];
    if (homeRoute != null) {
      final page = pagesUI.pages[homeRoute.pageId];
      if (page != null) {
        final requiresAuth = _authGate?.isRouteProtected('/') ?? false;
        final allowed = !requiresAuth || _isAuthed();
        _logAuthCheck('/', allowed);
        if (!allowed) {
          return _buildLoginPageWidget();
        }
        // Analytics: landing page viewed at app start
        AnalyticsService().logAuthEvent('landing_page_viewed', {
          'source': 'app_start',
        });
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
      EnhancedPageConfig? page;
      if (item.pageId.isNotEmpty) {
        page = pages[item.pageId];
      } else if (item.route != null && item.route!.isNotEmpty) {
        final rc = contract!.pagesUI.routes[item.route!];
        if (rc != null) {
          page = pages[rc.pageId];
        }
      }
      return page ?? pages.values.first;
    }).toList();

    final Map<String, int> routeToIndex = {};
    for (var i = 0; i < bottomNav.items.length; i++) {
      final item = bottomNav.items[i];
      // If item specifies a route, map directly
      if (item.route != null && item.route!.isNotEmpty) {
        routeToIndex[item.route!] = i;
      } else {
        // Otherwise, infer from routes matching pageId
        contract!.pagesUI.routes.forEach((routeName, routeConfig) {
          if (routeConfig.pageId == item.pageId) {
            routeToIndex[routeName] = i;
          }
        });
      }
    }

    NavigationBridge.tabController = _tabController;
    NavigationBridge.routeToIndex = routeToIndex;
    // Wire auth checks for tab navigation enforcement
    NavigationBridge.isRouteProtected = (route) => _authGate?.isRouteProtected(route) ?? false;
    NavigationBridge.isAuthed = () => _isAuthed();

    // Attach one-time listener to track bottom navigation changes
    if (!_tabTrackingAttached) {
      _tabController!.addListener(() {
        final idx = _tabController!.index;
        if (idx == null) return;
        if (idx < 0 || idx >= bottomNav.items.length) return;
        final item = bottomNav.items[idx];
        final pageId = tabPages[idx].id;
        final key = item.route ?? (item.pageId.isNotEmpty ? item.pageId : item.title);
        final componentId = 'bottom_nav_item_${idx}_${key}';
        AnalyticsService().trackComponentInteraction(
          componentId: componentId,
          componentType: 'bottomNavItem',
          eventType: TrackingEventType.routeChange,
          pageId: pageId,
          data: {
            'title': item.title,
            if (item.route != null) 'route': item.route,
          },
        );
        // Immediately flush to backend so tab changes are visible without delay
        // Flush is a no-op if backendUrl isn't configured or queue is empty
        AnalyticsService().flush();
      });
      _tabTrackingAttached = true;
    }

    return CupertinoTabScaffold(
      controller: _tabController,
      tabBar: CupertinoTabBar(
        currentIndex: bottomNav.initialIndex,
        backgroundColor: _parseColor(bottomNav.style?.backgroundColor) ?? CupertinoTheme.of(context).barBackgroundColor,
        activeColor: _parseColor(bottomNav.style?.foregroundColor) ?? CupertinoTheme.of(context).primaryColor,
        inactiveColor: _parseColor(bottomNav.style?.color) ?? (CupertinoTheme.of(context).textTheme.tabLabelTextStyle.color ?? CupertinoColors.inactiveGray),
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
          builder: (_) => EnhancedPageBuilder(config: tabPages[index], trackedIds: _trackedIds),
          onGenerateRoute: _generateRoute,
        );
      },
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    final routeName = settings.name ?? '/';
    final routeConfig = contract!.pagesUI.routes[routeName];
    if (routeName == '/home') {
      final requiresAuth = _authGate?.isRouteProtected('/home') ?? false;
      final allowed = !requiresAuth || _isAuthed();
      _logAuthCheck('/home', allowed);
      if (!allowed) {
        AnalyticsService().logAuthEvent('login_page_viewed', {
          'source': 'deep_link',
          'attemptedRoute': routeName,
        });
        return _buildLoginRoute(settings);
      }
    }

    if (routeConfig == null) {
      return CupertinoPageRoute(
        builder: (_) => const CupertinoPageScaffold(
          child: Center(child: Text('Page not found')),
        ),
      );
    }

    final requiresAuth = _authGate?.isRouteProtected(routeName) ?? false;
    final allowed = !requiresAuth || _isAuthed();
    _logAuthCheck(routeName, allowed);
    if (!allowed) {
      AnalyticsService().logAuthEvent('login_page_viewed', {
        'source': 'redirect_from_protected',
        'attemptedRoute': routeName,
      });
      return _buildLoginRoute(settings);
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
    // Contract-first: no extra banners, overlays, or pull-to-refresh
    return child;
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;

    if (colorString.startsWith('\${theme.') && colorString.endsWith('}')) {
      final tokenName = colorString.substring(8, colorString.length - 1);
      final themeMode = stateManager.getGlobalState<String>('theme') ?? 'light';
      final selectedMode = themeMode.toLowerCase() == 'system' ? 'light' : themeMode;
      final themeTokens = contract!.themingAccessibility.tokens[selectedMode];
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