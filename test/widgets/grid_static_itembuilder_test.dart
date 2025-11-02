import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_json_parser/widgets/component_factory.dart';
import 'package:demo_json_parser/models/config_models.dart';

void main() {
  group('Grid component', () {
    testWidgets('renders static items via itemBuilder', (WidgetTester tester) async {
      final items = [
        {'title': 'Tech Talk Weekly'},
        {'title': 'Storytime Adventures'},
        {'title': 'Health Matters'},
      ];

      final gridConfig = EnhancedComponentConfig(
        type: 'grid',
        id: 'podcastsGrid',
        columns: 2,
        dataSource: EnhancedDataSourceConfig(type: 'static', items: items),
        itemBuilder: EnhancedComponentConfig(
          type: 'card',
          children: [
            EnhancedComponentConfig(
              type: 'text',
              text: r'${item.title}',
            ),
          ],
        ),
      );

      final widget = EnhancedComponentFactory.createComponent(gridConfig);

      await tester.pumpWidget(CupertinoApp(home: widget));
      await tester.pumpAndSettle();

      expect(find.text('Tech Talk Weekly'), findsOneWidget);
      expect(find.text('Storytime Adventures'), findsOneWidget);
      expect(find.text('Health Matters'), findsOneWidget);
    });
  });
}