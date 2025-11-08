import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_json_parser/widgets/enhanced_page_builder.dart';
import 'package:demo_json_parser/models/config_models.dart';
import 'package:demo_json_parser/state/state_manager.dart';

void main() {
  testWidgets('Welcome Back shows username when available', (WidgetTester tester) async {
    final stateManager = EnhancedStateManager();
    await stateManager.setGlobalState('user', {
      'id': '507f1f77bcf86cd799439011',
      'username': 'demo_user',
      'name': 'Demo User',
    });

    final pageConfig = EnhancedPageConfig(
      id: 'home',
      title: 'Home',
      layout: 'scroll',
      style: StyleConfig(backgroundColor: '#FFFFFF'),
      children: [
        EnhancedComponentConfig(
          type: 'text',
          text: r'Welcome Back, ${state.user.username}',
          style: StyleConfig(use: 'title1'),
        ),
      ],
      columns: null,
      spacing: null,
    );

    await tester.pumpWidget(
      CupertinoApp(
        home: EnhancedPageBuilder(
          config: pageConfig,
          trackedIds: <String>{},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back, demo_user'), findsOneWidget);
  });
}