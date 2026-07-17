import 'dart:async';

import 'package:http/http.dart' as http;

import '../models/status.dart';

/// Fetches the local teaching API. A successful request is not an online,
/// calibrated, healthy, safe, or attended-device assertion.
class BeehiveApiService {
  BeehiveApiService({this.timeout = const Duration(seconds: 8)});

  final Duration timeout;

  Future<StatusPayload> fetchStatus(String host) async {
    final canonicalHost = _canonicalTrustedLocalHost(host);
    if (canonicalHost == null) {
      throw BeehiveApiException('仅接受可信局域网 IPv4 地址');
    }
    final uri = Uri(scheme: 'http', host: canonicalHost, path: '/api/status');
    final client = http.Client();
    try {
      final request = http.Request('GET', uri)
        ..followRedirects = false
        ..maxRedirects = 0;
      final streamed = await client.send(request).timeout(timeout);
      final response = await http.Response.fromStream(
        streamed,
      ).timeout(timeout);
      if (response.statusCode != 200) {
        throw BeehiveApiException('HTTP ${response.statusCode}');
      }
      final parsed = StatusPayload.tryParse(response.body);
      if (parsed == null) throw BeehiveApiException('响应不是可解析的 JSON');
      if (parsed.status != 'local_response') {
        throw BeehiveApiException(parsed.errorMessage ?? '设备返回本地错误');
      }
      return parsed;
    } finally {
      client.close();
    }
  }

  /// Returns only a canonical decimal IPv4 address in the allowed local ranges.
  ///
  /// Leading-zero octets are rejected before `Uri` or the operating system can
  /// interpret them with a different numeric base.
  static String? _canonicalTrustedLocalHost(String host) {
    final value = host.trim();
    final parts = value.split('.');
    if (parts.length != 4) return null;
    final canonicalDecimalOctet = RegExp(r'^(?:0|[1-9][0-9]{0,2})$');
    if (parts.any((part) => !canonicalDecimalOctet.hasMatch(part))) {
      return null;
    }
    final octets = parts.map(int.tryParse).toList();
    if (octets.any((item) => item == null || item < 0 || item > 255)) {
      return null;
    }
    final a = octets[0]!;
    final b = octets[1]!;
    final allowed =
        a == 10 ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168) ||
        (a == 169 && b == 254);
    return allowed ? value : null;
  }
}

class BeehiveApiException implements Exception {
  BeehiveApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
