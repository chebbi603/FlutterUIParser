import 'package:flutter_test/flutter_test.dart';
import 'package:demo_json_parser/engine/graph_engine.dart';

void main() {
  test('GraphEngine subscriptions and notifications', () {
    final graph = GraphEngine();
    graph.registerNode('theme', NodeType.state);
    graph.registerNode('comp1', NodeType.component);
    graph.subscribe('theme', 'comp1');
    final ticker = graph.getComponentTicker('comp1')!;
    final initial = ticker.value;
    graph.setComponentVisible('comp1', true);
    graph.notifyStateChange('theme');
    expect(ticker.value, initial + 1);
  });

  test('GraphEngine cycle detection prevents cycles', () {
    final graph = GraphEngine();
    graph.registerNode('a', NodeType.state);
    graph.registerNode('b', NodeType.component);
    graph.addEdge('a', 'b');
    // Creating cycle b -> a should throw
    expect(() => graph.addEdge('b', 'a'), throwsA(isA<StateError>()));
  });
}