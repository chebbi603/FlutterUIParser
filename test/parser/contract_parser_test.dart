import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_json_parser/validation/contract_validator.dart';

void main() {
  group('Contract parser and validator integration', () {
    test('canonical_contract.json loads and parses; validator runs', () {
      final jsonStr = File('assets/canonical_contract.json').readAsStringSync();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final result = ContractValidator().validateContract(data);
      expect(result.stats.pages, greaterThanOrEqualTo(1));
      expect(result.stats.components, greaterThanOrEqualTo(1));
      expect(result.errors, isA<List>());
    });

    test('invalid service schema triggers validation error', () {
      final jsonStr = File('assets/canonical_contract.json').readAsStringSync();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Inject a malformed responseSchema for a fake endpoint
      data['services'] ??= {};
      final services = data['services'] as Map<String, dynamic>;
      services['TestService'] = {
        'endpoints': {
          'badEndpoint': {
            'responseSchema': {
              'type': 'object',
              'properties': {
                'data':
                    'array', // invalid shorthand; should be an object with items and $ref
              },
            },
          },
        },
      };

      final result = ContractValidator().validateContract(data);
      expect(result.isValid, isFalse);
      expect(
        result.errors.any(
          (e) => e.path.contains(
            'services.TestService.endpoints.badEndpoint.responseSchema',
          ),
        ),
        isTrue,
      );
    });

    test('invalid route reference triggers error', () {
      final jsonStr = File('assets/canonical_contract.json').readAsStringSync();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      data['pagesUI'] ??= {};
      final pagesUi = data['pagesUI'] as Map<String, dynamic>;
      pagesUi['routes'] ??= {};
      final routes = pagesUi['routes'] as Map<String, dynamic>;
      routes['/broken'] = {'pageId': 'non_existing_page'};

      final result = ContractValidator().validateContract(data);
      expect(result.isValid, isFalse);
      expect(
        result.errors.any((e) => e.path == 'pagesUI.routes./broken'),
        isTrue,
      );
    });
  });
}
