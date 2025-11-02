import 'package:flutter_test/flutter_test.dart';
import 'package:demo_json_parser/models/config_models.dart';

void main() {
  group('PagesUIConfig.fromJson robustness', () {
    test('handles non-map routes without throwing', () {
      final input = {
        'routes': 'notAMap',
        'pages': {
          'home': {
            'title': 'Home',
          },
        },
      };

      final cfg = PagesUIConfig.fromJson(Map<String, dynamic>.from(input));
      expect(cfg.routes, isEmpty);
      expect(cfg.pages, isNotEmpty);
    });

    test('handles non-map pages without throwing', () {
      final input = {
        'routes': {
          '/': {
            'pageId': 'home',
          },
        },
        'pages': 'notAMap',
      };

      final cfg = PagesUIConfig.fromJson(Map<String, dynamic>.from(input));
      expect(cfg.pages, isEmpty);
      expect(cfg.routes, isNotEmpty);
    });
  });
}