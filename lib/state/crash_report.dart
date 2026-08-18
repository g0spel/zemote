import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../update/app_version.dart';
import 'log_store.dart';

/// One captured crash. Persisted to disk so the evidence survives the
/// process; surfaced in 设置 → 上次崩溃.
class CrashInfo {
  final DateTime time;
  final String kind; // 'framework' | 'uncaught'
  final String error;
  final String? stack;
  final String appVersion;

  const CrashInfo({
    required this.time,
    required this.kind,
    required this.error,
    this.stack,
    required this.appVersion,
  });

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'kind': kind,
        'error': error,
        'stack': stack,
        'appVersion': appVersion,
      };

  factory CrashInfo.fromJson(Map<String, dynamic> j) => CrashInfo(
        time: DateTime.tryParse('${j['time']}') ?? DateTime.now(),
        kind: '${j['kind']}',
        error: '${j['error']}',
        stack: j['stack'] as String?,
        appVersion: '${j['appVersion']}',
      );
}

String _trunc(String s, int max) => s.length <= max ? s : '${s.substring(0, max)}…(截断)';

/// Persists the LAST crash to [file] (single slot, overwritten). Kept tiny
/// on purpose: this is evidence for the next launch, not a crash archive.
class CrashStore {
  CrashStore(this.file);

  final File file;
  bool _writing = false;

  Future<void> record(String kind, Object error, StackTrace? stack) async {
    log('[诊断] 捕获异常（$kind）: $error');
    if (_writing) return;
    _writing = true;
    try {
      final info = CrashInfo(
        time: DateTime.now(),
        kind: kind,
        error: _trunc('$error', 8 * 1024),
        stack: stack == null ? null : _trunc('$stack', 32 * 1024),
        appVersion: appVersion,
      );
      await file.writeAsString(jsonEncode(info.toJson()), flush: true);
    } catch (_) {
      // Persistence is best-effort; must never throw during a crash.
    } finally {
      _writing = false;
    }
  }

  Future<CrashInfo?> read() async {
    try {
      if (!await file.exists()) return null;
      final j = jsonDecode(await file.readAsString());
      if (j is! Map<String, dynamic>) return null;
      return CrashInfo.fromJson(j);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

/// Global store; wired in `main()` on mobile/desktop, null on web.
CrashStore? crashStore;

/// Standard Flutter error hooks: framework errors and uncaught zone errors
/// are forwarded to the console as usual AND persisted for the next launch.
void installCrashHandlers(CrashStore store) {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    store.record('framework', details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    store.record('uncaught', error, stack);
    return true;
  };
}
