import 'package:flutter_test/flutter_test.dart';
import 'package:demo_json_parser/models/config_models.dart';

void main() {
  group('EndpointConfig alias handling', () {
    test('authRequired and params aliases are recognized', () {
      final json = {
        'meta': {
          'appName': 'Demo',
          'version': '1.0.0',
          'schemaVersion': '1.0.0',
          'generatedAt': DateTime.now().toIso8601String(),
          'authors': ['test']
        },
        'services': {
          'AnalyticsService': {
            'baseUrl': 'http://localhost:8081/analytics',
            'endpoints': {
              'trackEvent': {
                'path': '/event',
                'method': 'POST',
                'authRequired': true,
                'params': {
                  'event': {'type': 'string', 'required': true},
                  'feature': {'type': 'string', 'required': true},
                  'action': {'type': 'string', 'required': true},
                }
              }
            }
          }
        },
        'pagesUI': {
          'routes': {'/': {'pageId': 'home'}},
          'pages': {
            'home': {
              'id': 'home',
              'title': 'Home',
              'layout': 'column',
              'children': []
            }
          }
        },
        'state': {
          'global': <String, dynamic>{},
          'pages': <String, dynamic>{},
        },
        'eventsActions': <String, dynamic>{},
        'themingAccessibility': <String, dynamic>{},
        'assets': <String, dynamic>{},
        'validations': <String, dynamic>{},
        'permissionsFlags': <String, dynamic>{},
        'pagination': <String, dynamic>{}
      };

      final contract = CanonicalContract.fromJson(Map<String, dynamic>.from(json));
      // Alias created from AnalyticsService -> analytics
      expect(contract.services.containsKey('analytics'), isTrue);
      final endpoint = contract.services['analytics']!.endpoints['trackEvent']!;
      expect(endpoint.auth, isTrue);
      expect(endpoint.queryParams, isNotNull);
      expect(endpoint.queryParams!.containsKey('event'), isTrue);
      expect(endpoint.queryParams!['feature']!.type, 'string');
    });

    test('retry alias is recognized as retryPolicy', () {
      final json = {
        'meta': {
          'appName': 'Demo',
          'version': '1.0.0',
          'schemaVersion': '1.0.0',
          'generatedAt': DateTime.now().toIso8601String(),
          'authors': ['test']
        },
        'services': [
          {
            'name': 'ContentService',
            'baseUrl': 'http://localhost:8081/content',
            'endpoints': [
              {
                'name': 'search',
                'method': 'GET',
                'path': '/search',
                'params': {'query': {'type': 'string', 'required': true}},
                'retry': 3
              }
            ]
          }
        ],
        'pagesUI': {
          'routes': {'/': {'pageId': 'home'}},
          'pages': {
            'home': {
              'id': 'home',
              'title': 'Home',
              'layout': 'column',
              'children': []
            }
          }
        },
        'state': {
          'global': <String, dynamic>{},
          'pages': <String, dynamic>{},
        },
        'eventsActions': <String, dynamic>{},
        'themingAccessibility': <String, dynamic>{},
        'assets': <String, dynamic>{},
        'validations': <String, dynamic>{},
        'permissionsFlags': <String, dynamic>{},
        'pagination': <String, dynamic>{}
      };

      final contract = CanonicalContract.fromJson(Map<String, dynamic>.from(json));
      final endpoint = contract.services['content']!.endpoints['search']!;
      expect(endpoint.retryPolicy, isNotNull);
      expect(endpoint.retryPolicy!.maxAttempts, 3);
      expect(endpoint.queryParams!.containsKey('query'), isTrue);
    });
  });
}