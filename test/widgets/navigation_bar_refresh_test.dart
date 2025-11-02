import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:demo_json_parser/widgets/enhanced_page_builder.dart';
import 'package:demo_json_parser/models/config_models.dart';
import 'package:demo_json_parser/providers/contract_provider.dart';
import 'package:demo_json_parser/services/contract_service.dart';

class TestContractProvider extends ContractProvider {
  bool refreshed = false;
  TestContractProvider({required ContractService service}) : super(service: service);
  @override
  Future<void> refreshContract() async {
    refreshed = true;
  }
}

void main() {
  group('Navigation bar version and refresh', () {
    late TestContractProvider provider;

    setUp(() {
      provider = TestContractProvider(
        service: ContractService(baseUrl: 'https://api.example.com'),
      );
    });

    EnhancedPageConfig _makePage() {
      return EnhancedPageConfig(
        id: 'home',
        title: 'Home',
        layout: 'column',
        navigationBar: EnhancedNavigationBarConfig(title: 'Home'),
        children: const [],
        style: null,
      );
    }

    Widget _wrap(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<TestContractProvider>.value(value: provider),
          ChangeNotifierProvider<ContractProvider>.value(value: provider),
        ],
        child: CupertinoApp(home: child),
      );
    }

    testWidgets('shows contract version and refresh button when allowed', (tester) async {
      final page = _makePage();
      await tester.pumpWidget(_wrap(EnhancedPageBuilder(config: page, trackedIds: {})));

      // Version label defaults to 'unknown'
      expect(find.text('v unknown'), findsOneWidget);

      // Refresh icon is present when canRefresh is true
      expect(find.byIcon(CupertinoIcons.refresh), findsOneWidget);

      // Tapping refresh triggers provider method
      await tester.tap(find.byIcon(CupertinoIcons.refresh));
      await tester.pump();
      expect(provider.refreshed, isTrue);
    });
  });
}