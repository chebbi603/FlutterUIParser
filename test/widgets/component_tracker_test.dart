import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_json_parser/analytics/widgets/component_tracker.dart';
import 'package:demo_json_parser/analytics/services/analytics_service.dart';

void main() {
  group('ComponentTracker', () {
    setUp(() {
      AnalyticsService().events.clear();
    });

    testWidgets('emits tap event to AnalyticsService', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ComponentTracker(
                componentId: 'comp1',
                componentType: 'text',
                child: Container(
                  width: 120,
                  height: 48,
                  alignment: Alignment.center,
                  color: Colors.blue,
                  child: const Text('Tap'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(AnalyticsService().events, isEmpty);

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      final events = AnalyticsService().events;
      expect(events.length, 1);
      expect(events.last.componentId, 'comp1');
      expect(events.last.type.toString().split('.').last, 'tap');
    });
  });
}