import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cronet_http/cronet_http.dart';
import 'package:cupertino_http/cupertino_http.dart';
import 'package:xeris_wallet/core/config/network_config.dart';

enum ApiErrorType {
  network,
  timeout,
  server,
  rpc,
  unknown,
}

class ApiException implements Exception {
  final String message;
  final ApiErrorType type;
  final int? statusCode;
  final dynamic originalError;

  ApiException({
    required this.message,
    required this.type,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() =>
      'ApiException: $message (Type: $type, Code: $statusCode)';
}

/// Base class for all API services to standardize error handling and JSON-RPC calls.
abstract class BaseApiService {
  static const Duration defaultTimeout = Duration(seconds: 4);
  static int _rpcId = 1;

  // Platform-native HTTP client: Cronet on Android (connection pooling only —
  // HTTP/2 and QUIC disabled because endpoints are cleartext HTTP/1.1 and QUIC
  // probes hang on networks that block outbound UDP), NSURLSession on iOS,
  // default http.Client elsewhere. Persistent instance reuses TCP connections.
  static final http.Client _client = _buildClient();

  @visibleForTesting
  static http.Client? clientOverride;

  static http.Client get _activeClient => clientOverride ?? _client;

  static http.Client _buildClient() {
    try {
      if (Platform.isAndroid) {
        final engine = CronetEngine.build(
          cacheMode: CacheMode.disabled,
          enableHttp2: false,
          enableQuic: false,
        );
        return CronetClient.fromCronetEngine(engine);
      }
      if (Platform.isIOS || Platform.isMacOS) {
        final config = URLSessionConfiguration.ephemeralSessionConfiguration()
          ..allowsCellularAccess = true
          ..httpMaximumConnectionsPerHost = 6;
        return CupertinoClient.fromSessionConfiguration(config);
      }
    } catch (e) {
      // Log unconditionally — falling back to plain http.Client() loses
      // HTTP/2 multiplexing and connection pooling, which is the difference
      // between balances loading instantly and loading "forever". A silent
      // fallback once masked an R8 strip of Cronet classes in release.
      debugPrint(
          'Native HTTP client unavailable, falling back to http.Client: $e');
    }
    return http.Client();
  }

  /// Performs a centralized network request with retry logic and exponential backoff.
  ///
  /// maxRetries=1 means a single attempt with no retry. Pass a higher value
  /// (e.g. 2) for idempotent calls where a transient network failure or
  /// cold-connection timeout is worth retrying. With maxRetries=1, timeouts
  /// still fail fast since the retry is gated by the attempt budget.
  static Future<dynamic> _request({
    required Future<http.Response> Function() call,
    int maxRetries = 1,
    Duration timeout = defaultTimeout,
    String? context,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        final response = await call().timeout(timeout);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final dynamic decoded = json.decode(response.body);

          // JSON-RPC specific error handling within 200 OK
          if (decoded is Map &&
              decoded.containsKey('error') &&
              decoded['error'] != null) {
            final error = decoded['error'];
            final String errorMessage = error is Map
                ? (error['message'] ?? 'Unknown RPC Error')
                : error.toString();
            throw ApiException(
              message: errorMessage,
              type: ApiErrorType.rpc,
              statusCode: response.statusCode,
              originalError: error,
            );
          }

          return decoded;
        } else if (response.statusCode >= 500) {
          throw ApiException(
            message: 'Server error: ${response.statusCode}',
            type: ApiErrorType.server,
            statusCode: response.statusCode,
          );
        } else {
          throw ApiException(
            message: 'HTTP error: ${response.statusCode}',
            type: ApiErrorType.unknown,
            statusCode: response.statusCode,
          );
        }
      } catch (e) {
        attempt++;

        ApiErrorType type = ApiErrorType.unknown;
        String message = e.toString();

        bool retryable = false;
        if (e is SocketException) {
          type = ApiErrorType.network;
          message = 'Network unreachable';
          retryable = true;
        } else if (e is TimeoutException) {
          type = ApiErrorType.timeout;
          message = 'Request timed out';
          // Retry timeouts only when budget remains: a cold connection setup
          // (radio wake, wifi↔cellular handoff) can stall the first attempt,
          // and the retry reuses the now-warm pool. Single-attempt calls still
          // fail fast since maxRetries gates the retry below.
          retryable = true;
        } else if (e is ApiException) {
          // If it's already an ApiException (like RPC error), we might not want to retry depending on error
          if (e.type == ApiErrorType.rpc ||
              e.type == ApiErrorType.unknown && e.statusCode == 400) {
            // Don't retry client errors or explicit RPC rejections
            rethrow;
          }
          type = e.type;
          message = e.message;
          retryable = e.type == ApiErrorType.server;
        }

        if (!retryable || attempt >= maxRetries) {
          if (kDebugMode && context != null) {
            debugPrint('Final attempt failed for [$context]: $message');
          }
          if (e is ApiException) rethrow;
          throw ApiException(
            message: message,
            type: type,
            originalError: e,
          );
        }

        final backoff = Duration(milliseconds: 500 * (1 << attempt));
        if (kDebugMode) {
          debugPrint(
              'Retrying [$context] (attempt $attempt) in ${backoff.inMilliseconds}ms due to: $message');
        }
        await Future.delayed(backoff);
      }
    }
  }

  /// Performs a generic JSON-RPC call.
  static Future<dynamic> callRpc(String method, [List<dynamic>? params]) async {
    final id = _rpcId++;
    final payload = {
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params ?? [],
    };

    final response = await _request(
      context: 'RPC $method',
      call: () => _activeClient.post(
        Uri.parse(NetworkConfig.jsonRpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ),
    );

    if (response is Map && response.containsKey('result')) {
      final result = response['result'];
      // Older and current Xeris nodes can put RPC rejections inside result.
      // They must not be parsed as successful account/blockhash responses.
      if (result is Map && result['error'] != null) {
        final error = result['error'];
        throw ApiException(
          message: error is Map
              ? (error['message'] ?? 'RPC request rejected').toString()
              : error.toString(),
          type: ApiErrorType.rpc,
          originalError: error,
        );
      }
      return result;
    }
    return response;
  }

  /// Performs a standard GET request with improved logging and timeout.
  ///
  /// GETs are idempotent, so callers can pass maxRetries > 1 to ride out a
  /// transient network failure or cold-connection timeout.
  static Future<dynamic> get(
    String url, {
    int maxRetries = 1,
    Duration timeout = defaultTimeout,
  }) async {
    return _request(
      context: 'GET $url',
      maxRetries: maxRetries,
      timeout: timeout,
      call: () => _activeClient.get(Uri.parse(url)),
    );
  }

  /// Performs a standard POST request.
  ///
  /// Callers that submit transactions should pass a longer [timeout] than the
  /// 4s default: a node can take several seconds to accept a tx, and a premature
  /// timeout reported as failure invites a resubmit that double-sends.
  static Future<dynamic> post(
    String url,
    Map<String, dynamic> body, {
    Duration timeout = defaultTimeout,
  }) async {
    return _request(
      context: 'POST $url',
      timeout: timeout,
      call: () => _activeClient.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ),
    );
  }
}
