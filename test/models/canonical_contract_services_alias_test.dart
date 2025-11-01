import 'package:flutter_test/flutter_test.dart';
import 'package:demo_json_parser/models/config_models.dart';

void main() {
  group('CanonicalContract services aliasing', () {
    test('creates lowercase alias without Service suffix', () {
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
            'name': 'AuthService',
            'baseUrl': 'http://localhost:8081/auth',
            'endpoints': [
              {
                'name': 'login',
                'method': 'POST',
                'path': '/login',
              }
            ]
          }
        ],
        'pagesUI': {
          'routes': {'/': {'pageId': 'home'}},
          'pages': {'home': {'id': 'home', 'title': 'Home', 'layout': 'column', 'children': []}}
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

      final contract = CanonicalContract.fromJson(json);
      // Original key preserved
      expect(contract.services.containsKey('AuthService'), isTrue);
      // Alias key created
      expect(contract.services.containsKey('auth'), isTrue);

      final svc = contract.services['auth']!;
      expect(svc.baseUrl, 'http://localhost:8081/auth');
      expect(svc.endpoints.containsKey('login'), isTrue);
      expect(svc.endpoints['login']!.path, '/login');
      expect(svc.endpoints['login']!.method.toUpperCase(), 'POST');
    });

    test('does not override existing explicit alias', () {
      final json = {
        'meta': {
          'appName': 'Demo',
          'version': '1.0.0',
          'schemaVersion': '1.0.0',
          'generatedAt': DateTime.now().toIso8601String(),
          'authors': ['test']
        },
        'services': {
          'AuthService': {
            'baseUrl': 'http://localhost:8081/auth',
            'endpoints': {
              'login': {'path': '/login', 'method': 'POST'}
            }
          },
          'auth': {
            'baseUrl': 'http://override',
            'endpoints': {
              'login': {'path': '/override', 'method': 'POST'}
            }
          }
        },
        'pagesUI': {
          'routes': {'/': {'pageId': 'home'}},
          'pages': {'home': {'id': 'home', 'title': 'Home', 'layout': 'column', 'children': []}}
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

      final contract = CanonicalContract.fromJson(json);
      // Both keys available
      expect(contract.services.containsKey('AuthService'), isTrue);
      expect(contract.services.containsKey('auth'), isTrue);
      // Explicit alias not overridden
      expect(contract.services['auth']!.baseUrl, 'http://override');
      expect(contract.services['auth']!.endpoints['login']!.path, '/override');
    });
  });
}