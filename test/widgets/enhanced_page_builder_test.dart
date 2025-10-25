import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_json_parser/widgets/enhanced_page_builder.dart';
import 'package:demo_json_parser/models/config_models.dart';
import 'package:demo_json_parser/analytics/services/analytics_service.dart';
import 'package:demo_json_parser/analytics/widgets/component_tracker.dart';

void main() {
  group('EnhancedPageBuilder', () {
    setUp(() {
      AnalyticsService().events.clear();
    });

    testWidgets('wraps tracked components and emits tap', (WidgetTester tester) async {
      final page = EnhancedPageConfig(
        id: 'page1',
        title: 'Test Page',
        layout: 'column',
        children: [
          EnhancedComponentConfig(type: 'textButton', id: 'btn1', text: 'Click'),
          EnhancedComponentConfig(type: 'text', id: 'txt1', text: 'Hello'),
        ],
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: EnhancedPageBuilder(
            config: page,
            trackedIds: {'btn1'},
          ),
        ),
      );

      // Page enter event recorded
      expect(AnalyticsService().events.length, 1);

      // Only 'btn1' should be wrapped
      expect(find.byType(ComponentTracker), findsOneWidget);

      // Tap the tracked button and expect a tap event
      await tester.tap(find.text('Click'));
      await tester.pump();

      final events = AnalyticsService().events;
      expect(events.length, 2);
      expect(events.last.componentId, 'btn1');
      expect(events.last.type.toString().split('.').last, 'tap');
    });
  });
}