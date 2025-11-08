import 'package:demo_json_parser/models/config_models.dart';
import 'package:demo_json_parser/widgets/enhanced_page_builder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Page-level grid renders with correct columns and spacing', (tester) async {
    final pageConfig = EnhancedPageConfig(
      id: 'home',
      title: 'Home',
      layout: 'scroll', // should switch to GridView when columns/spacing provided
      columns: 3,
      spacing: 12.0,
      children: [
        EnhancedComponentConfig(
          id: 'c1',
          type: 'text',
          text: 'One',
        ),
        EnhancedComponentConfig(
          id: 'c2',
          type: 'text',
          text: 'Two',
        ),
        EnhancedComponentConfig(
          id: 'c3',
          type: 'text',
          text: 'Three',
        ),
      ],
    );

    await tester.pumpWidget(
      CupertinoApp(
        home: EnhancedPageBuilder(
          config: pageConfig,
          trackedIds: {},
        ),
      ),
    );

    // Ensure a GridView is used as the body
    final gridFinder = find.byType(GridView);
    expect(gridFinder, findsOneWidget);

    final grid = tester.widget<GridView>(gridFinder);
    expect(grid.gridDelegate, isA<SliverGridDelegateWithFixedCrossAxisCount>());
    final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, equals(3));
    expect(delegate.crossAxisSpacing, equals(12.0));
    expect(delegate.mainAxisSpacing, equals(12.0));

    // Ensure children rendered
    expect(find.text('One'), findsOneWidget);
    expect(find.text('Two'), findsOneWidget);
    expect(find.text('Three'), findsOneWidget);
  });
}