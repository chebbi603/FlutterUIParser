import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:demo_json_parser/services/contract_service.dart';
import 'package:demo_json_parser/models/contract_result.dart';

void main() {
  group('ContractService.fetchCanonicalContract', () {
    test('returns canonical from primary endpoint with wrapper json', () async {
      final mock = MockClient((request) async {
        expect(request.url.path, contains('/contracts/canonical'));
        expect(request.headers['Accept'], 'application/json');
        final contract = {
          'meta': {'version': '1.2.3'},
          'pagesUI': {},
        };
        return http.Response(jsonEncode({'json': contract}), 200, headers: {
          'content-type': 'application/json',
        });
      });

      final service = ContractService(baseUrl: 'https://api.example.com', client: mock);
      final result = await service.fetchCanonicalContract();
      expect(result.source, ContractSource.canonical);
      expect(result.version, '1.2.3');
      expect(result.contract['meta']['version'], '1.2.3');
    });

    test('falls back to /contracts/public/canonical when primary fails', () async {
      var callCount = 0;
      final mock = MockClient((request) async {
        callCount++;
        if (request.url.path.contains('/contracts/canonical')) {
          return http.Response('Not Found', 404);
        }
        expect(request.url.path, contains('/contracts/public/canonical'));
        final contract = {
          'meta': {'version': '9.9.9'},
          'pagesUI': {},
        };
        return http.Response(jsonEncode(contract), 200);
      });

      final service = ContractService(baseUrl: 'https://api.example.com', client: mock);
      final result = await service.fetchCanonicalContract();
      expect(callCount, greaterThanOrEqualTo(2));
      expect(result.source, ContractSource.canonical);
      expect(result.version, '9.9.9');
    });

    test('throws when both endpoints fail', () async {
      final mock = MockClient((request) async {
        if (request.url.path.contains('/contracts/canonical')) {
          return http.Response('Server Error', 500);
        }
        return http.Response('Server Error', 500);
      });

      final service = ContractService(baseUrl: 'https://api.example.com', client: mock);
      expect(service.fetchCanonicalContract(), throwsA(isA<Exception>()));
    });

    test('primary returns malformed JSON (array) then fallback succeeds', () async {
      final mock = MockClient((request) async {
        if (request.url.path.contains('/contracts/canonical')) {
          // Status 200 but body is array → FormatException → fallback path
          return http.Response(jsonEncode([]), 200);
        }
        final contract = {
          'meta': {'version': '2.0.0'},
          'pagesUI': {},
        };
        return http.Response(jsonEncode({'json': contract}), 200);
      });

      final service = ContractService(baseUrl: 'https://api.example.com', client: mock);
      final result = await service.fetchCanonicalContract();
      expect(result.source, ContractSource.canonical);
      expect(result.version, '2.0.0');
    });
  });

  group('ContractService.fetchUserContract', () {
    test('returns personalized contract with auth header', () async {
      final mock = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer token123');
        expect(request.headers['Accept'], 'application/json');
        expect(request.url.path, contains('/users/abc123/contract'));
        final contract = {
          'meta': {'version': '3.1.4'},
          'pagesUI': {},
        };
        return http.Response(jsonEncode({'json': contract}), 200);
      });

      final service = ContractService(baseUrl: 'https://api.example.com', client: mock);
      final result = await service.fetchUserContract(userId: 'abc123', jwtToken: 'token123');
      expect(result.source, ContractSource.personalized);
      expect(result.version, '3.1.4');
      expect(result.userId, 'abc123');
    });

    test('throws AuthenticationException on 401', () async {
      final mock = MockClient((request) async => http.Response('Unauthorized', 401));
      final service = ContractService(baseUrl: 'https://api.example.com', client: mock);

      expect(
        service.fetchUserContract(userId: 'abc123', jwtToken: 'bad'),
        throwsA(isA<AuthenticationException>()),
      );
    });

    test('404 falls back to canonical', () async {
      var calledCanonical = false;
      final mock = MockClient((request) async {
        if (request.url.path.contains('/users/abc123/contract')) {
          return http.Response('Not Found', 404);
        }
        // Fallback canonical
        calledCanonical = true;
        final contract = {
          'meta': {'version': '7.7.7'},
          'pagesUI': {},
        };
        return http.Response(jsonEncode({'json': contract}), 200);
      });

      final service = ContractService(baseUrl: 'https://api.example.com', client: mock);
      final result = await service.fetchUserContract(userId: 'abc123', jwtToken: 'token');
      expect(calledCanonical, isTrue);
      expect(result.source, ContractSource.canonical);
      expect(result.version, '7.7.7');
    });

    test('malformed JSON causes FormatException to propagate', () async {
      final mock = MockClient((request) async => http.Response(jsonEncode([]), 200));
      final service = ContractService(baseUrl: 'https://api.example.com', client: mock);
      expect(
        service.fetchUserContract(userId: 'abc123', jwtToken: 'token'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}