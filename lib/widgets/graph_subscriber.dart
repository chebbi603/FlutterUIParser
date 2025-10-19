import 'package:flutter/cupertino.dart';
import '../engine/graph_engine.dart';

/// Wraps a component widget and rebuilds when its dependent sources update.
class GraphSubscriber extends StatefulWidget {
  final String componentId;
  final List<String> dependencies; // state keys or data source ids
  final WidgetBuilder builder;

  const GraphSubscriber({
    super.key,
    required this.componentId,
    required this.dependencies,
    required this.builder,
  });

  @override
  State<GraphSubscriber> createState() => _GraphSubscriberState();
}

class _GraphSubscriberState extends State<GraphSubscriber> {
  final GraphEngine _graph = GraphEngine();
  ValueNotifier<int>? _ticker;

  @override
  void initState() {
    super.initState();
    for (final dep in widget.dependencies) {
      _graph.subscribe(dep, widget.componentId);
    }
    _ticker = _graph.getComponentTicker(widget.componentId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mark visible on first build
    _graph.setComponentVisible(widget.componentId, true);
  }

  @override
  void dispose() {
    for (final dep in widget.dependencies) {
      _graph.unsubscribe(dep, widget.componentId);
    }
    _graph.setComponentVisible(widget.componentId, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticker = _ticker;
    if (ticker == null) {
      // If no ticker yet, register one and render child
      return widget.builder(context);
    }
    return ValueListenableBuilder<int>(
      valueListenable: ticker,
      builder: (_, __, ___) {
        return widget.builder(context);
      },
    );
  }
}