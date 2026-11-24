import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/network_config.dart';

class DAppMainnetVerifier {
  static const origin = 'https://mainnetrpc.xerisweb.com';
  static const checkpointHash =
      '0a401c139eef73f049010450d4aa13ef38636799784d01bbc0ecdb9c71facaf3';
  @visibleForTesting
  static Future<dynamic> Function(String path)? readOverride;
  @visibleForTesting
  static http.Client? clientOverride;

  static Future<dynamic> _read(String path) async {
    if (path != '/v2/block/slot/27201' &&
        path != '/v2/blocks?page=1&page_size=100') {
      throw StateError('Unsupported identity path.');
    }
    if (readOverride != null) return readOverride!(path);
    final owned = clientOverride == null;
    final client = clientOverride ?? http.Client();
    StreamSubscription<List<int>>? subscription;
    try {
      final operation = () async {
        final request = http.Request('GET', Uri.parse('$origin$path'))
          ..followRedirects = false;
        request.headers.addAll(
            {'Accept': 'application/json', 'Cache-Control': 'no-store'});
        final response = await client.send(request);
        if (response.statusCode != 200 ||
            response.contentLength != null &&
                response.contentLength! > 524288) {
          throw StateError('Mainnet identity unavailable.');
        }
        final body = <int>[], done = Completer<void>();
        subscription = response.stream.listen((chunk) {
          if (body.length + chunk.length > 524288) {
            if (!done.isCompleted) {
              done.completeError(StateError('Oversized mainnet identity.'));
            }
            return;
          }
          body.addAll(chunk);
        }, onError: (Object error) {
          if (!done.isCompleted) done.completeError(error);
        }, onDone: () {
          if (!done.isCompleted) done.complete();
        }, cancelOnError: true);
        await done.future;
        return jsonDecode(utf8.decode(body));
      }();
      return await operation.timeout(const Duration(seconds: 6));
    } finally {
      // Cancellation itself may stall; it must not extend the request deadline.
      subscription?.cancel().catchError((_) {});
      if (owned) client.close();
    }
  }

  static Future<void> verifyIdentity() => _verify(null);

  static Future<void> verify(String blockhash, {int Function()? now}) =>
      _verify(blockhash, now: now);

  static Future<void> _verify(String? blockhash, {int Function()? now}) async {
    if (NetworkConfig.currentNetwork != XerisNetwork.mainnet ||
        NetworkConfig.rpcUrl != origin ||
        NetworkConfig.controlUrl != origin) {
      throw StateError(
          'Reviewed dApp transaction signing requires Xeris Mainnet.');
    }
    final scope = NetworkConfig.cacheKey,
        clock = now ?? () => DateTime.now().millisecondsSinceEpoch;
    if (blockhash != null && !RegExp(r'^[0-9a-f]{64}$').hasMatch(blockhash)) {
      throw StateError('Invalid blockhash.');
    }
    final point = await _read('/v2/block/slot/27201'), time = clock();
    final data = point is Map ? point['data'] : null,
        attestation = point is Map ? point['attestation'] : null;
    bool recent(dynamic value, int maximum) =>
        value is int && time - value >= -2000 && time - value <= maximum;
    if (point is! Map ||
        point['success'] != true ||
        data is! Map ||
        data['slot'] != 27201 ||
        data['hash'] != checkpointHash ||
        attestation is! Map ||
        attestation['chain_id'] != 'xeris-mainnet-v4' ||
        attestation['generation'] is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(attestation['generation']) ||
        !recent(attestation['prefix_verified_at_ms'], 120000) ||
        !recent(attestation['observed_at_ms'], 15000) ||
        attestation['prefix_verified_at_ms'] > attestation['observed_at_ms']) {
      throw StateError(
          'Mainnet identity is unavailable or stale. Signing paused.');
    }
    if (NetworkConfig.cacheKey != scope) {
      throw StateError('Network changed during verification.');
    }
    if (blockhash == null) return;
    final feed = await _read('/v2/blocks?page=1&page_size=100');
    if (NetworkConfig.cacheKey != scope ||
        feed is! Map ||
        feed['success'] != true ||
        feed['data'] is! List ||
        (feed['data'] as List).isEmpty ||
        (feed['data'] as List).length > 100) {
      throw StateError('Recent verified mainnet blocks unavailable.');
    }
    final finalTime = clock();
    if (finalTime - attestation['prefix_verified_at_ms'] > 120000 ||
        finalTime - attestation['observed_at_ms'] > 15000) {
      throw StateError('Mainnet attestation expired during review.');
    }
    final matches = (feed['data'] as List)
        .where((b) => b is Map && b['hash'] == blockhash)
        .toList();
    if (matches.length != 1) {
      throw StateError('Transaction blockhash not on recent mainnet.');
    }
    final block = matches.single as Map, stamp = block['poh_timestamp'];
    if (block['slot'] is! int ||
        block['slot'] <= 27201 ||
        stamp is! int ||
        clock() - stamp < -2000 ||
        clock() - stamp > 120000) {
      throw StateError('Transaction blockhash is stale.');
    }
  }
}
