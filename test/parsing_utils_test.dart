import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_json_parser/utils/parsing_utils.dart';

void main() {
  group('ParsingUtils', () {
    test('parseColor named colors', () {
      expect(ParsingUtils.parseColor('red'), CupertinoColors.systemRed);
      expect(ParsingUtils.parseColor('blue'), CupertinoColors.systemBlue);
      expect(ParsingUtils.parseColor('green'), CupertinoColors.systemGreen);
      expect(ParsingUtils.parseColor('transparent'), Colors.transparent);
    });

    test('parseColor hex formats', () {
      // #RRGGBB -> assumes FF alpha
      final red = ParsingUtils.parseColor('#FF0000');
      expect(red, equals(const Color(0xFFFF0000)));

      // #RGB expands to #RRGGBB
      final green = ParsingUtils.parseColor('#0F0');
      expect(green, equals(const Color(0xFF00FF00)));

      // #AARRGGBB respects alpha
      final halfRed = ParsingUtils.parseColor('#80FF0000');
      expect(halfRed, equals(const Color(0x80FF0000)));
    });

    test('parseColor rgba()', () {
      final c = ParsingUtils.parseColor('rgba(255, 0, 0, 0.5)');
      expect(c, equals(const Color.fromRGBO(255, 0, 0, 0.5)));
    });

    test('parseKeyboardType mapping', () {
      expect(
        ParsingUtils.parseKeyboardType('email'),
        TextInputType.emailAddress,
      );
      expect(ParsingUtils.parseKeyboardType('number'), TextInputType.number);
      expect(ParsingUtils.parseKeyboardType('phone'), TextInputType.phone);
      expect(ParsingUtils.parseKeyboardType(null), TextInputType.text);
    });

    test('parseIcon common names and fallback', () {
      expect(ParsingUtils.parseIcon('plus'), CupertinoIcons.plus);
      expect(
        ParsingUtils.parseIcon('chevron_right'),
        CupertinoIcons.chevron_right,
      );
      expect(
        ParsingUtils.parseIcon('CupertinoIcons.search'),
        CupertinoIcons.search,
      );
      expect(ParsingUtils.parseIcon('unknown'), CupertinoIcons.circle);
    });

    test('safe conversions', () {
      expect(ParsingUtils.safeToDouble('3.14'), 3.14);
      expect(ParsingUtils.safeToDouble(5), 5.0);
      expect(ParsingUtils.safeToDouble(null), isNull);

      expect(ParsingUtils.safeToInt('42'), 42);
      expect(ParsingUtils.safeToInt(3.7), 3);
      expect(ParsingUtils.safeToInt(null), isNull);

      expect(ParsingUtils.safeToBool('true'), isTrue);
      expect(ParsingUtils.safeToBool('false'), isFalse);
      expect(ParsingUtils.safeToBool(1), isTrue);
      expect(ParsingUtils.safeToBool(0), isFalse);
      expect(ParsingUtils.safeToBool('yes'), isNull);
    });

    test('clampDouble and withDefault', () {
      expect(ParsingUtils.clampDouble(20, 0, 10, 5), 10);
      expect(ParsingUtils.clampDouble(-5, 0, 10, 5), 0);
      expect(ParsingUtils.clampDouble(null, 0, 10, 5), 5);

      expect(ParsingUtils.withDefault<String>(null, 'x'), 'x');
      expect(ParsingUtils.withDefault<int>(2, 1), 2);
    });

    test('parse axis alignments', () {
      expect(
        ParsingUtils.parseMainAxisAlignment('space_between'),
        MainAxisAlignment.spaceBetween,
      );
      expect(
        ParsingUtils.parseMainAxisAlignment('center'),
        MainAxisAlignment.center,
      );
      expect(ParsingUtils.parseMainAxisAlignment('unknown'), isNull);

      expect(
        ParsingUtils.parseCrossAxisAlignment('stretch'),
        CrossAxisAlignment.stretch,
      );
      expect(
        ParsingUtils.parseCrossAxisAlignment('center'),
        CrossAxisAlignment.center,
      );
      expect(ParsingUtils.parseCrossAxisAlignment('unknown'), isNull);
    });

    test('parseEdgeInsets with numeric', () {
      final e1 = ParsingUtils.parseEdgeInsets(10);
      final e2 = ParsingUtils.parseEdgeInsets(12.5);
      expect(e1, const EdgeInsets.all(10));
      expect(e2, const EdgeInsets.all(12.5));
    });
  });
}