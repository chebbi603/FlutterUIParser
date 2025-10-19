import 'dart:convert';
import 'dart:io';

import 'package:contract_validator/contract_validator.dart';

void _printUsage() {
  stdout.writeln('Usage: dart run contract_validator:validate_contract --contract <path> [--schema <path>]');
  stdout.writeln('Examples:');
  stdout.writeln('  dart run bin/validate_contract.dart --contract ../assets/canonical_contract.json');
  stdout.writeln('  dart run bin/validate_contract.dart --contract <file> --schema ../assets/canonical_contract.schema.json');
}

Map<String, String> _parseArgs(List<String> args) {
  final map = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--contract' && i + 1 < args.length) {
      map['contract'] = args[++i];
    } else if (a == '--schema' && i + 1 < args.length) {
      map['schema'] = args[++i];
    } else if (a == '--help' || a == '-h') {
      map['help'] = 'true';
    }
  }
  return map;
}

Future<void> main(List<String> args) async {
  final opts = _parseArgs(args);
  if (opts['help'] == 'true' || !opts.containsKey('contract')) {
    _printUsage();
    exitCode = 2;
    return;
  }

  final contractPath = opts['contract']!;
  final schemaPath = opts['schema'];

  if (!File(contractPath).existsSync()) {
    stderr.writeln('Error: contract file not found at $contractPath');
    exitCode = 2;
    return;
  }

  Map<String, dynamic> contract;
  try {
    final text = await File(contractPath).readAsString();
    contract = jsonDecode(text) as Map<String, dynamic>;
  } catch (e) {
    stderr.writeln('Error: failed to read/parse contract: $e');
    exitCode = 2;
    return;
  }

  Map<String, dynamic>? schema;
  if (schemaPath != null) {
    if (!File(schemaPath).existsSync()) {
      stderr.writeln('Warning: schema file not found at $schemaPath; continuing without schema.');
    } else {
      try {
        final text = await File(schemaPath).readAsString();
        schema = jsonDecode(text) as Map<String, dynamic>;
      } catch (e) {
        stderr.writeln('Warning: failed to read/parse schema: $e; continuing without schema.');
      }
    }
  }

  final result = ContractValidator.validate(contract, schema: schema);

  if (result.warnings.isNotEmpty) {
    stdout.writeln('Warnings (${result.warnings.length}):');
    for (final w in result.warnings) {
      stdout.writeln(' - [${w.severity.toUpperCase()}] ${w.path}: ${w.message}');
    }
    stdout.writeln('');
  }

  if (result.errors.isNotEmpty) {
    stdout.writeln('Errors (${result.errors.length}):');
    for (final e in result.errors) {
      stdout.writeln(' - [${e.severity.toUpperCase()}] ${e.path}: ${e.message}');
    }
    stdout.writeln('\nValidation failed.');
    exitCode = 1;
  } else {
    stdout.writeln('Validation passed.');
    exitCode = 0;
  }
}