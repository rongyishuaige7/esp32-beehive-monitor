import 'dart:convert';

/// Mirrors the fixed teaching API in firmware/src/web_server.cpp.
class StatusPayload {
  StatusPayload({
    required this.status,
    required this.temperature,
    required this.humidity,
    required this.light,
    required this.pressure,
    required this.soundLevel,
    required this.mq2Raw,
    required this.uptime,
    required this.overallLabel,
    required this.labels,
    required this.temperatureValid,
    required this.humidityValid,
    required this.lightValid,
    required this.pressureValid,
    required this.soundValid,
    required this.mq2Valid,
    required this.bh1750Ok,
    required this.bmp280Ok,
    required this.pressureTrend,
    required this.pressureTrendKind,
    required this.pressureHistoryCount,
    this.errorMessage,
  });

  final String status;
  final double? temperature;
  final double? humidity;
  final double? light;
  final double? pressure;
  final int? soundLevel;
  final int? mq2Raw;
  final int? uptime;
  final String overallLabel;
  final SensorLabels labels;
  final bool temperatureValid;
  final bool humidityValid;
  final bool lightValid;
  final bool pressureValid;
  final bool soundValid;
  final bool mq2Valid;
  final bool bh1750Ok;
  final bool bmp280Ok;
  final String? errorMessage;
  final double? pressureTrend;
  final String pressureTrendKind;
  final int? pressureHistoryCount;

  /// Rejects incomplete, malformed, or label-unknown JSON rather than
  /// converting it into a superficially positive local response.
  static StatusPayload? tryParse(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      final labelsJson = decoded['labels'];
      if (labelsJson is! Map<String, dynamic>) return null;
      final labels = SensorLabels.tryParse(labelsJson);
      if (labels == null) return null;
      final status = _knownString(decoded['status'], {'local_response'});
      final overallLabel = _knownString(decoded['overallLabel'], _knownLabels);
      final pressureTrendKind = _knownString(
        decoded['pressureTrendKind'],
        _knownPressureTrendKinds,
      );
      final temperatureValid = decoded['temperatureValid'];
      final humidityValid = decoded['humidityValid'];
      final lightValid = decoded['lightValid'];
      final pressureValid = decoded['pressureValid'];
      final soundValid = decoded['soundValid'];
      final mq2Valid = decoded['mq2Valid'];
      final bh1750Ok = decoded['bh1750_ok'];
      final bmp280Ok = decoded['bmp280_ok'];
      if (status == null ||
          overallLabel == null ||
          pressureTrendKind == null ||
          temperatureValid is! bool ||
          humidityValid is! bool ||
          lightValid is! bool ||
          pressureValid is! bool ||
          soundValid is! bool ||
          mq2Valid is! bool ||
          bh1750Ok is! bool ||
          bmp280Ok is! bool) {
        return null;
      }
      final temperature = _parseDouble(decoded['temperature']);
      final humidity = _parseDouble(decoded['humidity']);
      final light = _parseDouble(decoded['light']);
      final pressure = _parseDouble(decoded['pressure']);
      final soundLevel = _parseInt(decoded['soundLevel']);
      final mq2Raw = _parseInt(decoded['mq2Raw']);
      final uptime = _parseInt(decoded['uptime']);
      final pressureHistoryCount = _parseInt(decoded['pressureHistoryCount']);
      if ((temperatureValid && temperature == null) ||
          (!temperatureValid && temperature != null) ||
          (humidityValid && humidity == null) ||
          (!humidityValid && humidity != null) ||
          (lightValid && light == null) ||
          (!lightValid && light != null) ||
          (pressureValid && pressure == null) ||
          (!pressureValid && pressure != null) ||
          soundLevel == null ||
          mq2Raw == null ||
          uptime == null ||
          pressureHistoryCount == null ||
          soundLevel < -1 ||
          mq2Raw < -1 ||
          uptime < 0 ||
          pressureHistoryCount < 0 ||
          (!soundValid && soundLevel != -1) ||
          (soundValid && soundLevel < 0) ||
          (!mq2Valid && mq2Raw != -1) ||
          (mq2Valid && mq2Raw < 0) ||
          !_labelMatchesValidity(labels.temperature, temperatureValid) ||
          !_labelMatchesValidity(labels.humidity, humidityValid) ||
          !_labelMatchesValidity(labels.light, lightValid) ||
          !_labelMatchesValidity(labels.pressure, pressureValid) ||
          !_labelMatchesValidity(labels.sound, soundValid) ||
          !_labelMatchesValidity(labels.mq2, mq2Valid) ||
          (overallLabel == 'unavailable' &&
              !{
                temperatureValid,
                humidityValid,
                lightValid,
                pressureValid,
                soundValid,
                mq2Valid,
              }.contains(false)) ||
          (overallLabel != 'unavailable' &&
              {
                temperatureValid,
                humidityValid,
                lightValid,
                pressureValid,
                soundValid,
                mq2Valid,
              }.contains(false))) {
        return null;
      }
      return StatusPayload(
        status: status,
        temperature: temperature,
        humidity: humidity,
        light: light,
        pressure: pressure,
        soundLevel: soundLevel,
        mq2Raw: mq2Raw,
        uptime: uptime,
        overallLabel: overallLabel,
        labels: labels,
        temperatureValid: temperatureValid,
        humidityValid: humidityValid,
        lightValid: lightValid,
        pressureValid: pressureValid,
        soundValid: soundValid,
        mq2Valid: mq2Valid,
        bh1750Ok: bh1750Ok,
        bmp280Ok: bmp280Ok,
        errorMessage: decoded['message'] is String
            ? decoded['message'] as String
            : null,
        pressureTrend: _parseDouble(decoded['pressureTrend']),
        pressureTrendKind: pressureTrendKind,
        pressureHistoryCount: pressureHistoryCount,
      );
    } catch (_) {
      // The caller reports a concise parse failure without storing response data.
      return null;
    }
  }

  static const Set<String> _knownLabels = {
    'reference',
    'attention',
    'high_threshold',
    'unavailable',
  };
  static const Set<String> _knownPressureTrendKinds = {
    'unknown',
    'stable',
    'rising',
    'falling',
    'larger_rise',
    'larger_fall',
    'rapid_fall',
  };

  static String? _knownString(dynamic value, Set<String> accepted) =>
      value is String && accepted.contains(value) ? value : null;

  static bool _labelMatchesValidity(String label, bool valid) =>
      valid ? label != 'unavailable' : label == 'unavailable';

  static double? _parseDouble(dynamic value) {
    if (value is num) {
      final parsed = value.toDouble();
      return parsed.isFinite ? parsed : null;
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed != null && parsed.isFinite ? parsed : null;
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class SensorLabels {
  const SensorLabels({
    required this.temperature,
    required this.humidity,
    required this.light,
    required this.sound,
    required this.mq2,
    required this.pressure,
  });

  final String temperature;
  final String humidity;
  final String light;
  final String sound;
  final String mq2;
  final String pressure;

  static SensorLabels? tryParse(Map<String, dynamic> json) {
    final values = <String, String>{};
    for (final key in _requiredKeys) {
      final value = json[key];
      if (value is! String || !StatusPayload._knownLabels.contains(value)) {
        return null;
      }
      values[key] = value;
    }
    return SensorLabels(
      temperature: values['temperature']!,
      humidity: values['humidity']!,
      light: values['light']!,
      sound: values['sound']!,
      mq2: values['mq2']!,
      pressure: values['pressure']!,
    );
  }

  static const Set<String> _requiredKeys = {
    'temperature',
    'humidity',
    'light',
    'sound',
    'mq2',
    'pressure',
  };
}
