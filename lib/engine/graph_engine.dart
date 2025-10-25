import 'package:flutter/foundation.dart';

/// Node types that participate in the rendering/data/action graph.
enum NodeType { component, state, dataSource, action }

/// Base graph node.
class GraphNode {
  final String id;
  final NodeType type;
  GraphNode(this.id, this.type);
}

/// A lightweight graph engine (DAG) to track dependencies and propagate updates.
/// - Nodes: components, state keys, data sources, actions
/// - Edges: directed dependencies (A -> B means B depends on A)
/// - Subscriptions: components subscribe to state keys and data source updates
/// - Visibility-aware: only notify visible components
class GraphEngine extends ChangeNotifier {
  static final GraphEngine _instance = GraphEngine._internal();
  factory GraphEngine() => _instance;
  GraphEngine._internal();

  final Map<String, GraphNode> _nodes = {};
  final Map<String, Set<String>> _edges = {}; // from -> {to}

  /// Subscription from a state or data node to component ids.
  final Map<String, Set<String>> _subscriptions = {};

  /// Component-local tick notifiers to trigger rebuilds.
  final Map<String, ValueNotifier<int>> _componentTicks = {};

  /// Visible components set to support lazy notifications.
  final Set<String> _visibleComponents = <String>{};

  /// Register a node in the graph.
  void registerNode(String id, NodeType type) {
    if (!_nodes.containsKey(id)) {
      _nodes[id] = GraphNode(id, type);
    }
    _edges.putIfAbsent(id, () => <String>{});
  }

  /// Add a dependency edge (from -> to). Returns true if added.
  /// Throws if it introduces a cycle.
  bool addEdge(String fromId, String toId) {
    registerNode(fromId, _nodes[fromId]?.type ?? NodeType.state);
    registerNode(toId, _nodes[toId]?.type ?? NodeType.component);
    final added = _edges[fromId]!.add(toId);
    if (added && _hasCycle()) {
      // revert and throw
      _edges[fromId]!.remove(toId);
      throw StateError(
        'Graph cycle detected when adding edge $fromId -> $toId',
      );
    }
    return added;
  }

  /// Subscribe a component to updates from a node (typically state or data).
  void subscribe(String sourceNodeId, String componentId) {
    registerNode(sourceNodeId, _nodes[sourceNodeId]?.type ?? NodeType.state);
    registerNode(componentId, _nodes[componentId]?.type ?? NodeType.component);
    _subscriptions.putIfAbsent(sourceNodeId, () => <String>{}).add(componentId);
    _componentTicks.putIfAbsent(componentId, () => ValueNotifier<int>(0));
    addEdge(sourceNodeId, componentId);
  }

  /// Unsubscribe a component.
  void unsubscribe(String sourceNodeId, String componentId) {
    final subs = _subscriptions[sourceNodeId];
    subs?.remove(componentId);
  }

  /// Mark a component as visible to enable lazy notifications.
  void setComponentVisible(String componentId, bool visible) {
    if (visible) {
      _visibleComponents.add(componentId);
    } else {
      _visibleComponents.remove(componentId);
    }
  }

  /// Notify that a state key has changed (e.g., `theme`, `volume`, etc.).
  void notifyStateChange(String stateKeyPath) {
    _notifySource(stateKeyPath);
  }

  /// Notify that a data source has updated.
  void notifyDataSourceChange(String dataSourceId) {
    _notifySource(dataSourceId);
  }

  void _notifySource(String sourceId) {
    final targets = _subscriptions[sourceId];
    if (targets == null || targets.isEmpty) {
      // Global change for any listeners that care.
      notifyListeners();
      return;
    }

    // Compute ordered targets using topological sort restricted to reachable nodes
    final orderedTargets = _topologicalOrderFrom(
      sourceId,
    ).where(_visibleComponents.contains);
    for (final componentId in orderedTargets) {
      final tick = _componentTicks[componentId];
      if (tick != null) {
        tick.value = tick.value + 1;
      }
    }

    // Global change for any listeners that care.
    notifyListeners();
  }

  /// Access a component tick notifier to rebuild subscribers cheaply.
  ValueNotifier<int>? getComponentTicker(String componentId) {
    return _componentTicks[componentId];
  }

  /// Perform cycle detection using DFS.
  bool _hasCycle() {
    final visited = <String>{};
    final stack = <String>{};

    bool dfs(String node) {
      if (stack.contains(node)) return true; // back-edge
      if (visited.contains(node)) return false;
      visited.add(node);
      stack.add(node);
      for (final next in _edges[node] ?? const <String>{}) {
        if (dfs(next)) return true;
      }
      stack.remove(node);
      return false;
    }

    for (final node in _nodes.keys) {
      if (dfs(node)) return true;
    }
    return false;
  }

  /// Topological order of nodes reachable from `sourceId`, excluding non-reachable nodes.
  /// Returns a list of componentIds ordered such that dependencies come before dependents.
  List<String> _topologicalOrderFrom(String sourceId) {
    final visited = <String, int>{}; // 0=unvisited,1=visiting,2=visited
    final result = <String>[];

    void dfs(String node) {
      final state = visited[node] ?? 0;
      if (state == 2) return; // already processed
      if (state == 1) return; // should not happen in DAG due to cycle guard
      visited[node] = 1;
      for (final next in _edges[node] ?? const <String>{}) {
        dfs(next);
      }
      visited[node] = 2;
      // Only append component nodes (targets)
      if (_nodes[node]?.type == NodeType.component) {
        result.add(node);
      }
    }

    dfs(sourceId);
    return result;
  }
}
