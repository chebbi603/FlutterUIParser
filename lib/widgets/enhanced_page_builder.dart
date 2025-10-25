import 'package:flutter/cupertino.dart';
import '../models/config_models.dart';
import 'component_factory.dart';
import '../analytics/services/analytics_service.dart';
import '../analytics/models/tracking_event.dart';
import '../analytics/widgets/component_tracker.dart';

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

    return CupertinoNavigationBar(
      middle: Text(navBar.title),
      trailing:
          navBar.actions != null && navBar.actions!.isNotEmpty
              ? Row(
                mainAxisSize: MainAxisSize.min,
                children:
                    navBar.actions!
                        .map(
                          (action) =>
                              _createTrackedComponent(action),
                        )
                        .toList(),
              )
              : null,
    );
  }

  Widget _buildBody() {
    final children =
        widget.config.children
            .map((child) => _createTrackedComponent(child))
            .toList();

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildCenterLayout(List<Widget> children) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;

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
