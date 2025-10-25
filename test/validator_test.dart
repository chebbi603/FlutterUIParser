import 'package:flutter_test/flutter_test.dart';
import 'package:demo_json_parser/validation/validator.dart';
import 'package:demo_json_parser/models/config_models.dart';

void main() {
  test('ValidationRuleConfig supports required', () {
    final ruleRequired = ValidationRuleConfig(
      required: true,
      message: 'Required',
    );
    final validator = EnhancedValidator();
    validator.initialize(
      ValidationsConfig(rules: {'req': ruleRequired}, crossField: {}),
    );

    expect(validator.validateWithRule('req', '').isValid, false);
    expect(validator.validateWithRule('req', 'ok').isValid, true);
  });
}
