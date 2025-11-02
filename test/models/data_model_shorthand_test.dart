import 'package:flutter_test/flutter_test.dart';
import 'package:demo_json_parser/models/config_models.dart';

void main() {
  group('Parser shorthand support', () {
    test('FieldConfig accepts string type shorthand', () {
      expect(FieldConfig.fromJson('string').type, 'string');
      expect(FieldConfig.fromJson('integer').type, 'integer');
      expect(FieldConfig.fromJson('int').type, 'integer');
      expect(FieldConfig.fromJson('number').type, 'number');
      expect(FieldConfig.fromJson('boolean').type, 'boolean');
      expect(FieldConfig.fromJson('bool').type, 'boolean');
      expect(FieldConfig.fromJson('object').type, 'object');
      expect(FieldConfig.fromJson('map').type, 'object');
      expect(FieldConfig.fromJson('array').type, 'array');
      expect(FieldConfig.fromJson('list').type, 'array');
    });

    test('FieldConfig accepts enum list shorthand', () {
      final fc = FieldConfig.fromJson(['pending', 'done']);
      expect(fc.type, 'string');
      expect(fc.enumValues, isNotNull);
      expect(fc.enumValues, containsAll(['pending', 'done']));
    });

    test('DataModel.fromJson accepts fields as string/list/map', () {
      final dm = DataModel.fromJson({
        'fields': {
          'id': 'string',
          'status': ['new', 'in_progress', 'done'],
          'rating': {
            'type': 'number',
            'minimum': 0,
            'maximum': 5,
          },
        },
        'indexes': ['unique:id', 'status'],
      });
      expect(dm.fields['id']!.type, 'string');
      expect(dm.fields['status']!.enumValues, isNotNull);
      expect(dm.fields['status']!.enumValues!.length, 3);
      expect(dm.fields['rating']!.type, 'number');
      expect(dm.indexes.length, 2);
      expect(dm.indexes[0].unique, isTrue);
      expect(dm.indexes[0].fields, contains('id'));
      expect(dm.indexes[1].fields, contains('status'));
    });

    test('DataModel.fromJson accepts fields as list of entries', () {
      final dm = DataModel.fromJson({
        'fields': [
          {'name': 'id', 'type': 'string', 'required': true},
          'title',
          {'name': 'priority', 'enum': ['low', 'medium', 'high']},
        ],
        'relationships': ['User'],
      });
      expect(dm.fields['id']!.type, 'string');
      expect(dm.fields['title']!.type, 'string');
      expect(dm.fields['priority']!.enumValues, containsAll(['low', 'medium', 'high']));
      expect(dm.relationships.isNotEmpty, isTrue);
      final rel = dm.relationships.values.first;
      expect(rel.type, 'hasOne');
      expect(rel.model, 'User');
    });
  });
}