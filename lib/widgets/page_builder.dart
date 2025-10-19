import 'package:flutter/cupertino.dart';
import '../models/config_models.dart';
import 'component_factory.dart';

/// Enhanced page builder with advanced layout and navigation support
class EnhancedPageBuilder extends StatelessWidget {
  final EnhancedPageConfig config;

  const EnhancedPageBuilder({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    Widget body = _buildBody();

    // Apply page-level styling
    if (config.style != null) {
      body = Container(
        color: _parseColor(config.style!.backgroundColor),
        padding: config.style!.padding?.toEdgeInsets(),
        child: body,
      );
    }

    // Wrap with navigation bar if configured
    if (config.navigationBar != null) {
      return CupertinoPageScaffold(
        navigationBar: _buildNavigationBar(),
        child: SafeArea(child: body),
      );
    }

    return CupertinoPageScaffold(child: SafeArea(child: body));
  }

  CupertinoNavigationBar _buildNavigationBar() {
    final navBar = config.navigationBar!;

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
                              EnhancedComponentFactory.createComponent(action),
                        )
                        .toList(),
              )
              : null,
    );
  }

  Widget _buildBody() {
    final children =
        config.children
            .map((child) => EnhancedComponentFactory.createComponent(child))
            .toList();

    switch (config.layout.toLowerCase()) {
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
