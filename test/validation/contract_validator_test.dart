import 'package:flutter_test/flutter_test.dart';
import 'package:demo_json_parser/validation/contract_validator.dart';

void main() {
  group('ContractValidator', () {
    test('valid minimal contract passes', () {
      final contract = {
        'meta': {'version': 1},
        'pagesUI': {
          'pages': {
            'home': {
              'children': [
                {'type': 'text', 'text': 'Hello'},
              ],
            },
          },
          'routes': {
            '/': {'pageId': 'home'},
          },
        },
      };
      final result = ContractValidator().validateContract(contract);
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
      expect(result.stats.pages, 1);
      expect(result.stats.components, 1);
      expect(result.stats.actions, 0);
    });

    test('unsupported component type errors', () {
      final contract = {
        'meta': {},
        'pagesUI': {
          'pages': {
            'home': {
              'children': [
                {'type': 'unknownWidget'},
              ],
            },
          },
        },
      };
      final result = ContractValidator().validateContract(contract);
      expect(result.isValid, isFalse);
      expect(
        result.errors
            .where(
              (e) => e.path.contains('pagesUI.pages.home.children[0].type'),
            )
            .length,
        1,
      );
    });

    test('apiCall requires service and endpoint', () {
      final contract = {
        'meta': {},
        'pagesUI': {
          'pages': {
            'home': {
              'children': [
                {
                  'type': 'button',
                  'onTap': {'action': 'apiCall'},
                },
              ],
            },
          },
        },
      };
      final result = ContractValidator().validateContract(contract);
      expect(result.isValid, isFalse);
      expect(
        result.errors.any(
          (e) => e.message.contains('apiCall requires service and endpoint'),
        ),
        isTrue,
      );
    });

    test(r'services responseSchema requires $ref to existing dataModels', () {
      // Valid: service endpoint has responseSchema.data.items with $ref to dataModels
      final goodContract = {
        'meta': {},
        'dataModels': {
          'post': {'type': 'object', 'properties': {}},
        },
        'services': {
          'BlogService': {
            'endpoints': {
              'listPosts': {
                'responseSchema': {
                  'type': 'object',
                  'properties': {
                    'data': {
                      'type': 'array',
                      'items': {'\$ref': '#/dataModels/post'},
                    },
                  },
                },
              },
            },
          },
        },
        'pagesUI': {
          'pages': {
            'home': {
              'children': [
                {
                  'type': 'button',
                  'onTap': {
                    'action': 'apiCall',
                    'service': 'BlogService',
                    'endpoint': 'listPosts',
                  },
                },
              ],
            },
          },
        },
      };
      final okResult = ContractValidator().validateContract(goodContract);
      expect(okResult.isValid, isTrue);

      // Invalid: endpoint uses shorthand 'data': 'array' instead of JSON Schema with $ref
      final badContract = {
        'meta': {},
        'dataModels': {
          'post': {'type': 'object', 'properties': {}},
        },
        'services': {
          'BlogService': {
            'endpoints': {
              'badEndpoint': {
                'responseSchema': {
                  'type': 'object',
                  'properties': {'data': 'array'},
                },
              },
            },
          },
        },
        'pagesUI': {
          'pages': {
            'home': {
              'children': [
                {
                  'type': 'button',
                  'onTap': {
                    'action': 'apiCall',
                    'service': 'BlogService',
                    'endpoint': 'badEndpoint',
                  },
                },
              ],
            },
          },
        },
      };
      final badResult = ContractValidator().validateContract(
        badContract as Map<String, dynamic>,
      );
      expect(badResult.isValid, isFalse);
      expect(
        badResult.errors.any(
          (e) => e.path.contains(
            'services.BlogService.endpoints.badEndpoint.responseSchema',
          ),
        ),
        isTrue,
      );
    });

    test('state persistence policy validation', () {
      final contract = {
        'meta': {},
        'state': {
          'global': {
            'username': {
              'type': 'string',
              'default': '',
              'persistence': 'device',
            },
          },
        },
        'pagesUI': {
          'pages': {
            'home': {'children': []},
          },
        },
      };
      final result = ContractValidator().validateContract(contract);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.path.endsWith('.persistence')), isTrue);
    });

    test('routes cross-reference must point to existing page', () {
      final contract = {
        'meta': {},
        'pagesUI': {
          'pages': {
            'home': {'children': []},
          },
          'routes': {
            '/missing': {'pageId': 'unknown'},
          },
        },
      };
      final result = ContractValidator().validateContract(contract);
      expect(result.isValid, isFalse);
      expect(
        result.errors.any((e) => e.path.startsWith('pagesUI.routes')),
        isTrue,
      );
    });

    test('performance: validates 1000 simple components under 150ms', () {
      final children = List.generate(
        1000,
        (i) => {'type': 'text', 'text': 'Item $i'},
      );
      final contract = {
        'meta': {},
        'pagesUI': {
          'pages': {
            'home': {'children': children},
          },
        },
      };
      final validator = ContractValidator();
      final sw = Stopwatch()..start();
      final result = validator.validateContract(contract);
      sw.stop();
      expect(result.isValid, isTrue);
      // Aim for fast validation; allow small buffer for CI variance
      expect(
        sw.elapsedMilliseconds < 150,
        isTrue,
        reason: 'Took ${sw.elapsedMilliseconds}ms',
      );
    });
  });
}
