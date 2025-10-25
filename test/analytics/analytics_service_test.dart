import 'package:flutter_test/flutter_test.dart';
import 'package:demo_json_parser/analytics/services/analytics_service.dart';
import 'package:demo_json_parser/analytics/models/tracking_event.dart';

void main() {
  group('AnalyticsService tagging and linking', () {
    final service = AnalyticsService();

    setUp(() {
      service.events.clear();
      service.updateTaggingConfig(
        rageThreshold: 3,
        rageWindowMs: 1000,
        repeatThreshold: 3,
        formFailWindowMs: 10000,
      );
    });

    test('tags rage_click on rapid consecutive taps for same component', () {
      final now = DateTime.now();
      final compId = 'btn1';

      service.track(
        TrackingEvent(
          id: 't1',
          type: TrackingEventType.tap,
          componentId: compId,
          componentType: 'textButton',
          timestamp: now,
          sessionId: 's',
          data: {},
        ),
      );
      service.track(
        TrackingEvent(
          id: 't2',
          type: TrackingEventType.tap,
          componentId: compId,
          componentType: 'textButton',
          timestamp: now.add(const Duration(milliseconds: 200)),
          sessionId: 's',
          data: {},
        ),
      );
      service.track(
        TrackingEvent(
          id: 't3',
          type: TrackingEventType.tap,
          componentId: compId,
          componentType: 'textButton',
          timestamp: now.add(const Duration(milliseconds: 400)),
          sessionId: 's',
          data: {},
        ),
      );

      expect(service.events.length, 3);
      final last = service.events.last;
      expect(last.data['tag'], 'rage_click');
      expect(last.data['repeatCount'], 3);
    });

    test('tags rapid_repeat on repeated non-tap events', () {
      final now = DateTime.now();
      final compId = 'field1';

      for (int i = 0; i < 3; i++) {
        service.track(
          TrackingEvent(
            id: 'i$i',
            type: TrackingEventType.input,
            componentId: compId,
            componentType: 'textField',
            timestamp: now.add(Duration(milliseconds: 300 * i)),
            sessionId: 's',
            data: {},
          ),
        );
      }

      expect(service.events.length, 3);
      final last = service.events.last;
      expect(last.data['tag'], 'rapid_repeat');
      expect(last.data['repeatCount'], 3);
    });

    test('links error to latest form submit within window', () {
      final now = DateTime.now();
      final formId = 'formA';

      final submit = TrackingEvent(
        id: 'sub1',
        type: TrackingEventType.formSubmit,
        componentId: formId,
        componentType: 'form',
        timestamp: now,
        sessionId: 's',
        data: {},
      );
      service.track(submit);

      final error = TrackingEvent(
        id: 'err1',
        type: TrackingEventType.error,
        componentId: formId,
        componentType: 'form',
        timestamp: now.add(const Duration(milliseconds: 5000)),
        sessionId: 's',
        errorMessage: 'Bad Request',
        data: {},
      );
      service.track(error);

      expect(service.events.length, 2);
      // Submit event should be updated with failure info.
      expect(submit.data['result'], 'fail');
      expect(submit.data['error'], 'Bad Request');
    });
  });

  group('AnalyticsService flush behavior', () {
    final service = AnalyticsService();

    setUp(() {
      service.events.clear();
    });

    test('flush keeps events when backendUrl is not configured', () async {
      final e = TrackingEvent(
        id: 't0',
        type: TrackingEventType.tap,
        componentId: 'x',
        componentType: 'text',
        timestamp: DateTime.now(),
        sessionId: 's',
        data: {},
      );
      service.track(e);
      expect(service.events.length, 1);

      await service.flush();
      expect(service.events.length, 1, reason: 'Events should remain without backendUrl');
    });
  });
}