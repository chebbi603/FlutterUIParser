// CLI tool to validate a JSON contract using ContractValidator.

import 'dart:convert';
import 'dart:io';

import 'package:demo_json_parser/validation/contract_validator.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: dart run tools/validate_contract.dart <path-to-contract.json>',
    );
    exit(2);
  }
  final path = args[0];
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('File not found: $path');
    exit(2);
  }

  try {
    final content = file.readAsStringSync();
    final contract = jsonDecode(content) as Map<String, dynamic>;
    final result = ContractValidator().validateContract(contract);
    stdout.writeln(result.isValid ? '✓ Valid' : '✗ Invalid');
    if (result.errors.isNotEmpty) {
      for (final e in result.errors) {
        stdout.writeln(e.toString());
      }
    }
    if (result.warnings.isNotEmpty) {
      for (final w in result.warnings) {
        stdout.writeln(w.toString());
      }
    }
    stdout.writeln(
      'Stats: pages=${result.stats.pages}, components=${result.stats.components}, actions=${result.stats.actions}',
    );
    exit(result.isValid ? 0 : 1);
  } catch (e) {
    stderr.writeln('Failed to parse or validate: $e');
    exit(2);
  }
}
