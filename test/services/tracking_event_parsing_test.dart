import 'package:flutter_test/flutter_test.dart';
import 'package:demo_json_parser/analytics/models/tracking_event.dart';

void main() {
  group('TrackingEvent.fromJson robustness', () {
    test('non-map data/context are handled with empty maps', () {
      final now = DateTime.now();
      final json = {
        'id': 'evt-1',
        'type': 'tap',
        'timestamp': now.toIso8601String(),
        'sessionId': 'sess-1',
        'data': 'oops-not-a-map',
        'context': 42,
      };

      final ev = TrackingEvent.fromJson(Map<String, dynamic>.from(json));
      expect(ev.data, isEmpty);
      expect(ev.context, isEmpty);
    });
  });
}