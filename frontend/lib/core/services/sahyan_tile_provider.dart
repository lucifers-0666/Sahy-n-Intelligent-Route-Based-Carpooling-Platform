import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// HTTP Client that seamlessly falls back to known CDN IPs when the host system
/// or emulator experiences DNS resolution failures (e.g. SocketException: Failed host lookup).
class DnsFallbackHttpClient extends http.BaseClient {
  late final http.Client _primaryClient;
  late final http.Client _fallbackClient;

  static const Map<String, String> _knownHostIps = {
    'tile.openstreetmap.org': '151.101.209.91',
    'a.tile.openstreetmap.org': '151.101.209.91',
    'b.tile.openstreetmap.org': '151.101.209.91',
    'c.tile.openstreetmap.org': '151.101.209.91',
    'a.tile.openstreetmap.fr': '151.101.209.91',
    'b.tile.openstreetmap.fr': '151.101.209.91',
    'c.tile.openstreetmap.fr': '151.101.209.91',
    'basemaps.cartocdn.com': '104.16.14.38',
    'a.basemaps.cartocdn.com': '104.16.14.38',
    'b.basemaps.cartocdn.com': '104.16.14.38',
    'c.basemaps.cartocdn.com': '104.16.14.38',
    'd.basemaps.cartocdn.com': '104.16.14.38',
    'server.arcgisonline.com': '23.48.200.75',
  };

  DnsFallbackHttpClient() {
    _primaryClient = http.Client();

    if (!kIsWeb) {
      final ioClient = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) {
          // Allow certificate when connecting directly via IP for fallback CDN hosts
          return true;
        };
      _fallbackClient = IOClient(ioClient);
    } else {
      _fallbackClient = _primaryClient;
    }
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    try {
      return await _primaryClient.send(request);
    } on SocketException catch (_) {
      return _tryFallback(request);
    } on http.ClientException catch (_) {
      return _tryFallback(request);
    } catch (_) {
      return _tryFallback(request);
    }
  }

  Future<http.StreamedResponse> _tryFallback(http.BaseRequest original) async {
    final originalHost = original.url.host;
    final fallbackIp = _knownHostIps[originalHost];

    if (fallbackIp == null) {
      // Re-issue original request to throw original exception
      return _primaryClient.send(original);
    }

    final newUri = original.url.replace(host: fallbackIp);
    final fallbackRequest = http.Request(original.method, newUri);
    fallbackRequest.headers.addAll(original.headers);
    fallbackRequest.headers['Host'] = originalHost;

    return _fallbackClient.send(fallbackRequest);
  }

  @override
  void close() {
    _primaryClient.close();
    if (!kIsWeb) {
      _fallbackClient.close();
    }
    super.close();
  }
}

/// Factory that creates a resilient NetworkTileProvider backed by DNS fallback.
class SahyanTileProvider {
  static final DnsFallbackHttpClient _sharedHttpClient = DnsFallbackHttpClient();

  /// Create a NetworkTileProvider with DNS resilience and custom user agent.
  static TileProvider create({
    Map<String, String>? headers,
    bool silenceExceptions = false,
  }) {
    return NetworkTileProvider(
      headers: headers,
      httpClient: _sharedHttpClient,
      silenceExceptions: silenceExceptions,
    );
  }
}
