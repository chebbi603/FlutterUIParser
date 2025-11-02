import 'package:flutter_test/flutter_test.dart';
import 'package:demo_json_parser/models/config_models.dart';

void main() {
  group('EventsActionsConfig.fromJson robustness', () {
    test('handles non-map actions without throwing', () {
      final input = {
        'actions': 'notAMap',
      };

      final cfg = EventsActionsConfig.fromJson(Map<String, dynamic>.from(input));
      expect(cfg.actions, isEmpty);
      expect(cfg.onAppStart, isNull);
      expect(cfg.onLogin, isNull);
      expect(cfg.onLogout, isNull);
    });
  });
}