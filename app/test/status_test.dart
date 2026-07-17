import 'dart:convert';

import 'package:beehive_monitor_app/models/status.dart';
import 'package:beehive_monitor_app/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> validPayload() => {
  'status': 'local_response',
  'temperature': 25.1,
  'humidity': 61.0,
  'light': 100.0,
  'pressure': 1008.2,
  'soundLevel': 28,
  'mq2Raw': 1150,
  'uptime': 42,
  'overallLabel': 'reference',
  'labels': {
    'temperature': 'reference',
    'humidity': 'reference',
    'light': 'reference',
    'sound': 'reference',
    'mq2': 'reference',
    'pressure': 'reference',
  },
  'temperatureValid': true,
  'humidityValid': true,
  'lightValid': true,
  'pressureValid': true,
  'soundValid': true,
  'mq2Valid': true,
  'bh1750_ok': true,
  'bmp280_ok': true,
  'pressureTrend': null,
  'pressureTrendKind': 'unknown',
  'pressureHistoryCount': 1,
};

void main() {
  test('accepts the complete fixed local-response contract', () {
    final payload = StatusPayload.tryParse(jsonEncode(validPayload()));
    expect(payload, isNotNull);
    expect(payload!.temperatureValid, isTrue);
    expect(payload.labels.temperature, 'reference');
  });

  test('rejects an incomplete response instead of showing reference data', () {
    final json = validPayload()..remove('mq2Valid');
    expect(StatusPayload.tryParse(jsonEncode(json)), isNull);
  });

  test('accepts unavailable values only with matching validity flags', () {
    final json = validPayload()
      ..['temperature'] = null
      ..['temperatureValid'] = false
      ..['soundLevel'] = -1
      ..['soundValid'] = false
      ..['mq2Raw'] = -1
      ..['mq2Valid'] = false
      ..['labels'] = {
        'temperature': 'unavailable',
        'humidity': 'reference',
        'light': 'reference',
        'sound': 'unavailable',
        'mq2': 'unavailable',
        'pressure': 'reference',
      }
      ..['overallLabel'] = 'unavailable';
    final payload = StatusPayload.tryParse(jsonEncode(json));
    expect(payload, isNotNull);
    expect(payload!.temperature, isNull);
    expect(payload.mq2Valid, isFalse);
  });

  test('rejects contradictory validity, labels, and sentinels', () {
    final contradictory = validPayload()
      ..['temperature'] = 20.0
      ..['temperatureValid'] = false;
    expect(StatusPayload.tryParse(jsonEncode(contradictory)), isNull);

    final invalidLabel = validPayload()
      ..['temperature'] = null
      ..['temperatureValid'] = false;
    (invalidLabel['labels'] as Map<String, dynamic>)['temperature'] =
        'reference';
    expect(StatusPayload.tryParse(jsonEncode(invalidLabel)), isNull);

    final invalidSentinel = validPayload()..['soundLevel'] = -1;
    expect(StatusPayload.tryParse(jsonEncode(invalidSentinel)), isNull);

    final unknown = validPayload();
    (unknown['labels'] as Map<String, dynamic>)['mq2'] = 'ok';
    expect(StatusPayload.tryParse(jsonEncode(unknown)), isNull);
  });

  test('rejects non-canonical IPv4 octets before any HTTP request', () async {
    final service = BeehiveApiService();
    final hosts = [
      ['010', '0', '0', '1'].join('.'),
      ['0177', '0', '0', '1'].join('.'),
      ['192', '168', '001', '1'].join('.'),
    ];
    for (final host in hosts) {
      await expectLater(
        service.fetchStatus(host),
        throwsA(isA<BeehiveApiException>()),
      );
    }
  });
}
