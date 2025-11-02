import 'package:flutter/cupertino.dart';
import '../utils/parsing_utils.dart';
import '../models/config_models.dart';
import 'component_factory.dart';
import '../analytics/services/analytics_service.dart';
import '../analytics/models/tracking_event.dart';
import '../analytics/widgets/component_tracker.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:provider/provider.dart';
import '../providers/contract_provider.dart';

/// Enhanced page builder with advanced layout and navigation support
class EnhancedPageBuilder extends StatefulWidget {
  final EnhancedPageConfig config;
  final Set<String> trackedIds;

  const EnhancedPageBuilder({super.key, required this.config, required this.trackedIds});

  @override
  State<EnhancedPageBuilder> createState() => _EnhancedPageBuilderState();
}

class _EnhancedPageBuilderState extends State<EnhancedPageBuilder> {
  final AnalyticsService _analytics = AnalyticsService();

  @override
  void initState() {
    super.initState();
    // Track page entry
    _trackPageEntry();
  }

  @override
  void dispose() {
    // Track page exit
    _trackPageExit();
    super.dispose();
  }

  void _trackPageEntry() {
    if (kDebugMode) {
      final bg = widget.config.style?.backgroundColor;
      final compCount = widget.config.children.length;
      debugPrint("[diag][page] enter id=${widget.config.id} layout=${widget.config.layout} components=$compCount bg=${bg ?? '-'}");
    }
    _analytics.trackPageNavigation(
      pageId: widget.config.id,
      eventType: TrackingEventType.pageEnter,
    );
  }

  void _trackPageExit() {
    _analytics.trackPageNavigation(
      pageId: widget.config.id,
      eventType: TrackingEventType.pageExit,
    );
  }

  /// Create component and wrap with ComponentTracker when ID is tracked
  Widget _createTrackedComponent(EnhancedComponentConfig config) {
    final child = EnhancedComponentFactory.createComponent(config);

    if (kDebugMode) {
      final hasBg = config.style?.backgroundColor != null;
      final hasBinding = (config.text?.contains(r'${') ?? false) ||
          (config.binding?.contains(r'${') ?? false) ||
          (config.style?.color?.contains(r'${') ?? false) ||
          (config.style?.backgroundColor?.contains(r'${') ?? false) ||
          (config.style?.foregroundColor?.contains(r'${') ?? false);
      debugPrint("[diag][component] page=${widget.config.id} type=${config.type} id=${config.id ?? '-'} bg=${hasBg ? 'yes' : 'no'} binding=${hasBinding ? 'yes' : 'no'}");
    }

    final id = config.id;
    if (id != null && widget.trackedIds.contains(id)) {
      return ComponentTracker(
        componentId: id,
        componentType: config.type,
        pageId: widget.config.id,
        child: child,
      );
    }

    return child;
  }

  @override
  Widget build(BuildContext context) {
    Widget body = _buildBody();

    // Apply page-level styling
    if (widget.config.style != null) {
      body = Container(
        color: _parseColor(widget.config.style!.backgroundColor),
        padding: widget.config.style!.padding?.toEdgeInsets(),
        child: body,
      );
    }

    // Wrap with navigation bar if configured
    if (widget.config.navigationBar != null) {
      return CupertinoPageScaffold(
        navigationBar: _buildNavigationBar(),
        child: SafeArea(child: body),
      );
    }

    return CupertinoPageScaffold(child: SafeArea(child: body));
  }

  CupertinoNavigationBar _buildNavigationBar() {
    final navBar = widget.config.navigationBar!;

    // Build existing actions
    final actionWidgets = (navBar.actions != null && navBar.actions!.isNotEmpty)
        ? navBar.actions!
            .map((action) => _createTrackedComponent(action))
            .toList()
        : <Widget>[];

    // Contract provider for version display and refresh capability
    final contractProvider = Provider.of<ContractProvider>(context);
    final versionText = Text(
      'v ${contractProvider.contractVersion}',
      style: CupertinoTheme.of(context).textTheme.textStyle,
      overflow: TextOverflow.ellipsis,
    );
    final refreshButton = contractProvider.canRefresh
        ? CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => contractProvider.refreshContract(),
            child: const Icon(CupertinoIcons.refresh),
          )
        : const SizedBox.shrink();

    final trailingChildren = <Widget>[];
    trailingChildren.addAll(actionWidgets);
    if (actionWidgets.isNotEmpty) {
      trailingChildren.add(const SizedBox(width: 8));
    }
    trailingChildren.add(versionText);
    if (contractProvider.canRefresh) {
      trailingChildren.add(const SizedBox(width: 8));
      trailingChildren.add(refreshButton);
    }

    return CupertinoNavigationBar(
      middle: Text(navBar.title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: trailingChildren,
      ),
    );
  }

  Widget _buildBody() {
    final children =
        widget.config.children
            .map((child) => _createTrackedComponent(child))
            .toList();

    if (kDebugMode && children.isEmpty) {
      debugPrint('[diag][page] WARN empty body pageId=${widget.config.id}');
    }

    switch (widget.config.layout.toLowerCase()) {
      case 'scroll':
        return _buildScrollLayout(children);
      case 'center':
        return _buildCenterLayout(children);
      case 'column':
      default:
        return _buildColumnLayout(children);
    }
  }

  Widget _buildScrollLayout(List<Widget> children) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildCenterLayout(List<Widget> children) {
    return Center(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }

  Widget _buildColumnLayout(List<Widget> children) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) return null;

    if (kDebugMode && colorString.contains(r'${')) {
      debugPrint('[diag][page] background binding detected value="$colorString"');
    }

    // Resolve theme tokens via component factory, then parse using ParsingUtils
    final resolved = EnhancedComponentFactory.resolveToken(colorString);
    if (resolved == null || resolved.isEmpty) return null;
    return ParsingUtils.parseColor(resolved);
  }
}
