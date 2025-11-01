import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:demo_json_parser/providers/contract_provider.dart';
import 'package:demo_json_parser/services/contract_service.dart';
import 'package:demo_json_parser/models/contract_result.dart';

void main() {
  group('ContractProvider', () {
    test('loadCanonicalContract sets canonical and clears auth state', () async {
      final client = MockClient((request) async {
        expect(request.url.path, contains('/contracts/canonical'));
        final contract = {
          'meta': {'version': '1.0.0'},
          'pagesUI': {},
        };
        return http.Response(jsonEncode({'json': contract}), 200);
      });
      final service = ContractService(baseUrl: 'https://api.example.com', client: client);
      final provider = ContractProvider(service: service);

      expect(provider.loading, isFalse);
      await provider.loadCanonicalContract();
      expect(provider.loading, isFalse);
      expect(provider.error, isNull);
      expect(provider.contractSource, ContractSource.canonical);
      expect(provider.isPersonalized, isFalse);
      expect(provider.contractVersion, '1.0.0');
      expect(provider.contract, isNotNull);
    });

    test('loadUserContract with invalid parameters sets error', () async {
      final client = MockClient((request) async => http.Response('Bad', 400));
      final service = ContractService(baseUrl: 'https://api.example.com', client: client);
      final provider = ContractProvider(service: service);

      await provider.loadUserContract(userId: '', jwtToken: '');
      expect(provider.error, isNotNull);
      // Should not enter loading
      expect(provider.loading, isFalse);
    });

    test('loadUserContract success sets personalized', () async {
      final client = MockClient((request) async {
        if (request.url.path.contains('/users/user1/contract')) {
          final contract = {
            'meta': {'version': '2.0.0'},
            'pagesUI': {},
          };
          return http.Response(jsonEncode({'json': contract}), 200);
        }
        return http.Response('Unexpected', 500);
      });
      final service = ContractService(baseUrl: 'https://api.example.com', client: client);
      final provider = ContractProvider(service: service);

      await provider.loadUserContract(userId: 'user1', jwtToken: 'jwt');
      expect(provider.error, isNull);
      expect(provider.contractSource, ContractSource.personalized);
      expect(provider.contractVersion, '2.0.0');
    });

    test('loadUserContract 401 sets error and clears state', () async {
      final client = MockClient((request) async => http.Response('Unauthorized', 401));
      final service = ContractService(baseUrl: 'https://api.example.com', client: client);
      final provider = ContractProvider(service: service);

      await provider.loadUserContract(userId: 'user1', jwtToken: 'bad');
      expect(provider.contract, isNull);
      expect(provider.error, isNotNull);
      expect(provider.loading, isFalse);
    });

    test('refreshContract routes to personalized when auth state present', () async {
      var personalizedCalls = 0;
      final client = MockClient((request) async {
        if (request.url.path.contains('/users/user1/contract')) {
          personalizedCalls++;
          final contract = {
            'meta': {'version': '3.0.0'},
            'pagesUI': {},
          };
          return http.Response(jsonEncode({'json': contract}), 200);
        }
        if (request.url.path.contains('/contracts/canonical')) {
          final contract = {
            'meta': {'version': '1.0.0'},
            'pagesUI': {},
          };
          return http.Response(jsonEncode({'json': contract}), 200);
        }
        return http.Response('Unexpected', 500);
      });
      final service = ContractService(baseUrl: 'https://api.example.com', client: client);
      final provider = ContractProvider(service: service);

      // First load personalized to set internal auth state
      await provider.loadUserContract(userId: 'user1', jwtToken: 'jwt');
      expect(provider.contractVersion, '3.0.0');

      // Wait beyond debounce window then refresh; should route to personalized again
      await Future.delayed(const Duration(milliseconds: 1600));
      await provider.refreshContract();
      // Idempotent: avoids refetch when already personalized for same user
      expect(personalizedCalls, equals(1));
    });

    test('canRefresh reflects baseUrl sanity checks', () async {
      final localService = ContractService(baseUrl: 'http://localhost:8081', client: MockClient((_) async => http.Response('x', 500)));
      final providerLocal = ContractProvider(service: localService);
      expect(providerLocal.canRefresh, isFalse);

      final validService = ContractService(baseUrl: 'https://api.example.com', client: MockClient((_) async => http.Response('x', 500)));
      final providerValid = ContractProvider(service: validService);
      expect(providerValid.canRefresh, isTrue);
    });
  });
}