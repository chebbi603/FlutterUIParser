import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_json_parser/widgets/component_factory.dart';
import 'package:demo_json_parser/models/config_models.dart';

void main() {
  group('Row spacing', () {
    testWidgets('applies SizedBox spacing between children', (WidgetTester tester) async {
      final rowConfig = EnhancedComponentConfig(
        type: 'row',
        spacing: 12,
        children: [
          EnhancedComponentConfig(type: 'text', text: 'A'),
          EnhancedComponentConfig(type: 'text', text: 'B'),
          EnhancedComponentConfig(type: 'text', text: 'C'),
        ],
      );

      final widget = EnhancedComponentFactory.createComponent(rowConfig);

      await tester.pumpWidget(const CupertinoApp(home: SizedBox(child: Placeholder())));
      await tester.pumpWidget(CupertinoApp(home: widget));
      await tester.pumpAndSettle();

      final spacedBoxesFinder = find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == 12,
      );
      expect(spacedBoxesFinder, findsNWidgets(2));
    });
  });
}