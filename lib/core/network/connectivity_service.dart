import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

abstract class ConnectivityService {
  Stream<bool> get connectivityStream;
  Future<bool> get isOnline;
  Future<bool> checkBackendReachability({String? baseUrl, Duration? timeout}) async => isOnline;
  void simulateOnlineStatus(bool? override);
}

/// Classified reason a backend reachability probe failed. Kept separate
/// from device internet state: `offline` means the device itself has no
/// network, every other value means the device is online but the FastAPI
/// backend could not be reached (or rejected the probe).
enum BackendFailureReason {
  none,
  offline,
  malformedUrl,
  dnsFailure,
  connectionRefused,
  connectionTimeout,
  httpError,
  unknown,
}

/// Detailed outcome of one backend reachability probe. `reachable` is true
/// only on HTTP 200 from a real health endpoint; otherwise [reason] and
/// [detail] describe the failure for development diagnostics. Never carries
/// credentials: the probe is an unauthenticated GET and logs no tokens.
class BackendProbeResult {
  final bool reachable;
  final String baseUrl;
  final String healthUrl;
  final BackendFailureReason reason;
  final String detail;
  final int? statusCode;

  const BackendProbeResult({
    required this.reachable,
    required this.baseUrl,
    required this.healthUrl,
    this.reason = BackendFailureReason.none,
    this.detail = '',
    this.statusCode,
  });
}

/// Classifies a probe exception into a [BackendFailureReason] plus a short
/// secret-free detail string. `package:http` surfaces transport failures as
/// [http.ClientException] (wrapping the socket message), so classification
/// inspects both the runtime type and the message text.
BackendFailureReason classifyProbeError(Object e, StringBuffer detail) {
  final text = e.toString();
  detail.write(text.length > 220 ? '${text.substring(0, 220)}…' : text);
  final lower = text.toLowerCase();
  if (e is FormatException ||
      lower.contains('invalid argument') && lower.contains('uri') ||
      lower.contains('no host specified')) {
    return BackendFailureReason.malformedUrl;
  }
  if (e is TimeoutException || lower.contains('time-out') || lower.contains('timed out')) {
    return BackendFailureReason.connectionTimeout;
  }
  if (lower.contains('failed host lookup') ||
      lower.contains('name or service not known') ||
      lower.contains('nodename nor servname') ||
      lower.contains('no address associated with hostname')) {
    return BackendFailureReason.dnsFailure;
  }
  if (lower.contains('connection refused') || lower.contains('errno = 111')) {
    return BackendFailureReason.connectionRefused;
  }
  return BackendFailureReason.unknown;
}

/// Probes a SINGLE configured backend base URL with real HTTP GETs against
/// the actual FastAPI health endpoints (`/api/v1/health`, then `/health`).
/// Pure function of [client] + [baseUrl] (no platform plugins) so it is
/// unit-testable against a local test server. Only HTTP 200 counts as
/// reachable. Uses [ApiConfig.joinPath] so a trailing-slash base can never
/// produce `//api/v1/health` or a missing-slash URL.
Future<BackendProbeResult> probeBackendDetailed({
  required http.Client client,
  required String baseUrl,
  required Duration timeout,
}) async {
  final base = baseUrl.trim();
  final healthUrl = ApiConfig.joinPath(base, '/api/v1/health');
  Uri uri;
  try {
    uri = Uri.parse(healthUrl);
    if (uri.host.isEmpty) {
      return BackendProbeResult(
        reachable: false,
        baseUrl: base,
        healthUrl: healthUrl,
        reason: BackendFailureReason.malformedUrl,
        detail: 'Parsed health URL has no host: $healthUrl',
      );
    }
  } on FormatException catch (e) {
    return BackendProbeResult(
      reachable: false,
      baseUrl: base,
      healthUrl: healthUrl,
      reason: BackendFailureReason.malformedUrl,
      detail: 'Malformed backend URL: $e',
    );
  }

  final endpoints = [uri, Uri.parse(ApiConfig.joinPath(base, '/health'))];
  BackendProbeResult? lastFailure;
  for (final endpoint in endpoints) {
    try {
      final response = await client.get(endpoint).timeout(timeout);
      if (response.statusCode == 200) {
        return BackendProbeResult(
          reachable: true,
          baseUrl: base,
          healthUrl: endpoint.toString(),
          statusCode: 200,
        );
      }
      lastFailure = BackendProbeResult(
        reachable: false,
        baseUrl: base,
        healthUrl: endpoint.toString(),
        reason: BackendFailureReason.httpError,
        detail: 'HTTP ${response.statusCode} from $endpoint',
        statusCode: response.statusCode,
      );
    } catch (e) {
      // Timeouts/refusals on the canonical path fall through to the alias;
      // anything else is recorded and retried once against `/health`.
      final detail = StringBuffer();
      final reason = classifyProbeError(e, detail);
      lastFailure = BackendProbeResult(
        reachable: false,
        baseUrl: base,
        healthUrl: endpoint.toString(),
        reason: reason,
        detail: detail.toString(),
      );
    }
  }
  return lastFailure ??
      const BackendProbeResult(
        reachable: false,
        baseUrl: '',
        healthUrl: '',
        reason: BackendFailureReason.unknown,
        detail: 'Probe produced no result',
      );
}

/// Probes backend health endpoints with real HTTP GETs. Pure function of
/// [client] + [candidateUrls] (no platform plugins) so it is unit-testable
/// against a local test server. Only HTTP 200 counts as reachable.
///
/// Retained for explicit multi-candidate callers and existing tests; the
/// production path ([ConnectivityServiceImpl.checkBackendReachability])
/// probes exactly one URL — the explicitly configured backend — and never
/// silently guesses emulator/loopback fallbacks.
Future<bool> probeBackendReachability({
  required http.Client client,
  required List<String> candidateUrls,
  required Duration timeout,
}) async {
  for (final base in candidateUrls) {
    final result = await probeBackendDetailed(
      client: client,
      baseUrl: base,
      timeout: timeout,
    );
    if (result.reachable) return true;
  }
  return false;
}

class ConnectivityServiceImpl implements ConnectivityService {
  final Connectivity _connectivity;
  final http.Client _httpClient;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  StreamSubscription? _sub;
  bool? _simulatedStatus;

  ConnectivityServiceImpl({Connectivity? connectivity, http.Client? httpClient})
      : _connectivity = connectivity ?? Connectivity(),
        _httpClient = httpClient ?? http.Client() {
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      if (_simulatedStatus == null) {
        final online = _isAnyConnected(results);
        _controller.add(online);
      }
    });
  }

  bool _isAnyConnected(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  @override
  Stream<bool> get connectivityStream => _controller.stream;

  @override
  Future<bool> get isOnline async {
    if (_simulatedStatus != null) return _simulatedStatus!;
    try {
      final results = await _connectivity.checkConnectivity();
      return _isAnyConnected(results);
    } catch (_) {
      return false;
    }
  }

  /// Real backend reachability probe. A network interface alone ("Wi-Fi is
  /// on") is never treated as proof that FastAPI is reachable: this issues
  /// an actual HTTP GET against the real health endpoint and only returns
  /// true on HTTP 200.
  ///
  /// Uses `package:http` (fetch-backed) instead of native-only HttpClient so
  /// the identical code runs on native platforms AND Flutter Web. A
  /// simulated OFFLINE short-circuits to false; a simulated ONLINE still
  /// probes for real.
  ///
  /// The probe targets EXACTLY one URL: the [baseUrl] override when given,
  /// otherwise the explicitly configured [ApiConfig.baseUrl]. There is
  /// deliberately no silent guessing between `127.0.0.1` (physical phone
  /// over `adb reverse tcp:8000 tcp:8000`) and `10.0.2.2` (emulator-only
  /// alias): guessing masks a missing `adb reverse` mapping or a stale
  /// `--dart-define=BACKEND_URL`. Development diagnostics (`[BackendDiag]`)
  /// always report which URL was actually probed and why it failed.
  ///
  /// Nothing is cached: every call re-probes, so Sync Now / retry observes
  /// a backend that just came back without reinstall or re-login.
  @override
  Future<bool> checkBackendReachability({String? baseUrl, Duration? timeout}) async {
    final result = await checkBackendReachabilityDetailed(
      baseUrl: baseUrl,
      timeout: timeout,
    );
    return result.reachable;
  }

  /// Same probe as [checkBackendReachability] with the classified outcome
  /// for development diagnostics. Not part of the [ConnectivityService]
  /// interface so existing fakes stay source-compatible.
  Future<BackendProbeResult> checkBackendReachabilityDetailed({
    String? baseUrl,
    Duration? timeout,
  }) async {
    if (_simulatedStatus != null && !_simulatedStatus!) {
      return const BackendProbeResult(
        reachable: false,
        baseUrl: '',
        healthUrl: '',
        reason: BackendFailureReason.offline,
        detail: 'Simulated offline',
      );
    }
    final online = await isOnline;
    final configured = (baseUrl ?? ApiConfig.baseUrl).trim();
    final duration = timeout ?? const Duration(seconds: 3);

    if (!online) {
      final offline = BackendProbeResult(
        reachable: false,
        baseUrl: configured,
        healthUrl: ApiConfig.healthUrl(baseUrlOverride: configured),
        reason: BackendFailureReason.offline,
        detail: 'Device has no network connectivity',
      );
      _logBackendDiag(offline, networkOnline: false);
      return offline;
    }

    final result = await probeBackendDetailed(
      client: _httpClient,
      baseUrl: configured,
      timeout: duration,
    );
    _logBackendDiag(result, networkOnline: true);
    return result;
  }

  /// Secret-free development diagnostic. Reports the ACTUAL probed URL —
  /// never tokens or passwords (the probe sends no auth headers at all).
  void _logBackendDiag(BackendProbeResult result, {required bool networkOnline}) {
    if (!kDebugMode) return;
    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
    debugPrint(
      '[BackendDiag] platform=$platform '
      'configuredBackendUrl=${result.baseUrl} '
      'healthUrl=${result.healthUrl} '
      'networkOnline=$networkOnline '
      'backendReachable=${result.reachable} '
      'failureReason=${result.reason.name}'
      '${result.statusCode != null ? ' httpStatus=${result.statusCode}' : ''}'
      '${result.detail.isNotEmpty ? ' error=${result.detail}' : ''}',
    );
    if (!result.reachable &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        result.baseUrl.startsWith('http://127.0.0.1:') &&
        result.reason == BackendFailureReason.connectionRefused) {
      debugPrint(
        '[BackendDiag] hint: connection refused on phone loopback. '
        'For a physical device over USB this means `adb reverse` is '
        'missing — run `adb reverse tcp:8000 tcp:8000` and check '
        '`adb reverse --list`. For an emulator, rebuild with '
        '--dart-define=BACKEND_URL=http://10.0.2.2:8000 instead.',
      );
    }
  }

  @override
  void simulateOnlineStatus(bool? override) {
    _simulatedStatus = override;
    if (override != null) {
      _controller.add(override);
    } else {
      isOnline.then((online) => _controller.add(online));
    }
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
    _httpClient.close();
  }
}
